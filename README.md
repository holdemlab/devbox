# devbox

Neovim у ролі IDE і tmux з пресетом для Debian/Ubuntu x86_64. **sudo не потрібен**: усе ставиться в `~/.local`.
Тема Catppuccin Mocha спільна для обох програм.

## Встановлення

```bash
git clone <URL-твого-репо> ~/devbox
cd ~/devbox
bash install.sh          # або ./install.sh після chmod +x install.sh
exec $SHELL -l
```

Оновлення на сервері:

```bash
cd ~/devbox && git pull && bash install.sh            # конфіги + нові інструменти
bash install.sh --upgrade                                     # примусово свіжі nvim/tmux/node/go/rg/fd
```

Конфіги підключені **симлінками** на репозиторій (`~/.config/nvim`, `~/.tmux.conf`), тому після `git pull` зміни діють одразу.
Якщо конфіги вже були, вони зберігаються поруч як `*.bak-ДАТА`.

### Опції

| Опція | Що робить |
|---|---|
| `--nvim-only` / `--tmux-only` | поставити лише одну частину |
| `--no-node` | без Node.js, тобто без LSP для bash/yaml/json/docker/pyright/ts/html/css |
| `--no-go` | без Go, тобто без gopls/gofumpt/goimports |
| `--sudo` | дозволити `apt` для відсутніх пакетів (build-essential, unzip, tmux) |
| `--font` | поставити JetBrainsMono Nerd Font, **на свою локальну машину** |
| `--copy` | копіювати конфіги замість симлінків |
| `--upgrade` | наново завантажити всі бінарники |
| `--skip-plugins` | не ставити плагіни і LSP одразу; поставляться при першому запуску nvim |
| `--no-shell` | не змінювати `~/.bashrc` і `~/.zshrc` |

### Що куди ставиться

| Компонент | Звідки | Куди |
|---|---|---|
| Neovim (остання стабільна) | GitHub releases; для glibc < 2.34 збірка з `neovim/neovim-releases` | `~/.local/opt/nvim` |
| tmux | системний, якщо ≥ 3.0; інакше статичний бінарник | `~/.local/bin/tmux` |
| ripgrep, fd | статичні musl-збірки | `~/.local/bin` |
| Node.js LTS, Go | nodejs.org, go.dev (лише якщо їх ще немає) | `~/.local/opt/{node,go}` |
| tree-sitter CLI | офіційний бінарник (glibc ≥ 2.39) або shim із `bin/` | `~/.local/bin/tree-sitter` |
| LSP, форматери, лінтери | Mason | `~/.local/share/nvim/mason` |
| Плагіни tmux | TPM | `~/.tmux/plugins` |

Логи встановлення лежать у `~/.cache/devbox/*.log`.

### Обмеження без sudo

- **C-компілятор.** Без `gcc`/`cc` treesitter-парсери не компілюються. Підсвітка тоді працює на стандартних regex-синтаксисах Vim, тобто трохи простіша. Інше (LSP, автодоповнення, пошук) працює. Рішення: `apt install build-essential` від адміна або `--sudo`.
- **unzip.** Якщо його немає, ставиться python-замінник (`bin/unzip-shim`).
- **Іконки.** Їх малює термінал на **твоєму ПК**, тому Nerd Font потрібен локально (`./install.sh --font` або вручну). Без шрифту: `export NVIM_NO_ICONS=1`.

---

## Neovim: шпаргалка

`<leader>` = **Space**. Натисни Space і почекай: which-key покаже всі команди.

**Файли і пошук**

| Клавіші | Дія |
|---|---|
| `Space Space` / `Space ff` | знайти файл |
| `Space /` | grep по проєкту |
| `Space ,` | відкриті буфери |
| `Space fr` | недавні файли |
| `Space e` | дерево файлів (у дереві: `l` відкрити, `h` закрити, `a` створити, `d` видалити, `r` перейменувати) |
| `Space sw` | grep слова під курсором |
| `Space sr` | повторити останній пошук |
| `Space sk` | пошук по всіх клавішах |

**Код (LSP)**

| Клавіші | Дія |
|---|---|
| `gd` / `gr` / `gI` / `gy` | визначення / посилання / реалізації / тип |
| `K` | документація |
| `Space ca` | code action (quick fix) |
| `Space cr` | перейменувати символ |
| `Space cf` | відформатувати |
| `Space uf` | увімкнути/вимкнути форматування при збереженні |
| `]d` / `[d` | наступна / попередня помилка |
| `Space xx` | список усіх помилок (Trouble) |
| `Space cs` | структура файлу (символи) |
| `Space ch` | inlay hints |

**Автодоповнення:** `Tab` або `Enter` приймає, `C-n`/`C-p` вибирає, `C-Space` відкриває меню, `C-e` закриває.

**Редагування**

| Клавіші | Дія |
|---|---|
| `C-s` | зберегти |
| `S-h` / `S-l` | попередній / наступний буфер |
| `Space bd` | закрити буфер |
| `Alt-j` / `Alt-k` | перемістити рядок або виділення |
| `gcc` / `gc` (у visual) | закоментувати |
| `sa` / `sd` / `sr` | додати / видалити / замінити дужки або лапки (mini.surround), напр. `saiw"` |
| `Space p` (visual) | вставити, не втрачаючи буфер |

**Git:** `]h` / `[h` переходять між змінами, `Space gp` показує зміну, `Space gr` її скидає, `Space gb` показує blame рядка, `Space gs` відкриває git status.

**Вікна:** `C-h/j/k/l` переходить між вікнами nvim **і панелями tmux**. `Space -` / `Space |` ділять вікно.

**Менеджери:** `Space L` відкриває Lazy (плагіни), `Space M` відкриває Mason (LSP), `:checkhealth` перевіряє стан.

**Буфер обміну по SSH.** Копіювання (`y`) працює через OSC 52, і текст потрапляє в буфер обміну твого ПК. Потрібен термінал з OSC 52: kitty, WezTerm, Alacritty, iTerm2, Windows Terminal, GNOME Terminal ≥ 3.5x/VTE.

### Мови

| Мова | LSP | Форматер |
|---|---|---|
| Bash/sh | bashls + shellcheck | shfmt |
| Python | pyright + ruff | ruff |
| Go | gopls | goimports + gofumpt |
| JS/TS | ts_ls | prettier |
| HTML/CSS | html, cssls | prettier |
| JSON/YAML | jsonls, yamlls + SchemaStore (compose, k8s, GH Actions...) | prettier (вручну `Space cf`) |
| Dockerfile / compose | dockerls, docker_compose_language_service | – |
| Lua | lua_ls | stylua |

Додати свій сервер: `Space M`, знайти його, натиснути `i`. mason-lspconfig увімкне його автоматично.

---

## tmux: шпаргалка

Prefix = **Ctrl+a**.

| Клавіші | Дія |
|---|---|
| `t` (у shell) | підключитися до сесії `main` або створити її (`t work` для іншої) |
| `prefix \|` / `prefix -` | поділити вертикально / горизонтально |
| `C-h/j/k/l` | перейти між панелями (і вікнами nvim) |
| `prefix h/j/k/l` | те саме через prefix |
| `prefix H/J/K/L` | змінити розмір (можна тиснути повторно) |
| `prefix z` | розгорнути панель на весь екран |
| `prefix c` | нове вікно |
| `Alt+1..9` | перейти у вікно N |
| `Shift+←/→` | попереднє / наступне вікно |
| `prefix Tab` | останнє вікно |
| `prefix S` | **синхронне введення** в усі панелі (статус стає помаранчевим) |
| `prefix s` | список сесій |
| `prefix d` | від'єднатися (сесія живе далі) |
| `prefix [` або `prefix Enter` | copy mode: `v` виділити, `y` скопіювати (через OSC 52 у буфер ПК) |
| `prefix C-l` | очистити екран (бо `C-l` зайнятий навігацією) |
| `prefix r` | перечитати конфіг |
| `prefix C-s` / `prefix C-r` | зберегти / відновити сесії (resurrect; автозбереження кожні 15 хв) |
| `prefix I` / `prefix U` | встановити / оновити плагіни |

Колір сесії в статус-барі: **фіолетовий** у звичайному режимі, **червоний** після натискання prefix, **помаранчевий** при синхронному введенні. Праворуч показано ім'я хоста.

Локальні налаштування для конкретного сервера, що не потрапляють у git, клади в `~/.tmux.local.conf`.

---

## Структура

```
install.sh              інсталятор
nvim/                   конфіг Neovim (~/.config/nvim → сюди)
  init.lua
  lua/config/           options, keymaps, autocmds, lazy bootstrap
  lua/plugins/          ui, editor, treesitter, lsp, coding
tmux/tmux.conf          (~/.tmux.conf → сюди)
shell/env.sh            PATH, EDITOR, аліаси (підключається з ~/.bashrc)
bin/                    tree-sitter-shim, unzip-shim (запасні варіанти без sudo)
```

`nvim/lazy-lock.json` з'явиться після першого запуску. Закоміть його, щоб на всіх серверах були ті самі версії плагінів.
