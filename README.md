# LidAngle (macOS Menu Bar App)

A tiny menu bar app that displays your Mac’s current lid angle as text (e.g., `120°`).

- Uses the hidden lid angle HID sensor via `IOHIDManager` (Vendor 0x05AC, UsagePage 0x0020, Usage 0x008A), reading Feature Report ID 1.
- No UI beyond the status item text.
- Right‑click (or control‑click) the status item to Quit.

## Build & Run

- Open the Xcode project and run the `LidAngle` target.
- Ensure `IOKit.framework` is linked (Target → Build Phases → Link Binary With Libraries).
- App Sandbox is disabled in `LidAngle.entitlements` to allow HID access.

## Behavior

- Updates the angle about twice per second.
- Shows `—°` if the sensor isn’t available or can’t be read.
- No left‑click action; right‑click shows a one‑item menu (Quit).

## Requirements & Notes

- Hardware: Newer Mac laptops/desktops with a lid angle sensor. Some M1 models reportedly don’t expose the sensor.
- API: Relies on undocumented HID usage; not App Store–safe and may break on OS updates.
- Matching: Falls back from strict (VID+PID+Usage) to relaxed (VID+Usage) to usage‑only.

## Troubleshooting

- If it always shows `—°`, check your hardware, confirm Sandbox is off, and verify `IOKit.framework` is linked. Use the Xcode console to see any read errors.
