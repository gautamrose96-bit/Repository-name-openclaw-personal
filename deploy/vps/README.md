# Run OpenClaw as a 24/7 Telegram bot on a free VPS

This folder sets up OpenClaw to run **non-stop on its own** (no laptop or
Codespace required) as a Telegram bot, using Groq (primary) and Gemini
(fallback) cloud models.

> Why not GitHub Codespaces? Codespaces auto-suspend when you disconnect and
> have monthly free-hour limits, so they can never run a bot 24/7. Run the
> Gateway on an always-on host instead — that is what this folder is for.

## What you get

- `openclaw.json` — enables Telegram and sets the Groq/Gemini model routing.
- `env.example` — template for your secrets (bot token + API keys).
- `setup.sh` — installs OpenClaw and registers the Gateway as a systemd
  service that **restarts on crash and starts on boot**.

## Before you start

1. **Telegram bot token** — open Telegram, chat with **@BotFather**, run
   `/newbot`, and save the token.
2. **Groq API key** — https://console.groq.com/keys (free tier).
3. *(optional)* **Gemini API key** — https://aistudio.google.com/apikey (used as fallback).

## Oracle Cloud Always-Free walkthrough

Full provider guide: https://docs.openclaw.ai/install/oracle

1. **Create the instance** in the [Oracle Cloud Console](https://cloud.oracle.com/):
   Compute → Instances → Create Instance.
   - Image: **Ubuntu 24.04 (aarch64)**
   - Shape: **VM.Standard.A1.Flex** (Ampere ARM), 2 OCPU / 12 GB RAM
   - Add your SSH public key, then note the public IP.

2. **Connect and install basics:**

   ```bash
   ssh ubuntu@YOUR_PUBLIC_IP
   sudo apt update && sudo apt upgrade -y
   sudo apt install -y build-essential git curl
   ```

3. **Get this repo and add your secrets:**

   ```bash
   git clone https://github.com/gautamrose96-bit/Repository-name-openclaw-personal.git
   cd Repository-name-openclaw-personal

   mkdir -p ~/.openclaw && chmod 700 ~/.openclaw
   cp deploy/vps/env.example ~/.openclaw/.env
   chmod 600 ~/.openclaw/.env
   nano ~/.openclaw/.env   # paste TELEGRAM_BOT_TOKEN and GROQ_API_KEY
   ```

4. **Run the setup script:**

   ```bash
   bash deploy/vps/setup.sh
   ```

   It installs OpenClaw, applies `deploy/vps/openclaw.json`, and starts the
   Gateway as a 24/7 systemd service.

5. **Pair your Telegram account** (first-time access):

   ```bash
   # DM your bot first, then:
   openclaw pairing list telegram
   openclaw pairing approve telegram <CODE>
   ```

Your bot now answers on Telegram around the clock. It keeps running after you
log out and comes back automatically after a reboot.

## Managing the service

```bash
systemctl --user status  openclaw-gateway.service   # is it running?
journalctl --user -u openclaw-gateway.service -f     # live logs
openclaw gateway restart                             # restart
openclaw gateway stop                                # stop
```

## Changing the models

Edit `~/.openclaw/openclaw.json` (or re-run the script after editing
`deploy/vps/openclaw.json`), then `openclaw gateway restart`.
See https://docs.openclaw.ai/channels/telegram and
https://docs.openclaw.ai/gateway/configuration for all options.

## Locking it down (recommended)

Oracle's guide pairs this with Tailscale so only you can reach the box and the
Control UI. See the "Harden admin access" and "Lock down VCN security" steps in
https://docs.openclaw.ai/install/oracle
