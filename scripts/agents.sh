#!/bin/bash
set -euo pipefail

# Colors
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
DIM='\033[2m'
NC='\033[0m'

get_agents() {
    # Match only processes where the command (field 11) is claude/opencode binary
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
        local pid=$(echo "$line" | awk '{print $2}')
        local mem=$(echo "$line" | awk '{print $4}')
        local full_cmd=$(echo "$line" | awk '{for(i=11;i<=NF;i++) printf "%s ", $i}')

        # Determine type from full command line
        local type="unknown"
        if [[ "$line" == *"claude"* ]]; then
            type="claude"
        fi
        if [[ "$line" == *"opencode"* ]]; then
            type="opencode"
        fi

        # Get working directory
        local cwd=$(readlink -f /proc/$pid/cwd 2>/dev/null || echo "?")
        cwd=${cwd/#$HOME/\~}
        # Truncate cwd for display
        if [[ ${#cwd} -gt 28 ]]; then
            cwd="...${cwd: -25}"
        fi

        # Truncate command for display
        local cmd_display="${full_cmd:0:40}"
        [[ ${#full_cmd} -gt 40 ]] && cmd_display="${cmd_display}..."

        # Get elapsed time
        local elapsed=$(ps -o etimes= -p $pid 2>/dev/null | tr -d ' ')
        local time_str="?"
        if [[ -n "$elapsed" ]]; then
            time_str=$(format_time $((elapsed / 60)))
        fi

        printf "%-8s %-10s %-8s %-10s %-30s %s\n" "$pid" "$type" "${mem}%" "$time_str" "$cwd" "$cmd_display"
    done

    echo ""
}

kill_agent() {
    local agents
    agents=$(get_agents)

    if [[ -z "$agents" ]]; then
        echo -e "${DIM}No running agents${NC}"
        return
    fi

    # Build options for gum
    local options=()
    while read -r line; do
        local pid=$(echo "$line" | awk '{print $2}')
        local mem=$(echo "$line" | awk '{print $4}')
        local cmd=$(echo "$line" | awk '{print $11}')
        local cwd=$(readlink -f /proc/$pid/cwd 2>/dev/null || echo "?")
        cwd=${cwd/#$HOME/\~}

        local type="unknown"
        if [[ "$cmd" == *"claude"* ]]; then
            type="claude"
        elif [[ "$cmd" == *"opencode"* ]]; then
            type="opencode"
        fi

        options+=("$pid  $type  ${mem}%  $cwd")
    done <<< "$agents"

    if ! command -v gum &> /dev/null; then
        echo "gum not installed - listing PIDs instead:"
        list_agents
        echo "Kill manually: kill <PID>"
        return
    fi

    local selected
    selected=$(printf '%s\n' "${options[@]}" | gum choose --header "Select agent to kill:")

    if [[ -n "$selected" ]]; then
        local pid=$(echo "$selected" | awk '{print $1}')
        if gum confirm "Kill process $pid?"; then
            kill "$pid" && echo -e "${GREEN}Killed $pid${NC}"
        fi
    fi
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
    echo "  list, ls    List running agents (default)"
    echo "  kill, k     Interactive kill"
    echo "  killall     Kill all agents"
    echo "  help        Show this help"
}

case "${1:-list}" in
    list|ls|"")
        list_agents
        ;;
    kill|k)
        kill_agent
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
