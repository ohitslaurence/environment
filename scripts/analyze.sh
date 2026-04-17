#!/bin/bash
set -euo pipefail

# Usage: analyze.sh [--sync-state]
#   --sync-state  rewrite ~/.config/vps-setup/state.json from observed reality
SYNC_STATE=false
for arg in "$@"; do
    [[ "$arg" == "--sync-state" ]] && SYNC_STATE=true
done

STATE_FILE="$HOME/.config/vps-setup/state.json"

echo "══════════════════════════════════════════════════════════════"
echo "                   Security Analysis Report"
echo "══════════════════════════════════════════════════════════════"
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Wrap sudo so password prompts don't kill the script under `set -e`.
# Returns empty output instead of failing when sudo isn't available.
_sudo() { sudo -n "$@" 2>/dev/null || true; }
HAS_SUDO=$(sudo -n true 2>/dev/null && echo true || echo false)
if [[ "$HAS_SUDO" != "true" ]]; then
    echo -e "  ${YELLOW}⚠${NC} Running without passwordless sudo — UFW & port-listing checks will be limited."
    echo -e "  ${YELLOW}⚠${NC} Re-run with 'sudo bash $(basename "$0")' for full coverage."
    echo ""
fi

check_pass() {
    echo -e "  ${GREEN}✓${NC} $1"
}

check_warn() {
    echo -e "  ${YELLOW}⚠${NC} $1"
}

check_fail() {
    echo -e "  ${RED}✗${NC} $1"
}

echo "─────────────────────────────────────────────────────────────"
echo "                    System Information"
echo "─────────────────────────────────────────────────────────────"
echo ""
echo "  Hostname: $(hostname)"
echo "  OS: $(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "  Kernel: $(uname -r)"
echo "  Uptime: $(uptime -p)"
echo ""

echo "─────────────────────────────────────────────────────────────"
echo "                    Tailscale Status"
echo "─────────────────────────────────────────────────────────────"
echo ""

if command -v tailscale &> /dev/null; then
    if tailscale status &> /dev/null; then
        check_pass "Tailscale is running"
        TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "Unable to get IP")
        echo "      Tailscale IP: $TAILSCALE_IP"

        # Check if Tailscale SSH is enabled
        if tailscale status --json 2>/dev/null | grep -q 'tailscale.com/cap/ssh'; then
            check_pass "Tailscale SSH is enabled"
        else
            check_warn "Tailscale SSH not enabled (run: sudo tailscale up --ssh)"
        fi
    else
        check_fail "Tailscale installed but not connected"
        echo "      Run: sudo tailscale up --ssh"
    fi
else
    check_fail "Tailscale not installed"
fi
echo ""

echo "─────────────────────────────────────────────────────────────"
echo "                    Firewall Status"
echo "─────────────────────────────────────────────────────────────"
echo ""

# Active check works without sudo via systemd; rule inspection still needs sudo.
ufw_active() {
    _sudo ufw status | grep -q "Status: active" && return 0
    systemctl is-active --quiet ufw 2>/dev/null
}

if ufw_active; then
    check_pass "UFW is active"

    UFW_RULES=$(_sudo ufw status)
    if [[ -z "$UFW_RULES" ]]; then
        check_warn "Cannot inspect rules (need sudo) — re-run with: sudo bash $(basename "$0")"
    else
        if echo "$UFW_RULES" | grep -q "tailscale0"; then
            check_pass "Tailscale interface allowed"
        else
            check_warn "Tailscale interface not explicitly allowed"
        fi

        if echo "$UFW_RULES" | grep -qE "22.*ALLOW.*Anywhere|80.*ALLOW.*Anywhere|443.*ALLOW.*Anywhere"; then
            check_fail "Ports open to public internet (should only allow tailscale0)"
            echo "$UFW_RULES" | grep "ALLOW.*Anywhere" | head -5
        else
            check_pass "No ports open to public internet"
        fi
    fi
else
    check_fail "UFW is not active - server is exposed!"
    echo "      Run: sudo ufw enable"
fi
echo ""

echo "─────────────────────────────────────────────────────────────"
echo "                    SSH Daemon Status"
echo "─────────────────────────────────────────────────────────────"
echo ""

if systemctl is-active --quiet sshd 2>/dev/null || systemctl is-active --quiet ssh 2>/dev/null; then
    check_warn "OpenSSH daemon is running"
    echo "      With Tailscale SSH, OpenSSH is not needed."
    echo "      Disable with: sudo systemctl disable --now ssh"
elif systemctl is-active --quiet ssh.socket 2>/dev/null; then
    check_warn "OpenSSH socket is active (port 22 still listening)"
    echo "      Disable with: sudo systemctl disable --now ssh.socket"
else
    check_pass "OpenSSH fully disabled (using Tailscale SSH only)"
fi
echo ""

echo "─────────────────────────────────────────────────────────────"
echo "                    Listening Services"
echo "─────────────────────────────────────────────────────────────"
echo ""

echo "  Services listening on all interfaces (0.0.0.0 or *):"
EXPOSED=$(_sudo ss -tlnp | grep -E "0\.0\.0\.0:\*|::" | grep -v "127\." || true)
if [[ -n "$EXPOSED" ]]; then
    echo "$EXPOSED" | while read line; do
        check_warn "$line"
    done
    echo ""
    echo "  Note: These are blocked by UFW if enabled, but consider binding to localhost."
else
    check_pass "No services exposed on all interfaces"
fi
echo ""

echo "  Services on Tailscale interface:"
_sudo ss -tlnp | grep -E "LISTEN" | head -10 || ss -tlnp 2>/dev/null | grep -E "LISTEN" | head -10 || true
echo ""

echo "─────────────────────────────────────────────────────────────"
echo "                    System Hardening"
echo "─────────────────────────────────────────────────────────────"
echo ""

echo "[Automatic Updates]"
if dpkg -l | grep -q unattended-upgrades; then
    check_pass "Unattended upgrades installed"
    if systemctl is-enabled --quiet unattended-upgrades 2>/dev/null; then
        check_pass "Automatic security updates enabled"
    else
        check_warn "Automatic updates not enabled"
    fi
else
    check_fail "Unattended upgrades not installed"
fi
echo ""

echo "[System Updates]"
UPDATES=$(apt list --upgradable 2>/dev/null | grep -c "upgradable" || true)
UPDATES=${UPDATES:-0}
if [[ "$UPDATES" -eq 0 ]]; then
    check_pass "System is up to date"
else
    check_warn "$UPDATES packages can be upgraded"
fi
echo ""

echo "─────────────────────────────────────────────────────────────"
echo "                    Access Summary"
echo "─────────────────────────────────────────────────────────────"
echo ""

echo "[Users with Login Shell]"
grep -E ":/bin/(bash|zsh|sh)$" /etc/passwd | cut -d: -f1 | while read user; do
    echo "    $user"
done
echo ""

echo "[Sudo Users]"
getent group sudo | cut -d: -f4 | tr ',' '\n' | while read user; do
    [[ -n "$user" ]] && echo "    $user"
done
echo ""

echo "─────────────────────────────────────────────────────────────"
echo "                    Security Score"
echo "─────────────────────────────────────────────────────────────"
echo ""

SCORE=0
MAX_SCORE=5

# Tailscale running
tailscale status &> /dev/null && ((++SCORE))

# UFW active
_sudo ufw status | grep -q "Status: active" && ((++SCORE))

# OpenSSH disabled (service and socket)
! systemctl is-active --quiet sshd 2>/dev/null && ! systemctl is-active --quiet ssh 2>/dev/null && ! systemctl is-active --quiet ssh.socket 2>/dev/null && ((++SCORE))

# Auto updates
systemctl is-enabled --quiet unattended-upgrades 2>/dev/null && ((++SCORE))

# No public ports
! _sudo ufw status | grep -qE "22.*ALLOW.*Anywhere" && ((++SCORE))

echo "  Score: $SCORE / $MAX_SCORE"
echo ""

if [[ $SCORE -eq $MAX_SCORE ]]; then
    echo -e "  ${GREEN}EXCELLENT${NC} - Server is fully locked down to Tailscale only"
elif [[ $SCORE -ge 3 ]]; then
    echo -e "  ${YELLOW}GOOD${NC} - Some improvements possible"
else
    echo -e "  ${RED}NEEDS WORK${NC} - Review recommendations below"
fi
echo ""

echo "─────────────────────────────────────────────────────────────"
echo "                    Recommendations"
echo "─────────────────────────────────────────────────────────────"
echo ""

RECOMMENDATIONS=0

if ! tailscale status &> /dev/null 2>&1; then
    echo "  • Connect Tailscale: sudo tailscale up --ssh"
    ((++RECOMMENDATIONS))
fi

if ! _sudo ufw status | grep -q "Status: active"; then
    echo "  • Enable firewall: sudo ufw enable"
    ((++RECOMMENDATIONS))
fi

if systemctl is-active --quiet sshd 2>/dev/null || systemctl is-active --quiet ssh 2>/dev/null || systemctl is-active --quiet ssh.socket 2>/dev/null; then
    echo "  • Disable OpenSSH: sudo systemctl disable --now ssh ssh.socket"
    ((++RECOMMENDATIONS))
fi

if ! command -v gitleaks &> /dev/null; then
    echo "  • Install secret scanner: bash $(dirname "$0")/../steps/gitleaks.sh"
    ((++RECOMMENDATIONS))
fi

if [[ "$RECOMMENDATIONS" -eq 0 ]]; then
    echo "  None - your server is properly locked down!"
fi

echo ""
echo "─────────────────────────────────────────────────────────────"
echo "                    Docker Exposure"
echo "─────────────────────────────────────────────────────────────"
echo ""

if command -v docker &> /dev/null && docker info &> /dev/null 2>&1; then
    if [[ -f /etc/docker/daemon.json ]] && jq -e '.ip == "127.0.0.1"' /etc/docker/daemon.json &> /dev/null; then
        check_pass "Docker default publish IP is 127.0.0.1 (containers default to localhost)"
    else
        check_fail "Docker default publish IP is NOT pinned to 127.0.0.1"
        echo "      Containers using -p HOST:CONT will bind to 0.0.0.0 and bypass UFW."
        echo "      Re-run: sudo bash $(dirname "$0")/../steps/docker.sh"
    fi

    EXPOSED_CONTAINERS=$(docker ps --format '{{.Names}}|{{.Image}}|{{.Ports}}' | grep -E '0\.0\.0\.0|::' || true)
    if [[ -n "$EXPOSED_CONTAINERS" ]]; then
        check_fail "Container(s) currently publishing on ALL interfaces:"
        echo "$EXPOSED_CONTAINERS" | while IFS='|' read -r name image ports; do
            echo "      $name ($image): $ports"
        done
        echo "      Stop+recreate these containers to pick up the daemon default."
    else
        check_pass "No running containers exposed on 0.0.0.0"
    fi
else
    check_warn "Docker not installed or not accessible from this user"
fi
echo ""

echo "─────────────────────────────────────────────────────────────"
echo "                    Secret Scanner"
echo "─────────────────────────────────────────────────────────────"
echo ""

if command -v gitleaks &> /dev/null; then
    check_pass "gitleaks installed: $(gitleaks version 2>&1 | head -1)"
    echo "      Scan working tree:  gitleaks detect --source ~/dev --no-git"
    echo "      Scan with history:  gitleaks detect --source <repo>"
else
    check_warn "gitleaks not installed (run: bash $(dirname "$0")/../steps/gitleaks.sh)"
fi
echo ""

echo "─────────────────────────────────────────────────────────────"
echo "                    State Drift Detection"
echo "─────────────────────────────────────────────────────────────"
echo ""

if [[ ! -f "$STATE_FILE" ]] || ! command -v jq &> /dev/null; then
    check_warn "Skipping drift check (state.json or jq missing)"
else
    # Pairs of "step_key:observed_state_command"
    # Command must echo "true" or "false"
    declare -A OBSERVED
    OBSERVED[tailscale]=$(tailscale status &> /dev/null && echo true || echo false)
    OBSERVED[ufw]=$(ufw_active && echo true || echo false)
    if systemctl is-active --quiet ssh 2>/dev/null \
        || systemctl is-active --quiet sshd 2>/dev/null \
        || systemctl is-active --quiet ssh.socket 2>/dev/null; then
        OBSERVED[disable_ssh]=false
    else
        OBSERVED[disable_ssh]=true
    fi
    OBSERVED[docker]=$(command -v docker &> /dev/null && echo true || echo false)
    OBSERVED[bun]=$(command -v bun &> /dev/null && echo true || echo false)
    OBSERVED[node]=$(command -v node &> /dev/null || command -v fnm &> /dev/null && echo true || echo false)
    OBSERVED[claude]=$(command -v claude &> /dev/null && echo true || echo false)
    OBSERVED[opencode]=$(command -v opencode &> /dev/null && echo true || echo false)
    OBSERVED[codex]=$(command -v codex &> /dev/null && echo true || echo false)
    OBSERVED[nia]=$(command -v nia &> /dev/null && echo true || echo false)
    OBSERVED[gh_auth]=$(gh auth status &> /dev/null && echo true || echo false)
    OBSERVED[syncthing]=$(systemctl --user is-active --quiet syncthing 2>/dev/null \
        || systemctl is-active --quiet syncthing@${USER} 2>/dev/null \
        || pgrep -x syncthing &> /dev/null && echo true || echo false)
    OBSERVED[gritty]=$(command -v gritty &> /dev/null && echo true || echo false)
    OBSERVED[par]=$(command -v par &> /dev/null && echo true || echo false)
    OBSERVED[gitleaks]=$(command -v gitleaks &> /dev/null && echo true || echo false)
    OBSERVED[github_ssh]=$([[ -f "$HOME/.ssh/id_ed25519.pub" || -f "$HOME/.ssh/id_rsa.pub" ]] && echo true || echo false)
    OBSERVED[aws_sso]=$(command -v aws &> /dev/null && echo true || echo false)

    DRIFTED=()
    for key in "${!OBSERVED[@]}"; do
        recorded=$(jq -r ".$key // \"missing\"" "$STATE_FILE")
        observed="${OBSERVED[$key]}"
        if [[ "$recorded" != "$observed" && "$recorded" != "missing" ]]; then
            DRIFTED+=("$key:$recorded:$observed")
        fi
    done

    if [[ ${#DRIFTED[@]} -eq 0 ]]; then
        check_pass "No drift — state.json matches observed reality"
    else
        for entry in "${DRIFTED[@]}"; do
            IFS=: read -r key recorded observed <<< "$entry"
            check_fail "$key: state=$recorded but observed=$observed"
        done
        echo ""
        if $SYNC_STATE; then
            tmp=$(mktemp)
            cp "$STATE_FILE" "$tmp"
            for entry in "${DRIFTED[@]}"; do
                IFS=: read -r key recorded observed <<< "$entry"
                jq ".$key = $observed" "$tmp" > "$tmp.new" && mv "$tmp.new" "$tmp"
            done
            mv "$tmp" "$STATE_FILE"
            echo -e "  ${GREEN}✓${NC} state.json updated to match reality"
        else
            echo "  Run with --sync-state to overwrite state.json from observed reality"
        fi
    fi
fi
echo ""

echo "══════════════════════════════════════════════════════════════"
echo "                   Analysis Complete"
echo "══════════════════════════════════════════════════════════════"
echo ""
