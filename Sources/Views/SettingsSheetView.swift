import SwiftUI

public struct SettingsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var monitor = ClipboardMonitor.shared
    @ObservedObject var hotKeyManager = HotKeyManager.shared

    @AppStorage("autoPasteEnabled") private var autoPasteEnabled: Bool = true
    @State private var isAccessibilityGranted: Bool = AccessibilityHelper.isAccessibilityGranted()

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // 顶栏
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14, weight: .semibold))
                    Text("偏好设置")
                        .font(.system(size: 14, weight: .bold))
                }
                Spacer()
                Button("完成") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 1. 全局呼出快捷键
                    GroupBox(label: Label("全局快捷键 (Global Hotkey)", systemImage: "command")) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("唤醒面板快捷键:")
                                    .font(.system(size: 12))
                                Spacer()
                                Picker("", selection: Binding(
                                    get: { hotKeyManager.currentOption },
                                    set: { newOption in
                                        hotKeyManager.updateHotKey(to: newOption)
                                    }
                                )) {
                                    ForEach(GlobalHotKeyOption.allCases) { option in
                                        Text(option.displayName).tag(option)
                                    }
                                }
                                .frame(width: 150)
                            }

                            Text("在任何应用程序中按下此快捷键，即可立即唤出 Paster 剪切板面板。")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                    }

                    // 2. 自动填入功能
                    GroupBox(label: Label("自动填入 (Auto-Paste)", systemImage: "bolt.fill")) {
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle("点击列表项自动填入当前光标焦点", isOn: $autoPasteEnabled)
                                .toggleStyle(.switch)

                            Text("开启后，点击历史项将自动切回原应用并模拟 ⌘V 快速粘贴。")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)

                            Divider()

                            HStack {
                                Text("辅助功能权限:")
                                    .font(.system(size: 12))
                                Spacer()
                                if isAccessibilityGranted {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("已授权")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.green)
                                    }
                                } else {
                                    Button("去授权") {
                                        AccessibilityHelper.openAccessibilitySettings()
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                }
                            }
                        }
                        .padding(8)
                    }

                    // 3. 面板内快捷键指南
                    GroupBox(label: Label("面板快捷键指南", systemImage: "keyboard")) {
                        VStack(alignment: .leading, spacing: 6) {
                            shortcutRow(key: "⌘ 1 ~ ⌘ 9", desc: "瞬间复制并填入对应序号的历史项")
                            shortcutRow(key: "↑ / ↓ 方向键", desc: "在历史列表中快速上下切换选中")
                            shortcutRow(key: "回车 (Enter)", desc: "填入当前选中的项目")
                            shortcutRow(key: "⌘ + Delete", desc: "删除当前选中的项目")
                            shortcutRow(key: "ESC", desc: "退出并关闭面板")
                        }
                        .padding(8)
                    }

                    // 4. 历史容量设置
                    GroupBox(label: Label("存储容量", systemImage: "clock.arrow.circlepath")) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("最大保留条数:")
                                    .font(.system(size: 12))
                                Spacer()
                                Picker("", selection: $monitor.maxItemCount) {
                                    Text("30 条").tag(30)
                                    Text("50 条 (推荐)").tag(50)
                                    Text("100 条").tag(100)
                                    Text("200 条").tag(200)
                                }
                                .frame(width: 120)
                            }

                            Text("已置顶收藏的项目不受数量限制，不会被自动清理。")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                    }

                    // 5. 数据管理
                    GroupBox(label: Label("历史管理", systemImage: "trash")) {
                        HStack {
                            Button("清空未置顶历史") {
                                monitor.clearAll(preservePinned: true)
                            }
                            .controlSize(.small)

                            Spacer()

                            Button("清空全部数据", role: .destructive) {
                                monitor.clearAll(preservePinned: false)
                            }
                            .controlSize(.small)
                        }
                        .padding(8)
                    }

                    // 6. 关于 Paster
                    HStack {
                        Spacer()
                        VStack(spacing: 2) {
                            Text("Paster v1.0.0 (Glue Stick Edition)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("极简 · 极速 · 极低资源占用")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                        Spacer()
                    }
                    .padding(.top, 4)
                }
                .padding(16)
            }
        }
        .frame(width: 380, height: 480)
        .onAppear {
            isAccessibilityGranted = AccessibilityHelper.isAccessibilityGranted()
        }
    }

    private func shortcutRow(key: String, desc: String) -> some View {
        HStack {
            Text(key)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color(NSColor.tertiaryLabelColor).opacity(0.15))
                .cornerRadius(4)

            Spacer()

            Text(desc)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
}
