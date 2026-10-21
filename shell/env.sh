# Підключається з ~/.bashrc / ~/.zshrc скриптом install.sh
# Все, що ставить install.sh, живе в ~/.local (без sudo).

_lu_prepend() { case ":$PATH:" in *":$1:"*) ;; *) [ -d "$1" ] && PATH="$1:$PATH" ;; esac; }
_lu_prepend "$HOME/.local/bin"
_lu_prepend "$HOME/.local/opt/node/bin"
_lu_prepend "$HOME/.local/opt/go/bin"
_lu_prepend "$HOME/go/bin"
export PATH
unset -f _lu_prepend

if command -v nvim >/dev/null 2>&1; then
  export EDITOR=nvim
  export VISUAL=nvim
  export MANPAGER='nvim +Man!'
  alias vim='nvim'
  alias vi='nvim'
  alias v='nvim'
fi

if command -v tmux >/dev/null 2>&1; then
  # t        → підключитись до сесії "main" (або створити її)
  # t work   → те саме для сесії "work"
  t() { tmux -u new-session -A -s "${1:-main}"; }
  alias tl='tmux ls'
  alias tmux='tmux -u'
fi
