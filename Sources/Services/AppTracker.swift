import AppKit
import Foundation

public final class AppTracker {
    public static let shared = AppTracker()

    private(set) public var previousApp: NSRunningApplication?
    private var ownProcessIdentifier: pid_t

    private init() {
        self.ownProcessIdentifier = ProcessInfo.processInfo.processIdentifier
        setupObserver()
    }

    private func setupObserver() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(applicationDidActivate(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    @objc private func applicationDidActivate(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        // 忽略自身激活事件，仅记录外部应用
        if app.processIdentifier != ownProcessIdentifier {
            self.previousApp = app
        }
    }

    public func recordCurrentFrontmost() {
        if let frontmost = NSWorkspace.shared.frontmostApplication,
           frontmost.processIdentifier != ownProcessIdentifier {
            self.previousApp = frontmost
        }
    }
}
