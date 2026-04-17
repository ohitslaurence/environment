#!/bin/bash
set -euo pipefail

echo "Installing Docker..."

if command -v docker &> /dev/null; then
    echo "Docker already installed: $(docker --version)"
else
    # Install Docker using official script
    curl -fsSL https://get.docker.com | sh

    # Add current user to docker group (no sudo needed for docker commands)
    sudo usermod -aG docker "$USER"

    echo ""
    echo "Docker installed: $(docker --version)"
fi

# Install Docker Compose plugin if not present
if ! docker compose version &> /dev/null; then
    echo "Installing Docker Compose plugin..."
    sudo apt install -y docker-compose-plugin
fi

echo ""
echo "Docker Compose: $(docker compose version)"

# Enable and start Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Default-bind published container ports to 127.0.0.1 instead of 0.0.0.0.
# Docker's iptables rules normally bypass UFW, so a careless `-p 6379:6379`
# would expose the container to the public internet. With this default,
# `-p 6379:6379` becomes `-p 127.0.0.1:6379:6379`. Containers that genuinely
# need public exposure can opt in with `-p 0.0.0.0:port:port` (and a UFW rule).
DAEMON_JSON=/etc/docker/daemon.json
NEED_RESTART=0

if [[ ! -f "$DAEMON_JSON" ]]; then
    echo ""
    echo "Setting Docker default publish IP to 127.0.0.1 (containers default to localhost)..."
    sudo mkdir -p /etc/docker
    echo '{"ip": "127.0.0.1"}' | sudo tee "$DAEMON_JSON" > /dev/null
    NEED_RESTART=1
elif ! jq -e '.ip == "127.0.0.1"' "$DAEMON_JSON" > /dev/null 2>&1; then
    echo ""
    echo "Updating Docker daemon.json: setting ip = 127.0.0.1..."
    tmp=$(mktemp)
    jq '. + {ip: "127.0.0.1"}' "$DAEMON_JSON" > "$tmp"
    sudo install -m 0644 -o root -g root "$tmp" "$DAEMON_JSON"
    rm -f "$tmp"
    NEED_RESTART=1
else
    echo ""
    echo "Docker daemon.json already binds to 127.0.0.1"
fi

if [[ "$NEED_RESTART" == 1 ]]; then
    echo "Restarting Docker to apply daemon config..."
    sudo systemctl restart docker
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Docker installed!                                          ║"
echo "║                                                              ║"
echo "║  NOTE: Log out and back in for group changes to take effect ║"
echo "║  Then you can run docker without sudo                       ║"
echo "║                                                              ║"
echo "║  Containers now default to 127.0.0.1 binding. To expose:    ║"
echo "║    - Tailnet only:  -p 100.x.y.z:HOST:CONT                  ║"
echo "║    - Public:        -p 0.0.0.0:HOST:CONT  + UFW rule        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
