# Android Phone Deployment Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Cross-compile ZeroClaw for Android, transfer to Moto 5G, and get a working agent runtime in Termux.

**Architecture:** Build on macOS using `cross` (Docker-based cross-compiler) targeting `aarch64-linux-android`. Transfer binary via USB/ADB or network. Configure and validate in Termux.

**Tech Stack:** cross (Rust cross-compiler), Docker, adb (Android Debug Bridge), Termux

---

## Prerequisites

- macOS dev machine with Docker running (confirmed available)
- Moto 5G phone with Termux installed from F-Droid (**not** Play Store)
- USB cable or shared Wi-Fi network between Mac and phone
- An API key for at least one provider (OpenRouter, OpenAI, etc.)

---

### Task 1: Install Cross-Compilation Tooling

**Step 1: Install `cross`**

```bash
cargo install cross --locked
```

Expected: Compiles and installs `cross` binary. Takes 1-3 minutes.

**Step 2: Verify cross is available**

```bash
cross --version
```

Expected: Prints version like `cross 0.2.x`

**Step 3: Add Android target to rustup**

```bash
rustup target add aarch64-linux-android
```

Expected: `info: component 'rust-std' for target 'aarch64-linux-android' is up to date`

**Step 4: Verify Docker is running**

```bash
docker info --format '{{.ServerVersion}}'
```

Expected: Prints a version number (e.g. `28.5.2`). If this fails, start Docker Desktop.

---

### Task 2: Cross-Compile the Android Binary

**Step 1: Build with cross**

From the project root (`/Users/jxmullins-devMini/dev/projects/zeroclawAR`):

```bash
cross build --release --target aarch64-linux-android --no-default-features --features channel-matrix
```

Expected: First run pulls the Docker image (~1-2 GB download), then compiles. Takes 5-15 minutes depending on network and CPU. Should end with `Finished release...`.

**Step 2: Verify binary was produced**

```bash
file target/aarch64-linux-android/release/zeroclaw
```

Expected: `ELF 64-bit LSB pie executable, ARM aarch64, version 1 (SYSV), dynamically linked...`

**Step 3: Check binary size**

```bash
ls -lh target/aarch64-linux-android/release/zeroclaw
```

Expected: Under 5MB (likely ~3-4MB). If over 5MB, that's a warning but not a blocker.

---

### Task 3: Transfer Binary to Phone

Choose **one** of these methods (A, B, or C):

#### Method A: USB + ADB (Recommended)

**Step 1: Install adb**

```bash
brew install android-platform-tools
```

Expected: Installs `adb` command.

**Step 2: Enable USB debugging on the Moto 5G**

On the phone:
1. Go to **Settings > About phone**
2. Tap **Build number** 7 times to enable Developer options
3. Go to **Settings > System > Developer options**
4. Enable **USB debugging**
5. Connect phone to Mac via USB cable
6. Accept the "Allow USB debugging?" prompt on the phone

**Step 3: Verify adb connection**

```bash
adb devices
```

Expected: Shows your device like `XXXXXXXXX    device`. If it says `unauthorized`, re-check the prompt on the phone.

**Step 4: Push binary to phone**

```bash
adb push target/aarch64-linux-android/release/zeroclaw /data/local/tmp/zeroclaw
```

Expected: `1 file pushed. X.X MB/s (XXXXXX bytes in X.XXXs)`

**Step 5: Copy into Termux from the phone**

Open Termux on the phone and run:

```bash
cp /data/local/tmp/zeroclaw ~/zeroclaw
chmod +x ~/zeroclaw
mv ~/zeroclaw $PREFIX/bin/zeroclaw
```

#### Method B: Network Transfer (No USB)

**Step 1: Find your Mac's IP**

```bash
ipconfig getifaddr en0
```

Expected: Something like `192.168.1.XXX`

**Step 2: Serve the binary over HTTP**

```bash
cd target/aarch64-linux-android/release && python3 -m http.server 8080
```

Leave this running.

**Step 3: Download in Termux on the phone**

Make sure the phone is on the same Wi-Fi network, then in Termux:

```bash
curl -fsSL http://<MAC_IP>:8080/zeroclaw -o $PREFIX/bin/zeroclaw
chmod +x $PREFIX/bin/zeroclaw
```

Replace `<MAC_IP>` with your Mac's IP from Step 1.

**Step 4: Stop the HTTP server on Mac**

Press Ctrl+C in the terminal running `python3 -m http.server`.

#### Method C: Termux SSH (Pull from Mac)

**Step 1: Install OpenSSH in Termux**

In Termux on the phone:

```bash
pkg install openssh
```

**Step 2: Copy binary via scp from Mac**

On your Mac:

```bash
scp -P 8022 target/aarch64-linux-android/release/zeroclaw <PHONE_IP>:$PREFIX/bin/zeroclaw
```

(Requires Termux sshd running — `sshd` in Termux to start it.)

---

### Task 4: Verify Binary Works in Termux

All remaining steps are run **in Termux on the phone**.

**Step 1: Verify binary runs**

```bash
zeroclaw --version
```

Expected: Prints version like `zeroclaw 0.1.0`

**Step 2: Run doctor**

```bash
zeroclaw doctor
```

Expected: Shows system info, reports missing config (expected at this point).

**Step 3: Export config schema**

```bash
zeroclaw config export-schema
```

Expected: Dumps JSON schema to stdout. Confirms the binary's config system works.

---

### Task 5: Configure ZeroClaw

**Step 1: Run interactive onboarding**

```bash
zeroclaw onboard --interactive
```

Follow the prompts to set provider and API key.

OR manually create config:

**Step 2 (alternative): Create config manually**

```bash
mkdir -p ~/.zeroclaw
cat > ~/.zeroclaw/config.toml << 'CONF'
[provider]
name = "openrouter"
api_key = "sk-or-v1-YOUR_KEY_HERE"
model = "anthropic/claude-sonnet-4"

[agent]
system_prompt = "You are ZeroClaw, a helpful AI assistant running on Android."
CONF
```

Replace `sk-or-v1-YOUR_KEY_HERE` with your actual API key.

**Step 3: Verify config loads**

```bash
zeroclaw doctor
```

Expected: Should now show the configured provider and report healthy status.

---

### Task 6: Smoke Test — CLI Chat

**Step 1: Start a chat session**

```bash
zeroclaw chat
```

**Step 2: Send a test message**

Type: `Hello, what device am I running you on?`

Expected: The agent responds coherently. This confirms provider connectivity, config loading, and the agent loop all work.

**Step 3: Exit chat**

Press Ctrl+C or type `exit`.

---

### Task 7: Smoke Test — Telegram Channel

Skip this task if you don't want Telegram integration.

**Step 1: Add Telegram config**

Edit `~/.zeroclaw/config.toml` and add:

```toml
[channel.telegram]
enabled = true
token = "YOUR_BOT_TOKEN"
allowed_users = [YOUR_TELEGRAM_USER_ID]
```

Get a bot token from [@BotFather](https://t.me/BotFather) on Telegram.
Get your user ID from [@userinfobot](https://t.me/userinfobot).

**Step 2: Start listening**

```bash
zeroclaw listen
```

Expected: Logs show "Telegram channel connected" or similar.

**Step 3: Send a message to the bot**

Open Telegram on the phone (or another device), message your bot.

Expected: Bot responds. This confirms the full channel pipeline works on Android.

**Step 4: Stop listener**

Press Ctrl+C.

---

### Task 8: Smoke Test — Gateway Server

**Step 1: Start the gateway**

```bash
zeroclaw gateway --bind 127.0.0.1:3000
```

**Step 2: Test from another Termux tab**

Swipe from the left edge in Termux to open a new session, then:

```bash
curl -s http://127.0.0.1:3000/health
```

Expected: Returns a health response (JSON or 200 OK).

**Step 3: Stop gateway**

Press Ctrl+C in the gateway tab.

---

### Task 9: Smoke Test — Memory Persistence

**Step 1: Start a chat and create a memory**

```bash
zeroclaw chat
```

Type: `Remember that my favorite color is blue.`

Wait for response, then exit (Ctrl+C).

**Step 2: Start a new chat and recall**

```bash
zeroclaw chat
```

Type: `What is my favorite color?`

Expected: Agent recalls "blue" from SQLite memory. This confirms the SQLite backend works on Android.

**Step 3: Exit**

Ctrl+C.

---

### Task 10: Set Up Auto-Start (Optional)

**Step 1: Install Termux:Boot from F-Droid**

```
https://f-droid.org/en/packages/com.termux.boot/
```

Open the app once after installing to register with the system.

**Step 2: Install the boot script**

In Termux:

```bash
zeroclaw service install
```

Expected: Prints `Installed Termux:Boot script: /data/data/com.termux/files/home/.termux/boot/zeroclaw`

**Step 3: Verify script was created**

```bash
cat ~/.termux/boot/zeroclaw
```

Expected:
```
#!/data/data/com.termux/files/usr/bin/sh
termux-wake-lock
/data/data/com.termux/files/usr/bin/zeroclaw daemon &
```

**Step 4: Disable battery optimization for Termux**

On the phone: **Settings > Apps > Termux > Battery > Unrestricted**

This prevents Android from killing ZeroClaw in the background.

**Step 5: Test reboot**

Reboot the phone. After boot, open Termux and check:

```bash
zeroclaw service status
```

Expected: Shows "running".

---

### Task 11: Cleanup and Final Validation

**Step 1: Verify everything works end-to-end**

Checklist:
- [ ] `zeroclaw --version` prints version
- [ ] `zeroclaw doctor` reports healthy
- [ ] `zeroclaw chat` can send/receive messages
- [ ] Telegram channel works (if configured)
- [ ] Gateway responds to `/health` (if tested)
- [ ] Memory persists across sessions
- [ ] Auto-start works after reboot (if configured)

**Step 2: Note the binary size**

```bash
ls -lh $(which zeroclaw)
```

Record this for comparison with future builds.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `cross build` fails with Docker error | Make sure Docker Desktop is running: `docker info` |
| `cross build` fails with linker error | Ensure `--no-default-features --features channel-matrix` is used (excludes nusb/tokio-serial) |
| `adb devices` shows empty | Enable USB debugging on phone, reconnect cable, accept prompt |
| `zeroclaw` crashes with SIGILL | Binary was built for wrong arch — verify `file zeroclaw` shows `ARM aarch64` |
| Telegram bot doesn't respond | Check `allowed_users` matches your Telegram ID, check token is correct |
| SQLite errors | Check disk space: `df -h` in Termux |
| Battery kills ZeroClaw | Disable battery optimization for Termux in Android settings |
| `termux-open-url` not found | `pkg install termux-api` and install Termux:API app from F-Droid |
