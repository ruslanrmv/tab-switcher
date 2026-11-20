#!/bin/bash
set -euo pipefail

# Build an ad-hoc signed personal bundle without the upstream auto-updater.
# Reuse Sparkle and the icon from an installed Tab Switcher app bundle.
root="$(cd "$(dirname "$0")/.." && pwd)"
template="${TAB_SWITCHER_TEMPLATE:-/Applications/Tab Switcher Personal.app}"
output="${TAB_SWITCHER_OUTPUT:-$root/dist/Tab Switcher Personal.app}"
if [[ ! -d "$template/Contents/Frameworks/Sparkle.framework" ]]; then
    printf 'Set TAB_SWITCHER_TEMPLATE to an app bundle containing Sparkle.framework.\n' >&2
    exit 1
fi
if [[ -e "$output" ]]; then
    printf 'Output already exists: %s\nChoose a different TAB_SWITCHER_OUTPUT.\n' "$output" >&2
    exit 1
fi
mkdir -p "$(dirname "$output")"
ditto "$template" "$output"
source="$root/native-host/Sources/tab-switcher/main.swift"
binary="$output/Contents/MacOS/tab-switcher"
if [[ "${TAB_SWITCHER_UNIVERSAL:-0}" == 1 ]]; then
    for arch in arm64 x86_64; do
        swiftc -O -D PERSONAL_BUILD -target "$arch-apple-macos14.0" -F "$template/Contents/Frameworks" -framework Sparkle \
            -Xlinker -rpath -Xlinker '@executable_path/../Frameworks' "$source" -o "$binary.$arch"
    done
    lipo -create "$binary.arm64" "$binary.x86_64" -output "$binary"
    rm "$binary.arm64" "$binary.x86_64"
else
    swiftc -O -D PERSONAL_BUILD -F "$template/Contents/Frameworks" -framework Sparkle \
        -Xlinker -rpath -Xlinker '@executable_path/../Frameworks' "$source" -o "$binary"
fi
plist="$output/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier com.ruslanrmv.tabswitcher' "$plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleName Tab Switcher Personal' "$plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleDisplayName Tab Switcher Personal' "$plist"
/usr/libexec/PlistBuddy -c 'Delete :SUFeedURL' "$plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c 'Delete :SUPublicEDKey' "$plist" 2>/dev/null || true
codesign --force --deep --sign - "$output"
codesign --verify --deep --strict "$output"
printf 'Built %s\n' "$output"
