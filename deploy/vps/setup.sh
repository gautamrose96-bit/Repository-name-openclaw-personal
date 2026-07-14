#!/usr/bin/env bash
# Set up OpenClaw as an always-on Telegram bot on a fresh Linux VPS
# (tested target: Oracle Cloud Always-Free, Ubuntu 24.04 ARM64).
#
# It installs OpenClaw, applies the Telegram + model config, installs the
# Gateway as a systemd user service that restarts on crash and survives reboot,
# and starts it. Safe to re-run.
#
# Usage (on the server, as the "ubuntu" user):
#   bash deploy/vps/setup.sh
#
# Before running, put your secrets in ~/.openclaw/.env (see deploy/vps/env.example).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCLAW_HOME_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"

log() { printf '\n\033[1;36m==> %s\033[0m\n' "$1"; }

log "Ensuring OpenClaw config directory: $OPENCLAW_HOME_DIR"
mkdir -p "$OPENCLAW_HOME_DIR"
chmod 700 "$OPENCLAW_HOME_DIR"

log "Applying Telegram + model config -> $OPENCLAW_HOME_DIR/openclaw.json"
if [ -f "$OPENCLAW_HOME_DIR/openclaw.json" ]; then
  cp "$OPENCLAW_HOME_DIR/openclaw.json" "$OPENCLAW_HOME_DIR/openclaw.json.bak.$(date +%s)"
  echo "Existing config backed up."
fi
cp "$SCRIPT_DIR/openclaw.json" "$OPENCLAW_HOME_DIR/openclaw.json"

if [ ! -f "$OPENCLAW_HOME_DIR/.env" ]; then
  cp "$SCRIPT_DIR/env.example" "$OPENCLAW_HOME_DIR/.env"
  chmod 600 "$OPENCLAW_HOME_DIR/.env"
  echo
  echo "!! Created $OPENCLAW_HOME_DIR/.env from the template."
  echo "!! Edit it now and add TELEGRAM_BOT_TOKEN and GROQ_API_KEY, then re-run this script."
  exit 1
fi

if ! grep -q '^TELEGRAM_BOT_TOKEN=.\+' "$OPENCLAW_HOME_DIR/.env"; then
  echo "!! TELEGRAM_BOT_TOKEN is empty in $OPENCLAW_HOME_DIR/.env. Add it and re-run."
  exit 1
fi
if ! grep -q '^GROQ_API_KEY=.\+' "$OPENCLAW_HOME_DIR/.env"; then
  echo "!! GROQ_API_KEY is empty in $OPENCLAW_HOME_DIR/.env. Add it and re-run."
  exit 1
fi

if ! command -v openclaw >/dev/null 2>&1; then
  log "Installing OpenClaw (official installer)"
  curl -fsSL https://openclaw.ai/install.sh | bash
  # shellcheck disable=SC1090
  [ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc" || true
  export PATH="$HOME/.local/bin:$PATH"
fi

command -v openclaw >/dev/null 2>&1 || {
  echo "!! openclaw not on PATH after install. Open a new shell (or 'source ~/.bashrc') and re-run."
  exit 1
}

log "OpenClaw version"
openclaw --version || true

log "Keeping user services running after logout (linger)"
sudo loginctl enable-linger "$USER" 2>/dev/null || loginctl enable-linger "$USER" 2>/dev/null || \
  echo "(!) Could not enable linger automatically; run: sudo loginctl enable-linger $USER"

log "Installing the Gateway as a systemd user service"
openclaw gateway install --force

log "Starting the Gateway (24/7, auto-restart)"
openclaw gateway start

log "Status"
systemctl --user status openclaw-gateway.service --no-pager || true

cat <<'DONE'

Done. Your Telegram bot is now running 24/7 on this server.

Next:
  1. DM your bot on Telegram, then approve the pairing:
       openclaw pairing list telegram
       openclaw pairing approve telegram <CODE>
  2. Tail logs to watch it work:
       journalctl --user -u openclaw-gateway.service -f
  3. It restarts on crash and starts automatically on reboot.
DONE
