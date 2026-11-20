#!/usr/bin/env python3
"""Exercise the actual SwiftUI carousel in an offscreen AppKit window on macOS."""
from pathlib import Path
import subprocess
import tempfile

source = (Path(__file__).resolve().parents[1] / 'native-host/Sources/tab-switcher/main.swift').read_text()
start = source.index('struct TabInfo: Identifiable')
end = source.index('// MARK:', source.index('struct VisualEffectView', start) + 10)
test = r'''
func findScroll(_ view: NSView) -> NSScrollView? {
    if let scroll = view as? NSScrollView { return scroll }
    for child in view.subviews { if let scroll = findScroll(child) { return scroll } }
    return nil
}
func pump() {
    let end = Date().addingTimeInterval(0.35)
    while Date() < end { _ = RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.01)) }
}
let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
let state = TabSwitcherState.shared
state.tabs = (0..<40).map { TabInfo(id: 350000000 + $0, title: "Tab \($0)", favIconUrl: "", thumbnail: nil, url: "") }
state.selectedIndex = 20
state.isVisible = false
let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 800, height: 178), styleMask: .borderless, backing: .buffered, defer: false)
let host = NSHostingView(rootView: TabSwitcherView())
window.contentView = host
window.setFrameOrigin(NSPoint(x: -20000, y: -20000))
window.orderFront(nil)
window.setContentSize(NSSize(width: 800, height: 178))
state.isVisible = true
window.displayIfNeeded()
pump()
guard var scroll = findScroll(host) else { fatalError("Missing scroll view") }
func assertVisible(_ index: Int) {
    let x = scroll.contentView.bounds.origin.x
    let left = CGFloat(index) * 232 + 16
    let right = left + 220
    let viewport = scroll.contentSize.width
    guard left >= x - 1 && right <= x + viewport + 1 else {
        fatalError("Tab \(index) is outside viewport: tab=\(left)...\(right), viewport=\(x)...\(x + viewport)")
    }
    print("Tab \(index) visible, offset \(Int(x))")
}
assertVisible(20)
for index in [21, 39, 0, 1, 30, 4] {
    state.selectedIndex = index
    pump()
    assertVisible(index)
}
state.isVisible = false
pump()
state.selectedIndex = 39
state.isVisible = true
window.setContentSize(NSSize(width: 800, height: 178))
window.displayIfNeeded()
pump()
guard let reopened = findScroll(host) else { fatalError("Missing reopened scroll view") }
scroll = reopened
assertVisible(39)
print("PASS: initial selection, forward, backward, wrap and reopening with 40 tabs")
'''
with tempfile.TemporaryDirectory(prefix='tabswitcher-scroll-test-') as tmp:
    path = Path(tmp) / 'main.swift'
    binary = Path(tmp) / 'carousel-test'
    path.write_text('import AppKit\nimport SwiftUI\nimport Combine\n' + source[start:end] + test)
    subprocess.run(['swiftc', '-suppress-warnings', str(path), '-o', str(binary)], check=True)
    subprocess.run([str(binary)], check=True)
