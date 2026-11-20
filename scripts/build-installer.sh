#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
out="${TAB_SWITCHER_PACKAGE_OUTPUT:-$root/dist/Tab-Switcher-Personal-macOS.zip}"
[ ! -e "$out" ] || { echo "Output already exists: $out" >&2; exit 1; }
stage="$(mktemp -d "${TMPDIR:-/tmp}/tabswitcher-package.XXXXXXXX")"
trap 'rm -rf "$stage"' EXIT
bundle="$stage/Tab Switcher Personal"
mkdir -p "$bundle/Extension" "$(dirname "$out")"
TAB_SWITCHER_UNIVERSAL=1 TAB_SWITCHER_OUTPUT="$bundle/Tab Switcher Personal.app" "$root/scripts/build-personal.sh"
for f in manifest.json mainsw.js popup.html popup.js tab-renaming.js rename-tab.html rename-tab.js icon16.png icon32.png icon48.png icon128.png; do cp "$root/$f" "$bundle/Extension/$f"; done
cp -R "$root/_locales" "$bundle/Extension/"
/usr/bin/plutil -insert key -string "$(cat "$root/packaging/extension-public-key.txt")" "$bundle/Extension/manifest.json"
/usr/bin/plutil -replace name -string 'Tab Switcher Personal' "$bundle/Extension/manifest.json"
python3 - "$bundle/Extension/mainsw.js" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
text = p.read_text()
welcome = '\tif (details.reason === "install") {\n\t\tchrome.tabs.create({ url: SETUP_PAGE_URL });\n\t}'
updates = 'checkForUpdates();\nsetInterval(checkForUpdates, VERSION_CHECK_INTERVAL);'
if text.count(welcome) != 1 or text.count(updates) != 1:
    raise SystemExit('Upstream extension changed; review personal packaging adjustments')
text = text.replace(welcome, '\t// Personal installation is configured locally.')
text = text.replace(updates, '// Personal builds are updated as a complete package.')
p.write_text(text)
PY
osacompile -o "$bundle/Установить Tab Switcher.app" "$root/packaging/installer.applescript"
payload="$bundle/Установить Tab Switcher.app/Contents/Resources/Package"
mkdir -p "$payload"
mv "$bundle/Tab Switcher Personal.app" "$payload/"
mv "$bundle/Extension" "$payload/"
cp "$root/packaging/install.sh" "$payload/install.sh"
helper="$payload/Chrome Setup.app/Contents"
mkdir -p "$helper/MacOS"
for arch in arm64 x86_64; do
    swiftc -O -target "$arch-apple-macos14.0" "$root/packaging/ChromeSetup.swift" -o "$helper/MacOS/ChromeSetup.$arch"
done
lipo -create "$helper/MacOS/ChromeSetup.arm64" "$helper/MacOS/ChromeSetup.x86_64" -output "$helper/MacOS/ChromeSetup"
rm "$helper/MacOS/ChromeSetup.arm64" "$helper/MacOS/ChromeSetup.x86_64"
cat > "$helper/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>com.ruslanrmv.tabswitcher.chrome-setup</string>
<key>CFBundleName</key><string>Tab Switcher — установка</string>
<key>CFBundleExecutable</key><string>ChromeSetup</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --deep --sign - "$bundle/Установить Tab Switcher.app"
codesign --verify --deep --strict "$bundle/Установить Tab Switcher.app"
cp "$root/packaging/README.txt" "$bundle/Прочти меня.txt"
ditto -c -k --sequesterRsrc --keepParent "$bundle" "$out"
printf 'Created %s\n' "$out"
