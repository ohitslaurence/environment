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
    $HOME/.opencode/bin
    $HOME/dev/bin
    $path
)

# ══════════════════════════════════════════════════════════════════════════════
# Tool Initialization
# ══════════════════════════════════════════════════════════════════════════════

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

# zoxide (smarter cd)
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
fi

# atuin (better history)
if command -v atuin &> /dev/null; then
    eval "$(atuin init zsh --disable-up-arrow)"
fi

# fzf
if command -v fzf &> /dev/null; then
    source <(fzf --zsh 2>/dev/null) || true
fi

# direnv
if command -v direnv &> /dev/null; then
    eval "$(direnv hook zsh)"
fi

# zsh plugins (Ubuntu paths)
[[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ══════════════════════════════════════════════════════════════════════════════
# Modern CLI Aliases
# ══════════════════════════════════════════════════════════════════════════════

# eza (better ls)
if command -v eza &> /dev/null; then
    alias ls="eza"
    alias ll="eza -la --git"
    alias la="eza -a"
    alias lt="eza --tree --level=2 --ignore-glob='node_modules|.git|dist|build'"
    alias lta="eza --tree --level=3 --ignore-glob='node_modules|.git|dist|build'"
else
    alias ls='ls --color=auto'
    alias ll='ls -lah'
    alias la='ls -A'
fi

# bat (better cat)
if command -v batcat &> /dev/null; then
    alias cat="batcat --paging=never"
    alias bat="batcat"
elif command -v bat &> /dev/null; then
    alias cat="bat --paging=never"
fi

# zoxide
if command -v zoxide &> /dev/null; then
    alias cd="z"
fi

# ══════════════════════════════════════════════════════════════════════════════
# General Aliases
# ══════════════════════════════════════════════════════════════════════════════

alias vim='nvim'
alias vi='nvim'

alias g='git'
alias gs='git status'
alias gd='git diff'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline -20'
alias lg='lazygit'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias t='tmux'
alias tl='tmux list-sessions'

# Create or attach to tmux session (starts in ~/dev/<name> if it exists)
unalias ta 2>/dev/null || true
ta() {
    local name="${1:-main}"

    # If session exists, just attach (don't change directory)
    if tmux has-session -t "$name" 2>/dev/null; then
        tmux attach -t "$name"
    else
        # New session - start in workspace dir if it exists
        local start_dir="$HOME"
        [[ -d "$HOME/dev/$name" ]] && start_dir="$HOME/dev/$name"
        tmux new-session -s "$name" -c "$start_dir"
    fi
}

# Switch to or create a tmux window for a project within current workspace
# Usage: tw platform  (switches to/creates "platform" window in ~/dev/<session>/platform)
tw() {
    local name="$1"

    if [[ -z "$name" ]]; then
        echo "Usage: tw <project>"
        echo "Available projects in current workspace:"
        local session=$(tmux display-message -p '#S')
        ls "$HOME/dev/$session" 2>/dev/null | head -20
        return 1
    fi

    # Get current session name (e.g., "spritz")
    local session=$(tmux display-message -p '#S')
    local dir="$HOME/dev/$session/$name"

    # Check if window exists in current session
    if tmux list-windows -F '#W' | grep -q "^${name}$"; then
        # Switch to existing window
        tmux select-window -t "$name"
    else
        # Create new window
        if [[ -d "$dir" ]]; then
            tmux new-window -n "$name" -c "$dir"
        else
            echo "Directory not found: $dir"
            return 1
        fi
    fi
}

alias c='claude'
alias ccu='npx ccusage@latest'
alias lzd='lazydocker'
alias sz='source ~/.zshrc'
alias up='~/dev/environment/scripts/upgrade.sh'
alias cleanup='~/dev/environment/scripts/cleanup.sh'

# ══════════════════════════════════════════════════════════════════════════════
# Functions
# ══════════════════════════════════════════════════════════════════════════════

mkcd() {
    mkdir -p "$1" && cd "$1"
}

dev() {
    cd "$DEV_HOME/${1:-}"
}

cc() {
    claude --dangerously-skip-permissions --continue "$@"
}

# SSH Agent (if not already running)
if [[ -z "$SSH_AUTH_SOCK" ]]; then
    eval "$(ssh-agent -s)" > /dev/null
fi

# Source local overrides if present
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Cargo env (for Rust tools)
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"
export PATH="$HOME/.local/nvim-linux-x86_64/bin:$PATH"

# strix
export PATH="/home/laurence/.strix/bin:$PATH"

. "$HOME/.local/share/../bin/env"

# bun completions
[ -s "/home/laurence/.bun/_bun" ] && source "/home/laurence/.bun/_bun"
