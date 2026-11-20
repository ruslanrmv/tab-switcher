import AppKit
import SwiftUI

private let accent = Color(red: 0.55, green: 0.55, blue: 1.0)

final class ChromeSetupDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, ObservableObject {
    var window: NSWindow!
    var timer: Timer?
    let folder = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ""
    let completed = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : ""
    @Published var copied = true

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !folder.isEmpty, !completed.isEmpty else { NSApp.terminate(nil); return }
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 620, height: 650), styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "Подключение к Chrome"
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.contentView = NSHostingView(rootView: ChromeSetupView(model: self))
        window.center()
        copyPath()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if FileManager.default.fileExists(atPath: self.completed) { NSApp.terminate(nil) }
        }
    }

    func copyPath() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(folder, forType: .string)
        copied = true
    }

    func openChrome() {
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

struct ChromeSetupView: View {
    @ObservedObject var model: ChromeSetupDelegate

    private func step(_ number: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Text(number).font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(accent).frame(width: 28, height: 28)
                .background(accent.opacity(0.15), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                Text(detail).font(.system(size: 12)).foregroundStyle(.white.opacity(0.64))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.system(size: 17, weight: .semibold)).foregroundStyle(accent)
                    .frame(width: 42, height: 42).background(accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 13))
                VStack(alignment: .leading, spacing: 3) {
                    Text("TAB SWITCHER").font(.system(size: 10, weight: .bold)).tracking(1.4).foregroundStyle(accent)
                    Text("Подключение к Chrome").font(.system(size: 20, weight: .bold)).foregroundStyle(.white)
                }
                Spacer()
            }
            Text("Осталось добавить расширение")
                .font(.system(size: 13)).foregroundStyle(.white.opacity(0.65))
            VStack(alignment: .leading, spacing: 17) {
                step("1", "Откройте страницу расширений", "Нажмите «Открыть Chrome» ниже. Включите «Режим разработчика» в правом верхнем углу.")
                step("2", "Нажмите «Загрузить распакованное расширение»", "Откроется системное окно выбора папки.")
                step("3", "Укажите папку Extension", "В окне выбора нажмите ⌘ ⇧ G. В появившееся поле вставьте адрес сочетанием ⌘ V и нажмите Return.")
                step("4", "Нажмите «Выбрать»", "После подключения это окно закроется автоматически.")
            }
            .padding(19).background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 18))
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Label("Адрес папки скопирован", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .semibold)).foregroundStyle(Color(red: 0.54, green: 0.85, blue: 0.72))
                    Spacer()
                    Button("Скопировать ещё раз") { model.copyPath() }.buttonStyle(.plain).font(.system(size: 11, weight: .medium)).foregroundStyle(accent)
                }
                Text(model.folder).font(.system(size: 10, design: .monospaced)).foregroundStyle(.white.opacity(0.48)).lineLimit(2).textSelection(.enabled)
            }
            Spacer(minLength: 0)
            HStack {
                Text("Это окно останется доступным в Dock")
                    .font(.system(size: 11)).foregroundStyle(.white.opacity(0.45))
                Spacer()
                Button(action: model.openChrome) {
                    HStack(spacing: 7) { Text("Открыть Chrome"); Image(systemName: "arrow.up.right") }
                        .font(.system(size: 13, weight: .semibold)).padding(.horizontal, 16).padding(.vertical, 10)
                }.buttonStyle(.plain).background(accent, in: RoundedRectangle(cornerRadius: 11)).foregroundStyle(Color.black.opacity(0.85))
            }
        }
        .padding(28)
        .frame(width: 620, height: 650)
        .background(LinearGradient(colors: [Color(red: 0.10, green: 0.11, blue: 0.17), Color(red: 0.055, green: 0.06, blue: 0.09)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .preferredColorScheme(.dark)
    }
}

let application = NSApplication.shared
let delegate = ChromeSetupDelegate()
application.setActivationPolicy(.regular)
application.delegate = delegate
application.run()
