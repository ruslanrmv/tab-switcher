on run
	set bundleFolder to (POSIX path of (path to me)) & "Contents/Resources/Package/"
	set supportFolder to (POSIX path of (path to library folder from user domain)) & "Application Support/Tab Switcher Personal/Extension"
	set appPath to (POSIX path of (path to applications folder from user domain)) & "Tab Switcher Personal.app"
	set dialogTool to quoted form of (bundleFolder & "Chrome Setup.app/Contents/MacOS/ChromeSetup")
	try
		set answer to do shell script dialogTool & " --dialog start " & quoted form of "Установка Tab Switcher" & " " & quoted form of "Установим программу и подготовим расширение для Chrome. Затем разрешите доступ macOS и один раз выберите папку расширения в Chrome."
		if answer is not "ok" then error number -128
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
		set completionFile to (POSIX path of (path to library folder from user domain)) & "Application Support/TabSwitcher/chrome-setup.complete"
		do shell script "/bin/rm -f " & quoted form of completionFile
		do shell script "/usr/bin/open -n " & quoted form of (bundleFolder & "Chrome Setup.app") & " --args " & quoted form of supportFolder & " " & quoted form of completionFile
		set extensionConnected to false
		repeat 300 times
			try
				do shell script "/bin/ps -axo command | /usr/bin/grep -F " & quoted form of (appPath & "/Contents/MacOS/tab-switcher") & " | /usr/bin/grep -F 'chrome-extension://ljjhnekahaikbjndkiihdpapdoafbfof/' | /usr/bin/grep -v grep >/dev/null"
				set extensionConnected to true
				exit repeat
			on error
				delay 1
			end try
		end repeat
		do shell script "/usr/bin/touch " & quoted form of completionFile
		if not extensionConnected then error "Расширение не подключилось. Убедитесь, что оно загружено и включено в Chrome, затем откройте установщик ещё раз."
		do shell script dialogTool & " --dialog done " & quoted form of "Установка завершена" & " " & quoted form of "Расширение подключено. В Chrome удерживайте Control и нажимайте Tab, чтобы переключаться между вкладками."
	on error errMsg number errNum
		if errNum is not -128 then do shell script dialogTool & " --dialog error " & quoted form of "Не удалось завершить установку" & " " & quoted form of errMsg
	end try
end run
