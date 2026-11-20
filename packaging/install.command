#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
app="$HOME/Applications/Tab Switcher Personal.app"
extension="$HOME/Library/Application Support/Tab Switcher Personal/Extension"
config="$HOME/Library/Application Support/TabSwitcher/browser_config.json"
host="$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.tabswitcher.native.json"
id="ljjhnekahaikbjndkiihdpapdoafbfof"
fail() { printf '\n%s\nНажмите Return, чтобы закрыть окно.\n' "$1"; read -r; exit 1; }
[ -d 'Tab Switcher Personal.app' ] && [ -f 'Extension/manifest.json' ] || fail 'Комплект неполный: распакуйте архив целиком.'
[ ! -e "$app" ] && [ ! -e "$extension" ] && [ ! -e "$config" ] && [ ! -e "$host" ] || fail 'Найдена существующая установка Tab Switcher. Для её сохранности автоматическая установка остановлена.'
[ -d '/Applications/Google Chrome.app' ] || [ -d "$HOME/Applications/Google Chrome.app" ] || fail 'Сначала установите Google Chrome.'
mkdir -p "$(dirname "$app")" "$(dirname "$extension")" "$(dirname "$config")" "$(dirname "$host")"
ditto 'Tab Switcher Personal.app' "$app"
ditto 'Extension' "$extension"
export TABSWITCHER_INSTALL_APP="$app" TABSWITCHER_INSTALL_ID="$id"
osascript -l JavaScript <<'JXA' > "$config"
JSON.stringify([{id:'com.google.Chrome',name:'Google Chrome',nativeMessagingPath:'Google/Chrome/NativeMessagingHosts',extensionId:$.NSProcessInfo.processInfo.environment.objectForKey('TABSWITCHER_INSTALL_ID').js,isEnabled:true,combineAllWindows:false,appName:'Google Chrome'}])
JXA
osascript -l JavaScript <<'JXA' > "$host"
JSON.stringify({name:'com.tabswitcher.native',description:'Tab Switcher Native Helper',path:$.NSProcessInfo.processInfo.environment.objectForKey('TABSWITCHER_INSTALL_APP').js+'/Contents/MacOS/tab-switcher',type:'stdio',allowed_origins:['chrome-extension://'+$.NSProcessInfo.processInfo.environment.objectForKey('TABSWITCHER_INSTALL_ID').js+'/']})
JXA
printf '\nУстановлено. Осталось один раз подключить расширение и разрешить доступ macOS.\n\n1. В Chrome включите режим разработчика и нажмите «Загрузить распакованное расширение».\n2. Выберите папку Extension в открывшемся Finder.\n3. Откройте Tab Switcher Personal и разрешите доступ в Универсальном доступе macOS.\n\nПапка расширения: %s\n' "$extension"
open "$extension"
open -a 'Google Chrome' 'chrome://extensions/'
open "$app"
printf '\nНажмите Return, чтобы закрыть окно.\n'
read -r
