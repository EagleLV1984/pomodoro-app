import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var viewController: ViewController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 612),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "番茄钟"
        window.center()
        window.minSize = NSSize(width: 280, height: 400)
        window.backgroundColor = NSColor(red: 0xFD/255, green: 0xF2/255, blue: 0xF2/255, alpha: 1.0)
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = false

        viewController = ViewController()
        window.contentViewController = viewController
        window.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {}

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
