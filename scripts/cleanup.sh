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

# Default threshold: 1 hour in seconds
STALE_THRESHOLD=${STALE_THRESHOLD:-3600}
CPU_THRESHOLD=${CPU_THRESHOLD:-1.0}

get_stale_claude() {
    # Find claude processes with low CPU and old age
    ps -eo pid,etimes,%cpu,%mem,comm,args --sort=-etimes 2>/dev/null | \
    awk -v threshold="$STALE_THRESHOLD" -v cpu_thresh="$CPU_THRESHOLD" '
        $5 == "claude" && $2 > threshold && $3 < cpu_thresh {print}
    ' || true
}

get_stale_zed_wrappers() {
    # Find Zed ACP wrapper processes (node running claude-code-acp)
    ps -eo pid,etimes,%cpu,%mem,comm,args --sort=-etimes 2>/dev/null | \
    awk -v threshold="$STALE_THRESHOLD" -v cpu_thresh="$CPU_THRESHOLD" '
        /claude-code-acp/ && $2 > threshold && $3 < cpu_thresh {print}
    ' || true
}

get_all_stale() {
    { get_stale_claude; get_stale_zed_wrappers; } | sort -k2 -rn
}

format_time() {
    local seconds=$1
    local hours=$((seconds / 3600))
    local minutes=$(((seconds % 3600) / 60))

    if [[ $hours -gt 0 ]]; then
        echo "${hours}h ${minutes}m"
    else
        echo "${minutes}m"
    fi
}

format_line() {
    local line="$1"
    local pid=$(echo "$line" | awk '{print $1}')
    local elapsed=$(echo "$line" | awk '{print $2}')
    local cpu=$(echo "$line" | awk '{print $3}')
    local mem=$(echo "$line" | awk '{print $4}')
    local comm=$(echo "$line" | awk '{print $5}')
    local args=$(echo "$line" | awk '{for(i=6;i<=NF;i++) printf "%s ", $i}')

    local type="claude"
    [[ "$args" == *"claude-code-acp"* ]] && type="zed-acp"

    local time_str=$(format_time "$elapsed")
    local args_short="${args:0:50}"
    [[ ${#args} -gt 50 ]] && args_short="${args_short}..."

    printf "%-8s %-10s %-8s %-6s %-10s %s" "$pid" "$type" "$time_str" "${cpu}%" "${mem}%" "$args_short"
}

list_stale() {
    local stale
    stale=$(get_all_stale)

    local threshold_hrs=$((STALE_THRESHOLD / 3600))
    local threshold_mins=$(((STALE_THRESHOLD % 3600) / 60))
    local threshold_str="${threshold_hrs}h ${threshold_mins}m"
    [[ $threshold_hrs -eq 0 ]] && threshold_str="${threshold_mins}m"

    echo -e "${CYAN}${BOLD}Stale Processes${NC}  ${DIM}(age > ${threshold_str}, cpu < ${CPU_THRESHOLD}%)${NC}"
    echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    printf "${DIM}%-8s %-10s %-8s %-6s %-10s %s${NC}\n" "PID" "TYPE" "AGE" "CPU" "MEM" "COMMAND"
    echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if [[ -z "$stale" ]]; then
        echo -e "${GREEN}No stale processes found${NC}"
        return
    fi

    local count=0
    local total_mem=0
    while IFS= read -r line; do
        format_line "$line"
        echo
        ((count++)) || true
        local mem=$(echo "$line" | awk '{print $4}')
        total_mem=$(awk "BEGIN {print $total_mem + $mem}")
    done <<< "$stale"

    echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Total: ${count} processes, ~${total_mem}% memory${NC}"
}

clean_stale() {
    local stale
    stale=$(get_all_stale)

    if [[ -z "$stale" ]]; then
        echo -e "${GREEN}No stale processes to clean${NC}"
        return
    fi

    local count=$(echo "$stale" | wc -l)
    local pids=$(echo "$stale" | awk '{print $1}' | tr '\n' ' ')

    if [[ "${1:-}" != "-f" && "${1:-}" != "--force" ]]; then
        echo -e "${YELLOW}Will kill ${count} stale processes:${NC}"
        list_stale
        echo ""

        if command -v gum &> /dev/null; then
            if ! gum confirm "Kill these ${count} processes?"; then
                echo "Aborted"
                return
            fi
        else
            read -p "Kill these ${count} processes? [y/N] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Aborted"
                return
            fi
        fi
    fi

    local killed=0
    for pid in $pids; do
        if kill "$pid" 2>/dev/null; then
            ((killed++))
        fi
    done

    echo -e "${GREEN}Killed ${killed}/${count} stale processes${NC}"
}

draw_screen() {
    local selected=$1
    shift
    local processes=("$@")

    clear
    echo -e "${CYAN}${BOLD}Stale Processes${NC}  ${DIM}(j/k:move  d:kill  D:kill-all  r:refresh  q:quit)${NC}"
    echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    printf "${DIM}%-8s %-10s %-8s %-6s %-10s %s${NC}\n" "PID" "TYPE" "AGE" "CPU" "MEM" "COMMAND"
    echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if [[ ${#processes[@]} -eq 0 ]]; then
        echo -e "${GREEN}No stale processes${NC}"
        return
    fi

    for i in "${!processes[@]}"; do
        local line=$(format_line "${processes[$i]}")
        if [[ $i -eq $selected ]]; then
            echo -e "${REVERSE}${line}${NC}"
        else
            echo "$line"
        fi
    done
}

interactive_mode() {
    local selected=0
    local processes=()

    tput civis
    trap 'tput cnorm; exit' EXIT INT TERM

    while true; do
        mapfile -t processes < <(get_all_stale)

        if [[ ${#processes[@]} -eq 0 ]]; then
            selected=0
        elif [[ $selected -ge ${#processes[@]} ]]; then
            selected=$((${#processes[@]} - 1))
        fi

        draw_screen $selected "${processes[@]}"

        read -rsn1 key

        if [[ $key == $'\x1b' ]]; then
            read -rsn2 -t 0.1 key
            case "$key" in
                '[A') key='k' ;;
                '[B') key='j' ;;
            esac
        fi

        case "$key" in
            j|J)
                [[ ${#processes[@]} -gt 0 ]] && selected=$(( (selected + 1) % ${#processes[@]} ))
                ;;
            k|K)
                [[ ${#processes[@]} -gt 0 ]] && selected=$(( (selected - 1 + ${#processes[@]}) % ${#processes[@]} ))
                ;;
            d|x)
                if [[ ${#processes[@]} -gt 0 ]]; then
                    local pid=$(echo "${processes[$selected]}" | awk '{print $1}')
                    kill "$pid" 2>/dev/null && {
                        echo -e "\n${GREEN}Killed $pid${NC}"
                        sleep 0.3
                    }
                fi
                ;;
            D|X)
                if [[ ${#processes[@]} -gt 0 ]]; then
                    local pids=$(printf '%s\n' "${processes[@]}" | awk '{print $1}')
                    echo "$pids" | xargs -r kill 2>/dev/null
                    echo -e "\n${GREEN}Killed all${NC}"
                    sleep 0.3
                fi
                ;;
            r|R)
                ;;
            q|Q)
                break
                ;;
        esac
    done
}

usage() {
    echo "Usage: cleanup [command] [options]"
    echo ""
    echo "Find and kill stale Claude sessions and Zed ACP wrappers."
    echo ""
    echo "Commands:"
    echo "  (none)      Interactive mode (default)"
    echo "  list, ls    List stale processes"
    echo "  clean       Kill stale processes (with confirmation)"
    echo "  clean -f    Kill stale processes (no confirmation)"
    echo "  help        Show this help"
    echo ""
    echo "Environment variables:"
    echo "  STALE_THRESHOLD  Age in seconds to consider stale (default: 3600 = 1hr)"
    echo "  CPU_THRESHOLD    CPU % below which process is idle (default: 1.0)"
    echo ""
    echo "Examples:"
    echo "  cleanup                          # Interactive mode"
    echo "  cleanup list                     # Show stale processes"
    echo "  cleanup clean                    # Kill with confirmation"
    echo "  STALE_THRESHOLD=7200 cleanup ls  # Show processes older than 2hrs"
    echo ""
    echo "Interactive keys:"
    echo "  j/↓         Move down"
    echo "  k/↑         Move up"
    echo "  d/x         Kill selected"
    echo "  D/X         Kill all"
    echo "  r           Refresh"
    echo "  q           Quit"
}

case "${1:-}" in
    "")
        interactive_mode
        ;;
    list|ls)
        list_stale
        ;;
    clean)
        shift
        clean_stale "$@"
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
