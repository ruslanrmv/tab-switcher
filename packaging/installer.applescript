on run
	set bundleFolder to (POSIX path of (path to me)) & "Contents/Resources/Package/"
	set supportFolder to (POSIX path of (path to library folder from user domain)) & "Application Support/Tab Switcher Personal/Extension"
	set appPath to (POSIX path of (path to applications folder from user domain)) & "Tab Switcher Personal.app"
	try
		display dialog "Установим Tab Switcher Personal для Chrome. Программа и связь с расширением настроятся автоматически. Затем нужно разрешить доступ macOS и один раз выбрать папку расширения в Chrome." buttons {"Отмена", "Установить"} default button "Установить" with title "Установка Tab Switcher"
		set resultText to do shell script quoted form of (bundleFolder & "install.sh")
		if resultText is not "OK" then error resultText
		set readyFile to (POSIX path of (path to library folder from user domain)) & "Application Support/TabSwitcher/accessibility.ready"
		do shell script "/bin/rm -f " & quoted form of readyFile
		do shell script "/usr/bin/open -n -g " & quoted form of appPath & " --args --installer-permission"
		set accessGranted to false
		repeat 300 times
			try
				do shell script "/bin/test -f " & quoted form of readyFile
				set accessGranted to true
				exit repeat
			on error
				delay 1
			end try
		end repeat
		if not accessGranted then error "Доступ macOS не получен. Включите Tab Switcher Personal в настройках «Управление устройством и доступ к данным» и запустите установщик снова."
		set the clipboard to supportFolder
		do shell script "/usr/bin/open -a 'Google Chrome' 'chrome://extensions/'"
		display dialog "Шаг 2 из 2: в Chrome включите «Режим разработчика» и нажмите «Загрузить распакованное расширение». В окне выбора нажмите ⌘⇧G, вставьте скопированный путь сочетанием ⌘V и нажмите Return, затем «Выбрать». Путь уже скопирован. Вернитесь сюда после загрузки." buttons {"Отмена", "Готово"} default button "Готово" with title "Подключение расширения"
		repeat
			try
				do shell script "/bin/ps -axo command | /usr/bin/grep -F " & quoted form of (appPath & "/Contents/MacOS/tab-switcher") & " | /usr/bin/grep -F 'chrome-extension://ljjhnekahaikbjndkiihdpapdoafbfof/' | /usr/bin/grep -v grep >/dev/null"
				exit repeat
			on error
				set choice to button returned of (display dialog "Программа ещё не подключилась. Проверьте, что в Chrome выбрана нужная папка Extension и расширение включено, затем повторите проверку." buttons {"Закрыть", "Проверить снова"} default button "Проверить снова" with title "Проверяем подключение")
				if choice is "Закрыть" then return
			end try
		end repeat
		display dialog "Chrome запустил программу-помощник. Теперь проверьте в Chrome: удерживайте Control и нажимайте Tab. Если карусель не появилась, проверьте разрешение macOS и перезагрузите расширение." buttons {"Готово"} default button "Готово" with title "Установка завершена"
	on error errMsg number errNum
		if errNum is not -128 then display alert "Не удалось завершить установку" message errMsg as warning
	end try
end run
