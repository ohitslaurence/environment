#!/bin/bash
# Nightly `dev prune --all` via a systemd user timer (Linux only).
set -euo pipefail
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/dev-prune.service <<UNIT
[Unit]
Description=dev prune: reconcile worktrees, branches, herdr workspaces
[Service]
Type=oneshot
Environment=PATH=%h/.local/bin:%h/.local/share/mise/shims:/usr/local/bin:/usr/bin:/bin
ExecStart=%h/.local/bin/dev prune --all
UNIT
cat > ~/.config/systemd/user/dev-prune.timer <<UNIT
[Unit]
Description=Nightly dev prune
[Timer]
OnCalendar=*-*-* 03:30:00
Persistent=true
[Install]
WantedBy=timers.target
UNIT
systemctl --user daemon-reload
systemctl --user enable --now dev-prune.timer
systemctl --user list-timers dev-prune.timer --no-pager
