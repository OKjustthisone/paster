import AppKit
import SwiftUI

public struct PopoverContentView: View {
    @ObservedObject var monitor = ClipboardMonitor.shared

    @State private var searchText: String = ""
    @State private var selectedCategory: FilterCategory = .all
    @State private var showSettings: Bool = false
    @AppStorage("autoPasteEnabled") private var autoPasteEnabled: Bool = true

    public init() {}

    private var filteredItems: [ClipboardItem] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return monitor.items.filter { item in
            // 分类过滤
            let categoryMatch: Bool
            switch selectedCategory {
            case .all:
                categoryMatch = true
            case .text:
                categoryMatch = (item.type == .text || item.type == .code || item.type == .link || item.type == .color)
            case .image:
                categoryMatch = (item.type == .image)
            case .pinned:
                categoryMatch = item.isPinned
            }

            guard categoryMatch else { return false }

            // 搜索词过滤
            if trimmed.isEmpty {
                return true
            }
            if let text = item.textContent, text.localizedCaseInsensitiveContains(trimmed) {
                return true
            }
            if item.previewText.localizedCaseInsensitiveContains(trimmed) {
                return true
            }
            return false
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 顶栏：标题与操作
            headerView

            Divider()

            // 搜索栏与分类
            SearchBarView(searchText: $searchText, selectedCategory: $selectedCategory)

            Divider()

            // 历史列表
            if filteredItems.isEmpty {
                emptyStateView
            } else {
                listView
            }

            Divider()

            // 底栏状态与快速操作
            footerView
        }
        .frame(width: 360, height: 480)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
        .sheet(isPresented: $showSettings) {
            SettingsSheetView()
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(nsImage: IconFactory.createMenuBarIcon())
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 15, height: 15)
                    .foregroundColor(.accentColor)

                Text("Paster")
                    .font(.system(size: 13, weight: .bold))

                Text("剪切板")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 设置按钮
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(4)
            }
            .buttonStyle(.plain)
            .help("偏好设置")

            // 退出按钮
            Button(action: { NSApplication.shared.terminate(nil) }) {
                Image(systemName: "power")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(4)
            }
            .buttonStyle(.plain)
            .help("退出 Paster")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - List View
    private var listView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                        ClipboardItemRow(
                            item: item,
                            index: index < 9 ? index : nil,
                            onSelect: { selected in
                                selectItem(selected)
                            },
                            onTogglePin: { pinned in
                                monitor.togglePin(pinned)
                            },
                            onDelete: { deleted in
                                monitor.deleteItem(deleted)
                            }
                        )
                        .id(item.id)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: searchText.isEmpty ? "clipboard" : "magnifyingglass")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.5))

            Text(searchText.isEmpty ? "剪切板历史空空如也\n尝试复制一些文本或截图吧" : "没有找到符合搜索条件的记录")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }

    // MARK: - Footer
    private var footerView: some View {
        HStack {
            Text("记录: \(monitor.items.count)/\(monitor.maxItemCount) 项")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Spacer()

            if !monitor.items.isEmpty {
                Button(action: {
                    monitor.clearAll(preservePinned: true)
                }) {
                    Text("清空未置顶")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .onHover { isHover in
                    if isHover { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
    }

    // MARK: - Actions
    private func selectItem(_ item: ClipboardItem) {
        PasteService.shared.paste(item: item, autoPaste: autoPasteEnabled)
    }
}

// MARK: - VisualEffectView for Native macOS Translucency
public struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
