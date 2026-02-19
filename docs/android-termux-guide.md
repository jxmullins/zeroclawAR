# Android / Termux Deployment Guide

Run ZeroClaw on Android phones via [Termux](https://termux.dev).

## Prerequisites

| Requirement | Notes |
|---|---|
| Android 9+ (aarch64) | Tested on Moto G 5G, Pixel, Samsung Galaxy |
| Termux (F-Droid) | **Do not** use the Play Store version — it is outdated |
| Termux:API (optional) | For `termux-open-url`, `termux-screencap` |
| Termux:Boot (optional) | For auto-start on device boot |

Install Termux from F-Droid:

```
https://f-droid.org/en/packages/com.termux/
```

## Installation

### One-liner

```bash
curl -fsSL https://raw.githubusercontent.com/zeroclaw-labs/zeroclaw/main/scripts/termux-install.sh | bash
```

### Pin a specific version

```bash
ZEROCLAW_VERSION=v0.1.0 bash <(curl -fsSL https://raw.githubusercontent.com/zeroclaw-labs/zeroclaw/main/scripts/termux-install.sh)
```

### Manual download

```bash
VERSION="v0.1.0"  # replace with desired tag
curl -fsSL "https://github.com/zeroclaw-labs/zeroclaw/releases/download/$VERSION/zeroclaw-aarch64-linux-android.tar.gz" -o /tmp/zeroclaw.tar.gz
tar xzf /tmp/zeroclaw.tar.gz -C "$PREFIX/bin/"
chmod +x "$PREFIX/bin/zeroclaw"
zeroclaw --version
```

## Configuration

Create or edit `~/.zeroclaw/config.toml`:

```bash
mkdir -p ~/.zeroclaw
zeroclaw onboard --interactive
```

Or manually:

```toml
[provider]
name = "openrouter"
api_key = "sk-or-..."
model = "anthropic/claude-sonnet-4"

[channel.telegram]
enabled = true
token = "123456:ABC-..."
allowed_users = [12345678]
```

## Running

### Interactive CLI

```bash
zeroclaw chat
```

### Channels (Telegram, Discord, Slack, etc.)

```bash
zeroclaw listen
```

### Gateway server

```bash
zeroclaw gateway --bind 0.0.0.0:3000
```

### Validate setup

```bash
zeroclaw --version
zeroclaw doctor
zeroclaw config export-schema
```

## Auto-Start via Termux:Boot

Install the Termux:Boot app from F-Droid, then:

```bash
zeroclaw service install
```

This creates `~/.termux/boot/zeroclaw` which runs `zeroclaw daemon` on device boot with a wake lock.

Manage the service:

```bash
zeroclaw service start
zeroclaw service status
zeroclaw service stop
zeroclaw service uninstall
```

## Troubleshooting

### Wake lock / battery optimization

Android aggressively kills background processes. To keep ZeroClaw running:

1. Install Termux:API: `pkg install termux-api`
2. The boot script uses `termux-wake-lock` automatically
3. Exclude Termux from battery optimization in Android Settings > Apps > Termux > Battery > Unrestricted

### Storage permissions

If tools need access to shared storage:

```bash
termux-setup-storage
```

This creates `~/storage/` symlinks to `/sdcard/`, `~/storage/dcim/`, etc.

### Browser open not working

Install Termux:API for `termux-open-url`:

```bash
pkg install termux-api
```

The browser_open tool tries `termux-open-url` first, then falls back to Android's `am start`.

### Screenshot not working

Install Termux:API:

```bash
pkg install termux-api
```

Screenshot requires `termux-screencap` from the termux-api package.

### Binary not found after install

Ensure `$PREFIX/bin` is in your PATH (it should be by default in Termux):

```bash
echo $PATH
which zeroclaw
```

### Compilation from source

If you prefer building from source inside Termux:

```bash
pkg install rust
cargo install --git https://github.com/zeroclaw-labs/zeroclaw --no-default-features --features channel-matrix
```

Note: Building from source on-device can take 10-30 minutes depending on hardware.

## Feature Differences from Desktop

| Feature | Android/Termux | Desktop |
|---|---|---|
| All channels | Yes | Yes |
| Gateway server | Yes | Yes |
| Memory (SQLite) | Yes | Yes |
| CLI tools | Yes | Yes |
| Hardware peripherals | No (excluded) | Yes (with `--features hardware`) |
| Browser automation | No | Yes (with `--features browser-native`) |
| OS sandbox (Landlock/Firejail) | No (uses Android sandbox) | Yes |
| Service management | Termux:Boot | systemd/launchd/schtasks |
