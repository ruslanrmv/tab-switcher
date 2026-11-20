#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
app="$HOME/Applications/Tab Switcher Personal.app"
extension="$HOME/Library/Application Support/Tab Switcher Personal/Extension"
config="$HOME/Library/Application Support/TabSwitcher/browser_config.json"
host="$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.tabswitcher.native.json"
id="ljjhnekahaikbjndkiihdpapdoafbfof"
fail() { printf "%s\n" "$1" >&2; exit 1; }
[ -d 'Tab Switcher Personal.app' ] && [ -f 'Extension/manifest.json' ] || fail 'Комплект неполный: распакуйте архив целиком.'
if [ -e "$app" ] || [ -e "$extension" ] || [ -e "$config" ] || [ -e "$host" ]; then
    if [ -f "$config" ] && [ -f "$host" ] && cmp -s "$app/Contents/MacOS/tab-switcher" 'Tab Switcher Personal.app/Contents/MacOS/tab-switcher' && diff -qr "$extension" Extension >/dev/null 2>&1; then
        export TABSWITCHER_INSTALL_APP="$app" TABSWITCHER_INSTALL_ID="$id" TABSWITCHER_INSTALL_CONFIG="$config" TABSWITCHER_INSTALL_HOST="$host"
        check=$(osascript -l JavaScript <<'JXA'
ObjC.import('Foundation');
const env=$.NSProcessInfo.processInfo.environment;
function read(k){return JSON.parse(ObjC.unwrap($.NSString.stringWithContentsOfFileEncodingError(env.objectForKey(k),$.NSUTF8StringEncoding,null)))}
const c=read('TABSWITCHER_INSTALL_CONFIG'), h=read('TABSWITCHER_INSTALL_HOST');
const id=ObjC.unwrap(env.objectForKey('TABSWITCHER_INSTALL_ID')), app=ObjC.unwrap(env.objectForKey('TABSWITCHER_INSTALL_APP'));
JSON.stringify(c.some(x=>x.id==='com.google.Chrome' && x.isEnabled && x.extensionId===id) && h.path===app+'/Contents/MacOS/tab-switcher' && h.allowed_origins.includes('chrome-extension://'+id+'/'));
JXA
        )
        [ "$check" = true ] || fail 'Найдена другая конфигурация Tab Switcher. Установщик не меняет её автоматически.'
        printf 'OK\n'
        exit 0
    fi
    fail 'Найдена существующая или неполная установка Tab Switcher. Установщик не заменяет её автоматически, чтобы сохранить ваши настройки.'
fi
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
printf "OK\n"
