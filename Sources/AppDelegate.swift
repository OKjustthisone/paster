import AppKit
import SwiftUI

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public static private(set) var shared: AppDelegate?

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var eventMonitor: Any?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self

        // 1. 初始化 AppTracker 与 ClipboardMonitor
        _ = AppTracker.shared
        ClipboardMonitor.shared.startMonitoring()

        // 2. 初始化 Popover 弹窗
        setupPopover()

        // 3. 创建系统菜单栏图标 (胶棒图标)
        setupStatusItem()

        // 4. 监听外部点击自动隐藏 Popover
        setupEventMonitor()

        // 5. 初始化全局快捷键 (Carbon HotKey)
        setupHotKey()

        // 6. 绑定 PasteService 关闭回调
        PasteService.shared.onDismissPopover = { [weak self] in
            self?.closePopover()
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 480)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: PopoverContentView())
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = IconFactory.createMenuBarIcon()
            button.toolTip = "Paster - 极速剪切板"
            button.target = self
            button.action = #selector(togglePopover(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    private func setupEventMonitor() {
        // 点击外部区域时自动关闭 Popover
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if let popover = self?.popover, popover.isShown {
                self?.closePopover()
            }
        }
    }

    private func setupHotKey() {
        HotKeyManager.shared.onHotKeyPressed = { [weak self] in
            self?.togglePopover(nil)
        }
        HotKeyManager.shared.setup()
    }

    @objc public func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            closePopover()
        } else {
            // 记录当前活跃应用，便于后续点击自动粘贴切回
            AppTracker.shared.recordCurrentFrontmost()

            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    public func closePopover() {
        popover.performClose(nil)
    }

    public func applicationWillTerminate(_ notification: Notification) {
        ClipboardMonitor.shared.stopMonitoring()
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
