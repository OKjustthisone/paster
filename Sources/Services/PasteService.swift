import AppKit
import Carbon.HIToolbox
import Foundation

public final class PasteService {
    public static let shared = PasteService()

    public var onDismissPopover: (() -> Void)?
    public var onPasteComplete: ((ClipboardItem) -> Void)?

    private init() {}

    /// 将条目复制到剪切板，并根据设置智能自动粘贴至目标输入框
    public func paste(item: ClipboardItem, autoPaste: Bool = true) {
        // 1. 临时标记剪切板监听器忽略本次自身写入
        ClipboardMonitor.shared.markSelfWrite()

        // 2. 写入系统剪切板
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.type {
        case .text, .code, .link, .color:
            if let text = item.textContent {
                pasteboard.setString(text, forType: .string)
            }
        case .image:
            if let fileName = item.imageFileName,
               let imageData = StorageService.shared.loadImage(fileName: fileName),
               let image = NSImage(data: imageData) {
                pasteboard.writeObjects([image])
            } else if let thumb = item.thumbnailImage {
                pasteboard.writeObjects([thumb])
            }
        case .file:
            if let path = item.textContent {
                let fileURL = URL(fileURLWithPath: path)
                pasteboard.writeObjects([fileURL as NSURL])
            }
        }

        // 3. 关闭弹出面板
        onDismissPopover?()

        guard autoPaste else {
            onPasteComplete?(item)
            return
        }

        // 4. 恢复先前聚焦的目标应用程序并自动模拟 Cmd+V 填入
        let targetApp = AppTracker.shared.previousApp

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if let app = targetApp, !app.isTerminated {
                app.activate(options: [.activateIgnoringOtherApps])
            }

            // 等待目标应用窗口完全获得光标焦点后模拟按键
            DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 0.08) {
                self.simulateCmdV()
                
                DispatchQueue.main.async {
                    self.onPasteComplete?(item)
                }
            }
        }
    }

    /// 模拟按下 Cmd + V 快捷键
    private func simulateCmdV() {
        // 检查是否有辅助功能权限
        guard AccessibilityHelper.isAccessibilityGranted() else {
            DispatchQueue.main.async {
                AccessibilityHelper.requestAccessibilityPermission()
            }
            return
        }

        let keyCode: CGKeyCode = 0x09 // 'v' 键的虚拟键码 (kVK_ANSI_V)
        let source = CGEventSource(stateID: .combinedSessionState)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
