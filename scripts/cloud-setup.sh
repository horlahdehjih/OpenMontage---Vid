#!/usr/bin/env bash
# Setup script for Claude Code on the web (cloud environments).
# Paste `bash scripts/cloud-setup.sh` into the environment's setup script box.
#
# Cloud sandboxes are throwaway Linux VMs, so this installs into the system
# Python instead of a .venv — that way plain `python` works for the agent
# without needing an activated environment.
set -uo pipefail
cd "$(dirname "$0")/.."

SUDO=""
if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then SUDO="sudo"; fi

echo "==> FFmpeg"
if ! command -v ffmpeg >/dev/null 2>&1; then
  $SUDO apt-get update -qq && $SUDO apt-get install -y -qq ffmpeg \
    || echo "  [warn] could not install ffmpeg"
fi
ffmpeg -version 2>/dev/null | head -1

PY="$(command -v python3 || command -v python)"
echo "==> Python: $($PY --version)"
pip_install() {
  # Debian/Ubuntu system Pythons refuse global installs (PEP 668) without this flag.
  $PY -m pip install -q "$@" 2>/dev/null || $PY -m pip install -q --break-system-packages "$@"
}

echo "==> Python dependencies"
pip_install -r requirements.txt

echo "==> Remotion composer"
(cd remotion-composer && npm install --no-audit --no-fund)

echo "==> Piper TTS (free offline narration)"
pip_install piper-tts || echo "  [skip] piper-tts failed — cloud TTS providers will be used instead"

echo "==> HyperFrames cache-warm"
npx --yes hyperframes --version >/dev/null 2>&1 || echo "  [skip] HyperFrames will fetch on first render"

# API keys belong in the cloud environment's variables, not a committed .env.
[ -f .env ] || cp .env.example .env

echo "==> Cloud setup done."
