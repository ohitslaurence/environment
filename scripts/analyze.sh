#!/bin/bash
set -euo pipefail

echo "══════════════════════════════════════════════════════════════"
echo "                   Security Analysis Report"
echo "══════════════════════════════════════════════════════════════"
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

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

if sudo ufw status | grep -q "Status: active"; then
    check_pass "UFW is active"

    if sudo ufw status | grep -q "tailscale0"; then
        check_pass "Tailscale interface allowed"
    else
        check_warn "Tailscale interface not explicitly allowed"
    fi

    # Check if any ports are open to public
    if sudo ufw status | grep -qE "22.*ALLOW.*Anywhere|80.*ALLOW.*Anywhere|443.*ALLOW.*Anywhere"; then
        check_fail "Ports open to public internet (should only allow tailscale0)"
        sudo ufw status | grep "ALLOW.*Anywhere" | head -5
    else
        check_pass "No ports open to public internet"
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
EXPOSED=$(sudo ss -tlnp | grep -E "0\.0\.0\.0:\*|::" | grep -v "127\." || true)
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
sudo ss -tlnp | grep -E "LISTEN" | head -10
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
tailscale status &> /dev/null && ((SCORE++))

# UFW active
sudo ufw status | grep -q "Status: active" && ((SCORE++))

# OpenSSH disabled (service and socket)
! systemctl is-active --quiet sshd 2>/dev/null && ! systemctl is-active --quiet ssh 2>/dev/null && ! systemctl is-active --quiet ssh.socket 2>/dev/null && ((SCORE++))

# Auto updates
systemctl is-enabled --quiet unattended-upgrades 2>/dev/null && ((SCORE++))

# No public ports
! sudo ufw status | grep -qE "22.*ALLOW.*Anywhere" && ((SCORE++))

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
    ((RECOMMENDATIONS++))
fi

if ! sudo ufw status | grep -q "Status: active"; then
    echo "  • Enable firewall: sudo ufw enable"
    ((RECOMMENDATIONS++))
fi

if systemctl is-active --quiet sshd 2>/dev/null || systemctl is-active --quiet ssh 2>/dev/null || systemctl is-active --quiet ssh.socket 2>/dev/null; then
    echo "  • Disable OpenSSH: sudo systemctl disable --now ssh ssh.socket"
    ((RECOMMENDATIONS++))
fi

if [[ "$RECOMMENDATIONS" -eq 0 ]]; then
    echo "  None - your server is properly locked down!"
fi

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "                   Analysis Complete"
echo "══════════════════════════════════════════════════════════════"
echo ""
