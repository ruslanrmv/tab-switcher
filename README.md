# Tab Switcher

**Ctrl+Tab, reimagined.** Switch between browser tabs the way you switch between apps — with visual previews and most-recently-used ordering.

[Website](https://tabswitcher.app) · [Download](https://tabswitcher.app/Tab%20Switcher.dmg) · [Setup Guide](https://tabswitcher.app/setup)

## Features

- **Visual tab previews** — See thumbnails, favicons, and titles as you cycle through tabs
- **Custom tab names** — In Chrome 150 or later, right-click a web tab in the tab strip and select **Rename tab…**. The name appears in Chrome and in the switcher, survives a reload of the same page, and is cleared when the tab changes URL or Chrome restarts. Open the same menu and choose **Restore original** in the editor to remove the custom name.
- **Most recently used order** — Tabs ordered by recency, not position. One Ctrl+Tab instantly jumps to your last tab
- **Copy URL shortcut** — Press Cmd+Shift+C to copy the current tab's URL to your clipboard with a confirmation toast
- **Customizable shortcuts** — Remap both the tab switcher and copy URL shortcuts to any key combination
- **Native performance** — A lightweight macOS companion app intercepts shortcuts at the system level
- **Multi-browser support** — Chrome, Brave, Edge, Arc, Vivaldi, Opera, and any Chromium-based browser
- **Auto-updates** — The native app updates itself automatically via Sparkle

## How It Works

Hold **Ctrl** and press **Tab** to bring up the visual switcher. Keep holding Ctrl and press Tab repeatedly to cycle through your tabs. Release Ctrl to switch to the selected tab.

Press **Cmd+Shift+C** to instantly copy the active tab's URL to your clipboard.

Works exactly like macOS app switching (Cmd+Tab), but for your browser tabs.

## Installation

Tab Switcher requires two components: a browser extension and a native macOS app.

### 1. Install the Extension

1. Download or clone this repository
2. Open Chrome and go to `chrome://extensions`
3. Enable **Developer mode** (toggle in top right)
4. Click **Load unpacked** and select this folder
5. Note the **Extension ID** shown (you'll need this later)

### 2. Install the Native App

Download the macOS app from [tabswitcher.app](https://tabswitcher.app/Tab%20Switcher.dmg).

1. Open the DMG and drag Tab Switcher to Applications
2. Open Tab Switcher from Applications
3. Grant Accessibility permission when prompted
4. Click **Enable** for your browser
5. Enter the **Extension ID** from step 1.5 and click **Save**

### 3. Grant Accessibility Permissions

If not prompted automatically:

1. Open **System Settings > Privacy & Security > Accessibility**
2. Enable the toggle next to Tab Switcher

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| **Ctrl+Tab** | Open switcher, cycle forward |
| **Ctrl+Shift+Tab** | Cycle backward |
| **Cmd+Shift+C** | Copy current tab URL |
| **Alt+W** | Quick switch to last tab (no UI) |

All shortcuts can be customized in the app's setup window.

## Requirements

- macOS 14.0 or later
- Any Chromium-based browser (Chrome, Brave, Edge, Arc, Vivaldi, Opera, etc.)
- Accessibility permissions for the native app

## Privacy

Custom tab names are kept locally in Chrome for the current browser session. See our [Privacy Policy](https://tabswitcher.app/privacy).

## Building from Source

### Extension
The extension files are in the root directory. Load unpacked in Chrome.

### Native App
```bash
cd native-host
swift build -c release
```

The built binary will be at `native-host/.build/release/tab-switcher`. To create a full app bundle with the Sparkle framework embedded:

```bash
cd native-host
./build.sh
```

The app bundle will be at `dist/Tab Switcher.app`. Code signing and notarization require a valid Apple Developer ID certificate and are optional for local development:

```bash
./build.sh --sign              # build + code sign
./build.sh --sign --notarize   # build + sign + notarize
```

## Project Structure

```
├── manifest.json          # Chrome extension manifest
├── mainsw.js              # Extension service worker
├── popup.html/js          # Extension popup UI
├── icon*.png              # Extension icons
├── native-host/
│   ├── Package.swift      # Swift package definition
│   ├── Sources/
│   │   └── tab-switcher/
│   │       └── main.swift # Native macOS app
│   ├── build.sh           # Build + sign + notarize script
│   ├── install.sh         # Install native messaging host
│   └── uninstall.sh       # Uninstall native messaging host
└── docs/                  # Website (GitHub Pages)
    ├── index.html
    ├── setup.html
    └── privacy.html
```

## Troubleshooting

**Extension shows "Not connected":**
- Make sure the Tab Switcher app is running
- Check that you've granted Accessibility permissions
- Verify the Extension ID was entered correctly

**Ctrl+Tab doesn't work:**
- Verify Accessibility permissions are enabled
- Make sure the browser window is focused

For more help, visit the [Setup Guide](https://tabswitcher.app/setup).

## License

MIT License — see [LICENSE](LICENSE)

## Personal macOS build

The personal build fixes carousel scrolling and disables the original developer's app update feed. It uses an ad-hoc signature; macOS Accessibility permission may need to be granted again after rebuilding. The Chrome Web Store extension remains the native messaging client.

### Personal installation bundle

The [personal installation bundle](releases/Tab-Switcher-Personal-macOS.zip) contains a universal Apple Silicon/Intel app and a locally loaded copy of the browser extension. `scripts/build-installer.sh` rebuilds it under `dist/`; rebuilding needs the same app template and Xcode tools as `build-personal.sh`, but the destination Mac does not need either. The included installer sets the native messaging host and a stable extension ID for Chrome. It stops rather than overwriting a different existing installation.

After extracting the zip on macOS 14 or newer, open `Установить Tab Switcher.app` and follow its prompts to grant Accessibility access and load the installed Extension folder using Chrome's developer mode. Chrome requires that manual step for a local extension on an unmanaged Mac; the installer copies the folder path to the clipboard. Keep the Extension folder in place. The installer can be resumed if the identical bundle and its configuration are already installed, but will not replace a different installation. The build is ad-hoc signed rather than notarized and may require the user to authorize it in macOS; it does not update automatically. The bundle is intended for trusted personal use and should be rebuilt and installed deliberately when updating.

Run `scripts/build-personal.sh` on macOS with Xcode command-line tools. By default it uses the installed `/Applications/Tab Switcher Personal.app` as a template for Sparkle and the icon and writes a separate bundle under `dist/`. To bootstrap from the original app, set `TAB_SWITCHER_TEMPLATE='/Applications/Tab Switcher.app'`. Set `TAB_SWITCHER_OUTPUT` to choose a fresh output path; the script refuses to overwrite an existing bundle. Install and grant Accessibility permission to the resulting app, then point the browser's native messaging manifest at its executable. Do not use the original app's update feed for this fork.

## Publishing this checkout

The local `publish` remote is configured with push URLs for the GitHub fork and the private Forgejo repository. After committing, run `git push publish HEAD` to publish the current branch to both. Git contacts the two servers separately; check both results if either push fails. The repository-specific SSH configuration and deploy key stay outside the tracked source.

## Extension-only prototype

[`extension-only/`](extension-only/) contains a standalone Chrome implementation that does not use the native helper. See its README for preview behavior, permissions, and the unsupported Control+Tab configuration.
