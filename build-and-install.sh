#!/bin/bash
# Build LidAngle and install to /Applications

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Ensure we're using Xcode (not just Command Line Tools)
if ! xcodebuild -version &>/dev/null; then
    echo "Error: xcodebuild not available or Xcode not selected."
    echo "Run this in Terminal (you'll be prompted for your password):"
    echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    exit 1
fi

echo "Building LidAngle (Release)..."
# Disable code signing so we can build without a Mac Development certificate
if ! xcodebuild -project LidAngle.xcodeproj -target LidAngle -configuration Release build \
    SYMROOT="$SCRIPT_DIR/build" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO; then
    echo ""
    echo "If the error above mentions CoreSimulator or 'runFirstLaunch', run this once then try again:"
    echo "  xcodebuild -runFirstLaunch"
    echo ""
    exit 1
fi

APP_PATH="$SCRIPT_DIR/build/Release/LidAngle.app"
if [[ ! -d "$APP_PATH" ]]; then
    echo "Error: Build failed or app not found at $APP_PATH"
    exit 1
fi

echo "Installing to /Applications/LidAngle.app..."
if [[ -d /Applications/LidAngle.app ]]; then
    rm -rf /Applications/LidAngle.app
fi
cp -R "$APP_PATH" /Applications/

echo "Done. LidAngle is installed at /Applications/LidAngle.app"
echo "Open it from Applications or run: open /Applications/LidAngle.app"
