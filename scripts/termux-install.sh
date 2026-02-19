#!/data/data/com.termux/files/usr/bin/bash
# ZeroClaw Termux installer — downloads the latest (or pinned) Android binary
# Usage:
#   curl -fsSL <raw-url>/scripts/termux-install.sh | bash
#   ZEROCLAW_VERSION=v0.1.0 bash termux-install.sh
set -euo pipefail

ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ]; then
    echo "Error: Only aarch64 Android is supported (detected: $ARCH)"
    exit 1
fi

VERSION="${ZEROCLAW_VERSION:-latest}"
REPO="zeroclaw-labs/zeroclaw"

if [ "$VERSION" = "latest" ]; then
    VERSION=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name"' | cut -d'"' -f4)
fi

ASSET="zeroclaw-aarch64-linux-android.tar.gz"
URL="https://github.com/$REPO/releases/download/$VERSION/$ASSET"

echo "Installing ZeroClaw $VERSION for Android (aarch64)..."
curl -fsSL "$URL" -o "/tmp/$ASSET"
tar xzf "/tmp/$ASSET" -C "$PREFIX/bin/"
chmod +x "$PREFIX/bin/zeroclaw"
rm "/tmp/$ASSET"

echo "ZeroClaw $VERSION installed to $PREFIX/bin/zeroclaw"
zeroclaw --version
