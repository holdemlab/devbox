#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
#  linux_upgrade — Neovim (IDE) + tmux для Debian/Ubuntu x86_64, БЕЗ sudo.
#  Все встановлюється в ~/.local, конфіги — симлінками на цей репозиторій,
#  тож оновлення = `git pull` (+ ./install.sh для нових бінарників).
#
#  Використання:  ./install.sh [опції]       (детальніше: ./install.sh --help)
# ──────────────────────────────────────────────────────────────────────────────
set -Eeuo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="$HOME/.local"
BIN="$PREFIX/bin"
OPT="$PREFIX/opt"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/linux_upgrade"
STAMP="$(date +%Y%m%d-%H%M%S)"

# Версії, які не мають "latest"-посилання без версії в імені файлу
RG_VERSION="15.1.0"
FD_VERSION="10.4.2"
NODE_MAJOR="24"          # LTS

# ─── Опції ────────────────────────────────────────────────────────────────────
DO_NVIM=1
DO_TMUX=1
DO_NODE=1
DO_GO=1
USE_SUDO=0
DO_FONT=0
LINK_MODE="symlink"
UPGRADE=0
SKIP_PLUGINS=0
DO_SHELL=1

usage() {
  cat <<EOF
Використання: ./install.sh [опції]

Компоненти (за замовчуванням ставиться все):
  --nvim-only        лише Neovim
  --tmux-only        лише tmux
  --no-node          не ставити Node.js (без LSP для bash/yaml/json/docker/ts/html/css/pyright)
  --no-go            не ставити Go (без gopls/gofumpt/goimports)
  --font             поставити JetBrainsMono Nerd Font (для ЛОКАЛЬНОЇ машини з GUI-терміналом)

Режим:
  --sudo             дозволити apt (sudo) для відсутніх пакетів: build-essential, unzip, tmux, git...
  --copy             копіювати конфіги замість симлінків на репозиторій
  --upgrade          перезавантажити бінарники (nvim, tmux, node, go, rg, fd...) навіть якщо вже є
  --skip-plugins     не встановлювати плагіни/LSP одразу (поставляться при першому запуску nvim)
  --no-shell         не чіпати ~/.bashrc / ~/.zshrc
  -h, --help         ця довідка

Приклади:
  ./install.sh                     # повне встановлення без sudo
  ./install.sh --no-go --no-node   # легше: тільки lua/python(ruff)/shell LSP
  ./install.sh --tmux-only
  ./install.sh --upgrade           # оновити все до свіжих версій
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --nvim-only) DO_TMUX=0 ;;
    --tmux-only) DO_NVIM=0; DO_NODE=0; DO_GO=0 ;;
    --no-node) DO_NODE=0 ;;
    --no-go) DO_GO=0 ;;
    --font) DO_FONT=1 ;;
    --sudo) USE_SUDO=1 ;;
    --copy) LINK_MODE="copy" ;;
    --upgrade) UPGRADE=1 ;;
    --skip-plugins) SKIP_PLUGINS=1 ;;
    --no-shell) DO_SHELL=0 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Невідома опція: $1"; usage; exit 1 ;;
  esac
  shift
done

# ─── Вивід ────────────────────────────────────────────────────────────────────
if [ -t 1 ]; then
  C_B=$'\e[1m'; C_G=$'\e[32m'; C_Y=$'\e[33m'; C_R=$'\e[31m'; C_C=$'\e[36m'; C_0=$'\e[0m'
else
  C_B=""; C_G=""; C_Y=""; C_R=""; C_C=""; C_0=""
fi
step() { printf '\n%s==> %s%s\n' "$C_B$C_C" "$*" "$C_0"; }
ok()   { printf '  %s✓%s %s\n' "$C_G" "$C_0" "$*"; }
warn() { printf '  %s!%s %s\n' "$C_Y" "$C_0" "$*"; WARNINGS+=("$*"); }
die()  { printf '%s✗ %s%s\n' "$C_R" "$*" "$C_0" >&2; exit 1; }
WARNINGS=()
trap 'die "Помилка в рядку $LINENO: $BASH_COMMAND"' ERR

have() { command -v "$1" >/dev/null 2>&1; }

# ─── Перевірки середовища ────────────────────────────────────────────────────
step "Перевірка системи"
[ "$(uname -s)" = "Linux" ] || die "Підтримується лише Linux"
[ "$(uname -m)" = "x86_64" ] || die "Підтримується лише x86_64 (зараз: $(uname -m))"
if [ "$(id -u)" = "0" ]; then
  warn "Запущено від root — все встановиться для root ($HOME). Для іншого користувача запусти від нього."
fi

SUDO=""
if [ "$USE_SUDO" = 1 ]; then
  if [ "$(id -u)" = "0" ]; then SUDO=""
  elif have sudo; then SUDO="sudo"
  else warn "--sudo вказано, але sudo немає — працюю без нього"; USE_SUDO=0
  fi
fi

APT_UPDATED=0
apt_install() {
  [ "$USE_SUDO" = 1 ] && have apt-get || return 1
  if [ "$APT_UPDATED" = 0 ]; then $SUDO apt-get update -qq || return 1; APT_UPDATED=1; fi
  DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y -qq "$@" >/dev/null || return 1
}

# Базові утиліти
for t in tar gzip; do have "$t" || apt_install "$t" || die "Потрібен '$t'"; done
if ! have git; then apt_install git || die "Потрібен git (попроси адміна: apt install git, або запусти з --sudo)"; fi
if have curl; then
  dl() { curl -fsSL --retry 3 --connect-timeout 20 -o "$2" "$1"; }
  dl_stdout() { curl -fsSL --retry 3 --connect-timeout 20 "$1"; }
elif have wget; then
  dl() { wget -q -O "$2" "$1"; }
  dl_stdout() { wget -q -O - "$1"; }
else
  apt_install curl || die "Потрібен curl або wget"
  dl() { curl -fsSL --retry 3 --connect-timeout 20 -o "$2" "$1"; }
  dl_stdout() { curl -fsSL --retry 3 --connect-timeout 20 "$1"; }
fi

GLIBC="$(getconf GNU_LIBC_VERSION 2>/dev/null | awk '{print $2}')"
[ -n "$GLIBC" ] || GLIBC="$(ldd --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+$' || echo 0.0)"
ver_ge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -1)" = "$2" ]; }  # ver_ge A B  => A >= B

mkdir -p "$BIN" "$OPT" "$CACHE" "$HOME/.config"
export PATH="$BIN:$OPT/node/bin:$OPT/go/bin:$HOME/go/bin:$PATH"
ok "Linux x86_64, glibc $GLIBC, $([ "$USE_SUDO" = 1 ] && echo "apt дозволено" || echo "без sudo")"

# Тимчасова директорія для завантажень
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Посилання/копія з бекапом існуючого
link_config() {  # link_config <src> <dst>
  local src="$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ] && [ "$LINK_MODE" = symlink ]; then
    ok "$dst → вже налаштовано"; return
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mv "$dst" "$dst.bak-$STAMP"
    warn "Старий $dst збережено як $dst.bak-$STAMP"
  fi
  mkdir -p "$(dirname "$dst")"
  if [ "$LINK_MODE" = symlink ]; then ln -s "$src" "$dst"; else cp -r "$src" "$dst"; fi
  ok "$dst ← $src ($LINK_MODE)"
}

# ─── Neovim ───────────────────────────────────────────────────────────────────
install_neovim() {
  step "Neovim"
  if [ -x "$OPT/nvim/bin/nvim" ] && [ "$UPGRADE" = 0 ]; then
    ok "вже встановлено: $("$OPT/nvim/bin/nvim" --version | head -1)"
  else
    local url
    if ver_ge "$GLIBC" "2.34"; then
      url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
    else
      # офіційна збірка під старий glibc (2.17+) для Debian 11 / Ubuntu 20.04 тощо
      url="https://github.com/neovim/neovim-releases/releases/latest/download/nvim-linux-x86_64.tar.gz"
      warn "glibc $GLIBC < 2.34 — беру сумісну збірку з neovim/neovim-releases"
    fi
    dl "$url" "$TMP/nvim.tar.gz"
    rm -rf "$OPT/nvim.new" && mkdir -p "$OPT/nvim.new"
    tar -xzf "$TMP/nvim.tar.gz" -C "$OPT/nvim.new" --strip-components=1
    rm -rf "$OPT/nvim" && mv "$OPT/nvim.new" "$OPT/nvim"
    ok "$("$OPT/nvim/bin/nvim" --version | head -1)"
  fi
  ln -sf "$OPT/nvim/bin/nvim" "$BIN/nvim"
}

install_rg_fd() {
  step "ripgrep + fd (для пошуку в Telescope)"
  if have rg && [ "$UPGRADE" = 0 ]; then ok "rg: $(rg --version | head -1)"; else
    dl "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl.tar.gz" "$TMP/rg.tgz"
    tar -xzf "$TMP/rg.tgz" -C "$TMP"
    install -m 755 "$TMP/ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl/rg" "$BIN/rg"
    ok "rg $RG_VERSION"
  fi
  if (have fd || have fdfind) && [ "$UPGRADE" = 0 ]; then
    have fd || ln -sf "$(command -v fdfind)" "$BIN/fd"
    ok "fd: $(fd --version)"
  else
    dl "https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz" "$TMP/fd.tgz"
    tar -xzf "$TMP/fd.tgz" -C "$TMP"
    install -m 755 "$TMP/fd-v${FD_VERSION}-x86_64-unknown-linux-musl/fd" "$BIN/fd"
    ok "fd $FD_VERSION"
  fi
}

install_node() {
  step "Node.js (для LSP: bash, yaml, json, docker, pyright, ts, html, css)"
  if [ "$DO_NODE" = 0 ]; then warn "пропущено (--no-node): ці LSP не будуть встановлені"; return; fi
  if have npm && [ "$UPGRADE" = 0 ]; then ok "вже є: node $(node --version)"; return; fi
  local base="https://nodejs.org/dist/latest-v${NODE_MAJOR}.x"
  local file
  file="$(dl_stdout "$base/SHASUMS256.txt" | awk '/linux-x64\.tar\.gz$/ {print $2; exit}')" \
    || { warn "не вдалося отримати список версій Node.js"; return; }
  [ -n "$file" ] || { warn "не знайдено архів Node.js"; return; }
  dl "$base/$file" "$TMP/node.tgz"
  rm -rf "$OPT/node.new" && mkdir -p "$OPT/node.new"
  tar -xzf "$TMP/node.tgz" -C "$OPT/node.new" --strip-components=1
  rm -rf "$OPT/node" && mv "$OPT/node.new" "$OPT/node"
  ok "node $("$OPT/node/bin/node" --version) → $OPT/node"
}

install_go() {
  step "Go (для gopls / gofumpt / goimports)"
  if [ "$DO_GO" = 0 ]; then warn "пропущено (--no-go): Go LSP не буде встановлено"; return; fi
  if have go && [ "$UPGRADE" = 0 ]; then ok "вже є: $(go version)"; return; fi
  local v
  v="$(dl_stdout "https://go.dev/VERSION?m=text" | head -1)" || { warn "не вдалося дізнатися версію Go"; return; }
  dl "https://go.dev/dl/${v}.linux-amd64.tar.gz" "$TMP/go.tgz"
  rm -rf "$OPT/go.new" && mkdir -p "$OPT/go.new"
  tar -xzf "$TMP/go.tgz" -C "$OPT/go.new" --strip-components=1
  rm -rf "$OPT/go" && mv "$OPT/go.new" "$OPT/go"
  ok "$("$OPT/go/bin/go" version) → $OPT/go"
}

install_build_deps() {
  step "Компілятор і unzip (для treesitter-парсерів і Mason)"
  local cc_found=""
  for c in cc gcc clang; do have "$c" && { cc_found="$c"; break; }; done
  if [ -z "$cc_found" ]; then
    if apt_install build-essential; then ok "build-essential встановлено"; cc_found=cc
    else
      warn "Немає C-компілятора: treesitter-парсери не ставитимуться (підсвітка буде базова, vim regex). Рішення: попросити 'apt install build-essential' або запустити з --sudo"
    fi
  else
    ok "C-компілятор: $cc_found"
  fi
  have make || apt_install make || true

  if have unzip; then ok "unzip є"
  elif apt_install unzip; then ok "unzip встановлено"
  elif have python3; then
    ln -sf "$REPO_DIR/bin/unzip-shim" "$BIN/unzip"; chmod +x "$REPO_DIR/bin/unzip-shim"
    ok "unzip: python-shim → $BIN/unzip"
  else
    warn "Немає unzip і python3 — частина інструментів Mason (stylua) не встановиться"
  fi

  # tree-sitter CLI: офіційний бінарник потребує glibc >= 2.39
  if [ -n "$cc_found" ]; then
    if have tree-sitter && tree-sitter --version >/dev/null 2>&1 && [ "$UPGRADE" = 0 ]; then
      ok "tree-sitter: $(tree-sitter --version)"
    elif ver_ge "$GLIBC" "2.39"; then
      dl "https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-x64.gz" "$TMP/ts.gz"
      gunzip -c "$TMP/ts.gz" > "$BIN/tree-sitter" && chmod +x "$BIN/tree-sitter"
      ok "tree-sitter: $("$BIN/tree-sitter" --version)"
    else
      chmod +x "$REPO_DIR/bin/tree-sitter-shim"
      ln -sf "$REPO_DIR/bin/tree-sitter-shim" "$BIN/tree-sitter"
      ok "tree-sitter: shim (glibc $GLIBC < 2.39, парсери компілюються напряму через $cc_found)"
    fi
  fi
}

setup_nvim_config() {
  step "Конфіг Neovim"
  link_config "$REPO_DIR/nvim" "$HOME/.config/nvim"
}

sync_nvim_plugins() {
  [ "$SKIP_PLUGINS" = 1 ] && { warn "плагіни поставляться при першому запуску nvim"; return; }
  # timeout: щоб мережеві проблеми не підвісили інсталятор назавжди
  local TO=""; have timeout && TO="timeout 900"
  step "Плагіни Neovim (lazy.nvim)"
  $TO "$BIN/nvim" --headless "+Lazy! sync" +qa >"$CACHE/lazy.log" 2>&1 \
    && ok "плагіни встановлено" || warn "Lazy sync з помилками — див. $CACHE/lazy.log"

  step "Treesitter-парсери (може зайняти кілька хвилин)"
  if $TO "$BIN/nvim" --headless "+TSInstallMineSync" +qa >"$CACHE/treesitter.log" 2>&1; then
    ok "парсери: $(ls "$HOME/.local/share/nvim/site/parser" 2>/dev/null | wc -l) шт."
  else
    warn "частина парсерів не встановилась — див. $CACHE/treesitter.log (решта доставиться при запуску nvim)"
  fi

  step "LSP-сервери, форматери, лінтери (Mason)"
  if $TO "$BIN/nvim" --headless "+MasonToolsInstallSync" +qa >"$CACHE/mason.log" 2>&1; then
    ok "встановлено: $(ls "$HOME/.local/share/nvim/mason/packages" 2>/dev/null | tr '\n' ' ')"
  else
    warn "Mason завершився з помилками — див. $CACHE/mason.log (у nvim: :Mason)"
  fi
}

# ─── tmux ─────────────────────────────────────────────────────────────────────
tmux_version_ok() {  # >= 3.0
  local v; v="$(tmux -V 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)"
  [ -n "$v" ] && ver_ge "$v" "3.0"
}

install_tmux() {
  step "tmux"
  if [ -x "$BIN/tmux" ] && [ "$UPGRADE" = 1 ]; then rm -f "$BIN/tmux"; hash -r; fi
  if have tmux && tmux_version_ok; then
    ok "вже є: $(tmux -V) ($(command -v tmux))"
  elif apt_install tmux && tmux_version_ok; then
    ok "встановлено через apt: $(tmux -V)"
  else
    # Статична збірка: не залежить від бібліотек системи
    dl "https://github.com/pythops/tmux-linux-binary/releases/latest/download/tmux-linux-x86_64" "$TMP/tmux"
    install -m 755 "$TMP/tmux" "$BIN/tmux"
    hash -r
    ok "статичний tmux: $("$BIN/tmux" -V) → $BIN/tmux"
  fi
}

setup_tmux_config() {
  step "Конфіг tmux + плагіни (TPM)"
  link_config "$REPO_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
  local tpm="$HOME/.tmux/plugins/tpm"
  if [ -d "$tpm/.git" ]; then
    git -C "$tpm" pull -q --ff-only || true
    ok "TPM оновлено"
  else
    git clone -q --depth 1 https://github.com/tmux-plugins/tpm "$tpm"
    ok "TPM встановлено"
  fi
  # Встановлення плагінів без запуску tmux вручну
  if TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins/" "$tpm/bin/install_plugins" >"$CACHE/tpm.log" 2>&1; then
    ok "плагіни tmux: $(ls "$HOME/.tmux/plugins" | grep -v '^tpm$' | tr '\n' ' ')"
  else
    warn "TPM не зміг поставити плагіни — у tmux натисни prefix + I (див. $CACHE/tpm.log)"
  fi
  # Якщо tmux-сервер уже запущено — перечитати конфіг
  tmux source-file "$HOME/.tmux.conf" >/dev/null 2>&1 || true
}

# ─── Шрифт (для локальної машини) ────────────────────────────────────────────
install_font() {
  step "JetBrainsMono Nerd Font"
  local dir="$HOME/.local/share/fonts/JetBrainsMonoNerd"
  if [ -d "$dir" ] && [ "$UPGRADE" = 0 ]; then ok "вже встановлено"; return; fi
  have xz || { warn "потрібен xz для розпакування шрифту"; return; }
  dl "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz" "$TMP/font.tar.xz"
  rm -rf "$dir" && mkdir -p "$dir"
  tar -xJf "$TMP/font.tar.xz" -C "$dir"
  have fc-cache && fc-cache -f "$dir" >/dev/null 2>&1 || true
  ok "встановлено в $dir — вибери 'JetBrainsMono Nerd Font' у налаштуваннях терміналу"
}

# ─── Shell ────────────────────────────────────────────────────────────────────
setup_shell() {
  [ "$DO_SHELL" = 1 ] || return 0
  step "Налаштування shell (PATH, EDITOR, аліаси)"
  local env_file="$REPO_DIR/shell/env.sh"
  if [ "$LINK_MODE" = copy ]; then
    mkdir -p "$HOME/.config/linux_upgrade"
    cp "$env_file" "$HOME/.config/linux_upgrade/env.sh"
    env_file="$HOME/.config/linux_upgrade/env.sh"
  fi
  local begin="# >>> linux_upgrade >>>" end="# <<< linux_upgrade <<<"
  local block="$begin
[ -f \"$env_file\" ] && . \"$env_file\"
$end"
  local rc
  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [ "$rc" = "$HOME/.zshrc" ] && [ ! -f "$rc" ] && continue
    touch "$rc"
    if grep -qF "$begin" "$rc"; then
      # оновити блок (шлях до репозиторію міг змінитися)
      awk -v b="$begin" -v e="$end" '$0==b{skip=1} !skip{print} $0==e{skip=0}' "$rc" > "$TMP/rc"
      cat "$TMP/rc" > "$rc"
    fi
    printf '\n%s\n' "$block" >> "$rc"
    ok "$rc"
  done
}

# ─── Запуск ───────────────────────────────────────────────────────────────────
printf '%slinux_upgrade%s: nvim=%s tmux=%s node=%s go=%s (%s)\n' "$C_B" "$C_0" \
  "$DO_NVIM" "$DO_TMUX" "$DO_NODE" "$DO_GO" "$LINK_MODE"

if [ "$DO_NVIM" = 1 ]; then
  install_neovim
  install_rg_fd
  install_build_deps
  install_node
  install_go
  setup_nvim_config
fi
if [ "$DO_TMUX" = 1 ]; then
  install_tmux
  setup_tmux_config
fi
[ "$DO_FONT" = 1 ] && install_font
setup_shell
[ "$DO_NVIM" = 1 ] && sync_nvim_plugins

step "Готово"
if [ ${#WARNINGS[@]} -gt 0 ]; then
  printf '%sЗауваження:%s\n' "$C_Y" "$C_0"
  for w in "${WARNINGS[@]}"; do printf '  - %s\n' "$w"; done
fi
cat <<EOF

  Перезавантаж shell:   ${C_B}exec \$SHELL -l${C_0}
  Запусти:              ${C_B}t${C_0}  (tmux-сесія "main")  і  ${C_B}nvim${C_0}
  Перевірка:            у nvim ${C_B}:checkhealth${C_0}, ${C_B}:Mason${C_0}, ${C_B}:Lazy${C_0}

  Іконки потребують Nerd Font у терміналі на ТВОЄМУ ПК (./install.sh --font локально).
EOF
