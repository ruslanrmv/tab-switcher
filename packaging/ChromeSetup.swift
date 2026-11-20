import AppKit

final class ChromeSetupDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow!
    var timer: Timer?
    let folder = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ""
    let completed = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : ""

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !folder.isEmpty, !completed.isEmpty else { NSApp.terminate(nil); return }
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 540, height: 470), styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "Установка расширения Chrome"
        window.delegate = self
        window.center()
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        stack.edgeInsets = NSEdgeInsets(top: 24, left: 26, bottom: 24, right: 26)
        stack.translatesAutoresizingMaskIntoConstraints = false
        window.contentView?.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor),
            stack.topAnchor.constraint(equalTo: window.contentView!.topAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: window.contentView!.bottomAnchor)
        ])
        let heading = NSTextField(labelWithString: "Подключите расширение в Chrome")
        heading.font = .systemFont(ofSize: 19, weight: .semibold)
        stack.addArrangedSubview(heading)
        let steps = NSTextField(wrappingLabelWithString: "1. Откройте Chrome кнопкой ниже.\n\n2. Включите «Режим разработчика» и нажмите «Загрузить распакованное расширение».\n\n3. В окне выбора нажмите ⌘⇧G, затем ⌘V и Return. Откроется папка Extension.\n\n4. Нажмите «Выбрать». Это окно закроется после подключения.")
        steps.font = .systemFont(ofSize: 14)
        steps.maximumNumberOfLines = 0
        stack.addArrangedSubview(steps)
        steps.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -52).isActive = true
        let note = NSTextField(wrappingLabelWithString: "Путь к папке Extension уже скопирован. К этому окну можно вернуться из Dock.")
        note.font = .systemFont(ofSize: 12)
        note.textColor = .secondaryLabelColor
        stack.addArrangedSubview(note)
        note.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -52).isActive = true
        let buttons = NSStackView()
        buttons.orientation = .horizontal
        buttons.spacing = 10
        let openButton = NSButton(title: "Открыть Chrome", target: self, action: #selector(openChrome))
        openButton.bezelStyle = .rounded
        openButton.keyEquivalent = "\r"
        let copyButton = NSButton(title: "Скопировать путь ещё раз", target: self, action: #selector(copyPath))
        buttons.addArrangedSubview(openButton)
        buttons.addArrangedSubview(copyButton)
        stack.addArrangedSubview(buttons)
        copyPath()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if FileManager.default.fileExists(atPath: self.completed) { NSApp.terminate(nil) }
        }
    }
    @objc func copyPath() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(folder, forType: .string)
    }
    @objc func openChrome() {
        copyPath()
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = ["-a", "Google Chrome", "chrome://extensions/"]
        do { try task.run() } catch { NSSound.beep() }
    }
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApp.terminate(nil)
        return true
    }
}

let application = NSApplication.shared
let delegate = ChromeSetupDelegate()
application.setActivationPolicy(.regular)
application.delegate = delegate
application.run()
