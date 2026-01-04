# Environment Configuration
# ══════════════════════════════════════════════════════════════════════════════

# History
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt SHARE_HISTORY

# Directory navigation
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

# Completion
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Vi mode
bindkey -v
export KEYTIMEOUT=1

# Cursor shape for vi modes
function zle-keymap-select {
    if [[ ${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
        echo -ne '\e[2 q'
    elif [[ ${KEYMAP} == main ]] || [[ ${KEYMAP} == viins ]] || [[ $1 = 'beam' ]]; then
        echo -ne '\e[6 q'
    fi
}
zle -N zle-keymap-select

function zle-line-init {
    echo -ne '\e[6 q'
}
zle -N zle-line-init

# Better history search
bindkey '^R' history-incremental-search-backward
bindkey '^P' up-line-or-history
bindkey '^N' down-line-or-history

# Edit command in vim
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line

# Prompt
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' %F{cyan}(%b)%f'
setopt PROMPT_SUBST
PROMPT='%F{green}%n@%m%f:%F{blue}%~%f${vcs_info_msg_0_} %(!.#.$) '

# Environment
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"
export LANG="en_US.UTF-8"

# XDG Base Directory
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# Development directories
export DEV_HOME="$HOME/dev"

# PATH additions
typeset -U path
path=(
    $HOME/.local/bin
    $HOME/dev/bin
    $path
)

# fnm (Fast Node Manager)
if [[ -d "$HOME/.local/share/fnm" ]]; then
    export FNM_PATH="$HOME/.local/share/fnm"
    path=($FNM_PATH $path)
    eval "$(fnm env --use-on-cd)"
fi

# Bun
if [[ -d "$HOME/.bun" ]]; then
    export BUN_INSTALL="$HOME/.bun"
    path=($BUN_INSTALL/bin $path)
fi

# pnpm
if [[ -d "$HOME/.local/share/pnpm" ]]; then
    export PNPM_HOME="$HOME/.local/share/pnpm"
    path=($PNPM_HOME $path)
fi

# Aliases
alias ls='ls --color=auto'
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'

alias vim='nvim'
alias vi='nvim'

alias g='git'
alias gs='git status'
alias gd='git diff'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline -20'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias t='tmux'
alias ta='tmux attach -t'
alias tn='tmux new -s'
alias tl='tmux list-sessions'

alias c='claude'

# Functions

mkcd() {
    mkdir -p "$1" && cd "$1"
}

cdl() {
    cd "$1" && ls -la
}

dev() {
    cd "$DEV_HOME/${1:-}"
}

osc52() {
    printf "\033]52;c;%s\a" "$(base64)"
}

tailscale-ssh() {
    echo "Tailscale IP: $(tailscale ip -4 2>/dev/null || echo 'Not connected')"
}

# SSH Agent (if not already running)
if [[ -z "$SSH_AUTH_SOCK" ]]; then
    eval "$(ssh-agent -s)" > /dev/null
fi

# Source local overrides if present
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
