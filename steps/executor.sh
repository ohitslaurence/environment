#!/bin/bash
# Executor (executor.sh): one MCP endpoint in front of every integration.
# Self-hosted Docker on this box, bound to the Tailscale IP only (Docker's
# published ports bypass UFW, so 0.0.0.0 would expose it on the public IP).
# Web UI + MCP: https://<host>.<tailnet>.ts.net  (Tailscale Serve -> container on the TS IP)
set -euo pipefail

command -v docker >/dev/null || { echo "docker required (run the docker step)"; exit 1; }
TS_IP="$(tailscale ip -4 2>/dev/null | head -1)"
[[ -n "$TS_IP" ]] || { echo "tailscale not up"; exit 1; }
# HTTPS via Tailscale Serve (Claude Code refuses OAuth over plain http off-localhost):
#   sudo tailscale set --operator=$USER && tailscale serve --bg --https=443 http://$TS_IP:4788
TS_FQDN="$(tailscale status --json 2>/dev/null | python3 -c "import json,sys;print(json.load(sys.stdin)['Self']['DNSName'].rstrip('.'))")"
BASE_URL="${EXECUTOR_WEB_BASE_URL:-https://${TS_FQDN}}"

ENV_FILE="$HOME/.config/executor/admin.env"
mkdir -p "$(dirname "$ENV_FILE")"
if [[ ! -f "$ENV_FILE" ]]; then
  PW="$(openssl rand -base64 24 | tr -d '/+=' | cut -c1-24)"
  cat > "$ENV_FILE" <<ENV
EXECUTOR_BOOTSTRAP_ADMIN_EMAIL=${EXECUTOR_ADMIN_EMAIL:-$(git config --global user.email)}
EXECUTOR_BOOTSTRAP_ADMIN_PASSWORD=$PW
EXECUTOR_BOOTSTRAP_ADMIN_NAME=Laurence
EXECUTOR_ORG_NAME=Spritz
EXECUTOR_ORG_SLUG=spritz
ENV
  chmod 600 "$ENV_FILE"
  echo "wrote $ENV_FILE (admin password lives there; chmod 600)"
fi

if docker ps -a --format '{{.Names}}' | grep -qx executor; then
  echo "container 'executor' exists; restarting"
  docker rm -f executor >/dev/null
fi
docker pull -q ghcr.io/rhyssullivan/executor-selfhost:latest
docker run -d \
  --name executor \
  --restart unless-stopped \
  -p "${TS_IP}:4788:4788" \
  -v executor-data:/data \
  --env-file "$ENV_FILE" \
  -e "EXECUTOR_WEB_BASE_URL=${BASE_URL}" \
  ghcr.io/rhyssullivan/executor-selfhost:latest >/dev/null

for i in $(seq 1 30); do
  if curl -fsS -m 2 "http://${TS_IP}:4788/" >/dev/null 2>&1; then
    echo "executor up: ${BASE_URL}  (MCP: ${BASE_URL}/mcp)"
    exit 0
  fi
  sleep 1
done
echo "executor did not answer on ${TS_IP}:4788; check: docker logs executor"
exit 1
