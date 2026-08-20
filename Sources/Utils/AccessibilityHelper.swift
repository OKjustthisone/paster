import AppKit
import ApplicationServices
import Foundation

public final class AccessibilityHelper {
    
    /// 检查应用是否已获得 macOS 辅助功能（Accessibility）权限
    public static func isAccessibilityGranted() -> Bool {
        return AXIsProcessTrusted()
    }
    
    /// 触发系统辅助功能授权弹窗
    public static func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
    
    /// 打开 macOS 系统设置中的辅助功能隐私页
    public static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
