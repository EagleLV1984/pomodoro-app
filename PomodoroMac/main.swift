import Cocoa
import WebKit
import SwiftUI
import IOKit

// MARK: - SwiftUI 液态玻璃背景
struct LiquidGlassBackground: View {
    var body: some View {
        Color.clear
            .background(.ultraThinMaterial)
    }
}

// MARK: - View Controller
class PomodoroVC: NSViewController, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    var webView: WKWebView!
    var glassView: NSView!

    override func loadView() {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        config.userContentController.add(self, name: "hostBridge")

        webView = WKWebView(frame: .zero, configuration: config)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.setValue(false, forKey: "drawsBackground")
        webView.wantsLayer = true
        webView.layer?.backgroundColor = NSColor.clear.cgColor

        // macOS 26+ 使用 SwiftUI .ultraThinMaterial
        // 旧版回退到 NSVisualEffectView
        let container = NSView(frame: .zero)
        container.wantsLayer = true

        if #available(macOS 26.0, *) {
            let swiftUIGlass = NSHostingView(rootView: LiquidGlassBackground())
            swiftUIGlass.wantsLayer = true
            swiftUIGlass.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(swiftUIGlass)
            NSLayoutConstraint.activate([
                swiftUIGlass.topAnchor.constraint(equalTo: container.topAnchor),
                swiftUIGlass.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                swiftUIGlass.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                swiftUIGlass.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            ])
        } else {
            let legacyGlass = NSVisualEffectView(frame: .zero)
            legacyGlass.wantsLayer = true
            legacyGlass.blendingMode = .behindWindow
            legacyGlass.material = .underWindowBackground
            legacyGlass.state = .active
            legacyGlass.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(legacyGlass)
            NSLayoutConstraint.activate([
                legacyGlass.topAnchor.constraint(equalTo: container.topAnchor),
                legacyGlass.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                legacyGlass.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                legacyGlass.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            ])
        }

        // WKWebView 放在玻璃层上方
        container.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: container.topAnchor),
            webView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])

        glassView = container
        view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadHTML()
    }

    func loadHTML() {
        var htmlPath: String?
        if let path = Bundle.main.path(forResource: "pomodoro", ofType: "html") {
            htmlPath = path
        } else if let exePath = Bundle.main.executablePath {
            let dir = (exePath as NSString).deletingLastPathComponent
            htmlPath = "\(dir)/pomodoro.html"
        }
        guard let path = htmlPath else {
            webView.loadHTMLString("<h1>找不到 pomodoro.html</h1>", baseURL: nil)
            return
        }
        let url = URL(fileURLWithPath: path)
        let dirURL = url.deletingLastPathComponent()
        webView.loadFileURL(url, allowingReadAccessTo: dirURL)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "hostBridge",
              let body = message.body as? String,
              let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String
        else { return }
        switch type {
        case "alwaysOnTop":
            if let val = json["value"] as? Bool {
                DispatchQueue.main.async { self.view.window?.level = val ? .floating : .normal }
            }
        case "resizeWindow":
            if let w = json["width"] as? Int, let h = json["height"] as? Int {
                DispatchQueue.main.async {
                    self.view.window?.setContentSize(NSSize(width: w, height: h))
                    self.view.window?.center()
                }
            }
        case "setDarkMode":
            if let dark = json["value"] as? Bool {
                DispatchQueue.main.async {
                    NSApp.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
                }
            }
        default: break
        }
    }

    @available(macOS 12.0, *)
    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType,
                 decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        decisionHandler(.grant)
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var sleepAssertion: IOPMAssertionID = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 阻止屏幕休眠
        IOPMAssertionCreateWithName(
            "PreventUserIdleDisplaySleep" as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "超坦番茄钟运行中" as CFString,
            &sleepAssertion
        )
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 612),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "超坦番茄钟"
        window.center()
        window.minSize = NSSize(width: 280, height: 280)
        window.backgroundColor = NSColor.clear
        window.isOpaque = false
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = false
        window.hasShadow = true

        let vc = PomodoroVC()
        window.contentViewController = vc
        window.makeKeyAndOrderFront(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        if sleepAssertion != 0 {
            IOPMAssertionRelease(sleepAssertion)
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
