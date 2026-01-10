#!/bin/bash
set -euo pipefail

# Colors
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
DIM='\033[2m'
BOLD='\033[1m'
REVERSE='\033[7m'
NC='\033[0m'

get_agents() {
    ps aux --sort=-%mem | awk '$11 ~ /^(claude|opencode)$/ || $11 ~ /\/(claude|opencode)$/' || true
}

format_time() {
    local minutes=$1
    if [[ $minutes -ge 60 ]]; then
        echo "$((minutes / 60))h $((minutes % 60))m"
    else
        echo "${minutes}m"
    fi
}

format_agent_line() {
    local line="$1"
    local pid=$(echo "$line" | awk '{print $2}')
    local mem=$(echo "$line" | awk '{print $4}')
    local full_cmd=$(echo "$line" | awk '{for(i=11;i<=NF;i++) printf "%s ", $i}')

    local type="unknown"
    [[ "$line" == *"claude"* ]] && type="claude"
    [[ "$line" == *"opencode"* ]] && type="opencode"

    local cwd=$(readlink -f /proc/$pid/cwd 2>/dev/null || echo "?")
    cwd=${cwd/#$HOME/\~}
    [[ ${#cwd} -gt 28 ]] && cwd="...${cwd: -25}"

    local cmd_display="${full_cmd:0:40}"
    [[ ${#full_cmd} -gt 40 ]] && cmd_display="${cmd_display}..."

    local elapsed=$(ps -o etimes= -p $pid 2>/dev/null | tr -d ' ')
    local time_str="?"
    [[ -n "$elapsed" ]] && time_str=$(format_time $((elapsed / 60)))

    printf "%-8s %-10s %-8s %-10s %-30s %s" "$pid" "$type" "${mem}%" "$time_str" "$cwd" "$cmd_display"
}

draw_screen() {
    local selected=$1
    shift
    local agents=("$@")

    clear
    echo -e "${CYAN}${BOLD}Running Agents${NC}  ${DIM}(j/k:move  d:kill  r:refresh  q:quit)${NC}"
    echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    printf "${DIM}%-8s %-10s %-8s %-10s %-30s %s${NC}\n" "PID" "TYPE" "MEM" "TIME" "CWD" "CMD"
    echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if [[ ${#agents[@]} -eq 0 ]]; then
        echo -e "${DIM}No running agents${NC}"
        return
    fi

    for i in "${!agents[@]}"; do
        local line=$(format_agent_line "${agents[$i]}")
        if [[ $i -eq $selected ]]; then
            echo -e "${REVERSE}${line}${NC}"
        else
            echo "$line"
        fi
    done
}

interactive_mode() {
    local selected=0
    local agents=()

    # Hide cursor
    tput civis
    trap 'tput cnorm; exit' EXIT INT TERM

    while true; do
        # Refresh agent list
        mapfile -t agents < <(get_agents)

        # Clamp selection
        if [[ ${#agents[@]} -eq 0 ]]; then
            selected=0
        elif [[ $selected -ge ${#agents[@]} ]]; then
            selected=$((${#agents[@]} - 1))
        fi

        draw_screen $selected "${agents[@]}"

        # Read single keypress
        read -rsn1 key

        # Handle arrow keys (escape sequences)
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 -t 0.1 key
            case "$key" in
                '[A') key='k' ;;  # Up
                '[B') key='j' ;;  # Down
            esac
        fi

        case "$key" in
            j|J)
                [[ ${#agents[@]} -gt 0 ]] && selected=$(( (selected + 1) % ${#agents[@]} ))
                ;;
            k|K)
                [[ ${#agents[@]} -gt 0 ]] && selected=$(( (selected - 1 + ${#agents[@]}) % ${#agents[@]} ))
                ;;
            d|D|x|X)
                if [[ ${#agents[@]} -gt 0 ]]; then
                    local pid=$(echo "${agents[$selected]}" | awk '{print $2}')
                    kill "$pid" 2>/dev/null && {
                        # Brief feedback
                        echo -e "\n${GREEN}Killed $pid${NC}"
                        sleep 0.3
                    }
                fi
                ;;
            r|R)
                # Just refresh (loop will do it)
                ;;
            q|Q)
                break
                ;;
        esac
    done
}

list_agents() {
    local agents
    agents=$(get_agents)

    if [[ -z "$agents" ]]; then
        echo -e "${DIM}No running agents${NC}"
        return
    fi

    echo -e "${CYAN}Running Agents${NC}"
    echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    printf "${DIM}%-8s %-10s %-8s %-10s %-30s %s${NC}\n" "PID" "TYPE" "MEM" "TIME" "CWD" "CMD"
    echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    echo "$agents" | while read -r line; do
        format_agent_line "$line"
        echo
    done
    echo ""
}

kill_all() {
    local agents
    agents=$(get_agents)

    if [[ -z "$agents" ]]; then
        echo -e "${DIM}No running agents${NC}"
        return
    fi

    local count=$(echo "$agents" | wc -l)

    if command -v gum &> /dev/null; then
        if ! gum confirm "Kill all $count agents?"; then
            return
        fi
    fi

    echo "$agents" | awk '{print $2}' | xargs -r kill
    echo -e "${GREEN}Killed $count agents${NC}"
}

usage() {
    echo "Usage: agents [command]"
    echo ""
    echo "Commands:"
    echo "  (none)      Interactive mode (default)"
    echo "  list, ls    List agents and exit"
    echo "  killall     Kill all agents"
    echo "  help        Show this help"
    echo ""
    echo "Interactive keys:"
    echo "  j/↓         Move down"
    echo "  k/↑         Move up"
    echo "  d/x         Kill selected"
    echo "  r           Refresh"
    echo "  q           Quit"
}

case "${1:-}" in
    "")
        interactive_mode
        ;;
    list|ls)
        list_agents
        ;;
    killall)
        kill_all
        ;;
    help|-h|--help)
        usage
        ;;
    *)
        echo "Unknown command: $1"
        usage
        exit 1
        ;;
esac
