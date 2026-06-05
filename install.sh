#!/bin/bash
# vpnctl installer — curl -fsSL .../install.sh | bash
# Ensures OpenVPN (Homebrew) and installs the `vpnctl` command. No secrets here;
# you supply your VPN profile yourself via `vpnctl install` afterwards.
set -euo pipefail

REPO_RAW="${VPNCTL_RAW:-https://raw.githubusercontent.com/Anakin-Inc/vpnctl/main}"
DEST=/usr/local/bin/vpnctl

# 1. ensure Homebrew (auto-install if missing — runs as you; sudo prompts on your terminal)
if ! command -v brew >/dev/null 2>&1 && ! ls /opt/homebrew/bin/brew /usr/local/bin/brew >/dev/null 2>&1; then
  echo "==> Homebrew not found — installing (non-interactive)"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
# put brew on PATH for the rest of this script
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null || true)"

# 2. ensure openvpn (Apple Silicon /opt/homebrew or Intel /usr/local)
if ! ls /opt/homebrew/sbin/openvpn /usr/local/sbin/openvpn >/dev/null 2>&1 \
   && ! command -v openvpn >/dev/null 2>&1; then
  echo "==> installing openvpn"; brew install openvpn
fi

# 3. install vpnctl (sudo prompts on your terminal even via curl | bash)
echo "==> installing vpnctl -> $DEST"
sudo mkdir -p "$(dirname "$DEST")"
curl -fsSL "$REPO_RAW/vpnctl" | sudo tee "$DEST" >/dev/null
sudo chmod 755 "$DEST"

# 4. keep it current automatically (daily + at boot)
sudo "$DEST" autoupdate on >/dev/null && echo "==> autoupdate enabled (daily)"

echo "✅ vpnctl installed. Next:"
echo "   vpnctl install <profile.ovpn | profile.zip | https://host/key/XXXX.zip> [name]"
echo "   vpnctl list"
