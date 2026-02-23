# macOS-LidAngleSleep

A small **macOS menu bar app** that puts your Mac to sleep when the lid is at or below a **custom angle threshold**, and **keeps it asleep** if it wakes accidentally—handy for MacBooks with uncalibrated or faulty lid sensors, or phantom keypress wake-ups.

## What it does

- **Shows the current lid angle** in the menu bar (e.g. `120°`), using the built-in HID lid angle sensor.
- **Sleep at your chosen angle:** When “Put Mac to sleep when lid is at or below threshold” is on, the app puts the Mac to sleep whenever the reported angle is at or below the value you set (5°–200°).
- **Keeps it asleep:** If the Mac wakes (e.g. accidental keypress, bad sensor) while the lid is still “closed” (angle below your threshold), the app triggers sleep again on the next poll. So it repeatedly re-sleeps until you open the lid above the threshold.
- **Launch at login** (optional), **no Dock icon** (menu bar only).
- **Battery-friendly polling:** Normal interval 3 s; faster (0.75 s) only when the angle is near your threshold and sleep-by-angle is enabled.

## Requirements

- **macOS 13+** (Ventura or later) for Launch at login.
- **Mac with a lid angle sensor** (many Intel and Apple Silicon laptops have it; some M1 models reportedly don’t expose it).
- **Xcode** (or Xcode Command Line Tools + full Xcode selected) to build.

## Build & install

### Option A: Script (recommended)

1. Use Xcode as the active developer tools (one-time, needs your password):
   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```
2. If you haven’t already, run first-launch setup (one-time):
   ```bash
   xcodebuild -runFirstLaunch
   ```
3. Build and install:
   ```bash
   ./build-and-install.sh
   ```
   The app is installed to `/Applications/LidAngle.app`. Open it from Applications or run:
   ```bash
   open /Applications/LidAngle.app
   ```

### Option B: Xcode

1. Open `LidAngle.xcodeproj` in Xcode.
2. Select the **LidAngle** scheme and run (⌘R) or build (⌘B).
3. To install: in the Project navigator, under **Products**, right‑click **LidAngle.app** → **Show in Finder**, then drag the app into **Applications**.

The build script disables code signing so you can build without a Mac Development certificate. If macOS blocks the app when you first open it, use **Right‑click → Open** or **System Settings → Privacy & Security → Open Anyway**.

## Usage

- **Menu bar:** The current angle is shown in the menu bar (e.g. `120°` or `—°` if the sensor isn’t available). Click it for the menu.
- **Settings…** (or ⌘,): Opens **LidAngle → Settings**, where you can:
  - **Launch at login** — Start the app when you log in.
  - **Put Mac to sleep when lid is at or below threshold** — Enable sleep-by-angle.
  - **Threshold (degrees)** — Set the angle (5°–200°). When the reported angle is ≤ this value, the Mac is put to sleep (and re-sleeps if it wakes while still below).
- **Quit** (or ⌘Q): Quit the app.

The app has no Dock icon; it lives only in the menu bar.

## How it works

- Reads the lid angle from the **HID lid angle sensor** (IOHIDManager, Apple vendor/usage). This is an undocumented API and may change in future macOS versions.
- When sleep-by-angle is enabled and the angle is at or below your threshold, the app runs `pmset sleepnow` to put the Mac to sleep. It does this on every poll while the angle stays at or below the threshold, so accidental wake-ups are corrected on the next poll.
- App Sandbox is **disabled** in the project so the app can access the HID device and run `pmset`.

## Troubleshooting

- **Don’t see the app in the menu bar?** There’s no Dock icon. If the menu bar is crowded or you have a notched Mac, check the **»** (overflow) on the **right side** of the menu bar; the angle may be there. You can drag it out to keep it visible.
- **Always shows `—°`?** The lid angle sensor may not be present or not exposed on your Mac. Check that App Sandbox is off and IOKit is linked. Run from Xcode to see any console errors.
- **Sleep doesn’t happen?** Confirm the threshold is enabled and the reported angle (when you close the lid) is at or below your set value. You may need to raise or lower the threshold to match your hardware.

## Acknowledgments

- Features added to and built on top of [LidAngle](https://github.com/deepakness/LidAngle) by DeepakNess. Credit for writing app and API usage/setup.
- The lid angle HID approach is based on [LidAngleSensor](https://github.com/samhenrigold/LidAngleSensor) by Sam Gold. Credit to that project for discovering and demonstrating the hidden lid angle API.
