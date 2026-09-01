import AppKit
import SwiftUI

public struct PopoverContentView: View {
    @ObservedObject var monitor = ClipboardMonitor.shared

    @State private var searchText: String = ""
    @State private var selectedCategory: FilterCategory = .all
    @State private var showSettings: Bool = false
    @State private var previewItem: ClipboardItem? = nil
    @State private var hoverWorkItem: DispatchWorkItem? = nil
    @State private var selectedIndex: Int = 0
    @State private var localKeyMonitor: Any? = nil
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
        .popover(item: $previewItem, arrowEdge: .leading) { item in
            ItemPreviewView(item: item)
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheetView()
        }
        .onAppear {
            setupKeyboardMonitor()
        }
        .onDisappear {
            removeKeyboardMonitor()
        }
        .onChange(of: filteredItems) { items in
            if selectedIndex >= items.count {
                selectedIndex = max(0, items.count - 1)
            }
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
            Button(action: {
                clearHover()
                showSettings = true
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(4)
            }
            .buttonStyle(.plain)
            .help("偏好设置与快捷键")

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
                            isSelected: index == selectedIndex,
                            onSelect: { selected in
                                clearHover()
                                selectItem(selected)
                            },
                            onTogglePin: { pinned in
                                monitor.togglePin(pinned)
                            },
                            onDelete: { deleted in
                                clearHover()
                                monitor.deleteItem(deleted)
                            },
                            onHoverChange: { hoveredItem, isHovered in
                                handleRowHover(item: hoveredItem, isHovered: isHovered)
                            }
                        )
                        .id(item.id)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
            }
            .onChange(of: selectedIndex) { newIndex in
                if newIndex < filteredItems.count {
                    withAnimation {
                        proxy.scrollTo(filteredItems[newIndex].id, anchor: .center)
                    }
                }
            }
        }
    }

    // MARK: - Local Keyboard Shortcuts
    private func setupKeyboardMonitor() {
        removeKeyboardMonitor()

        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // 1. ESC 键关闭面板
            if event.keyCode == 53 { // kVK_Escape
                clearHover()
                AppDelegate.shared?.closePopover()
                return nil
            }

            // 2. ⌘ + 1 ~ 9 快速选择前9项
            if event.modifierFlags.contains(.command),
               let chars = event.charactersIgnoringModifiers,
               let firstChar = chars.first,
               let num = Int(String(firstChar)), num >= 1 && num <= 9 {
                let targetIndex = num - 1
                if targetIndex < filteredItems.count {
                    clearHover()
                    selectItem(filteredItems[targetIndex])
                    return nil
                }
            }

            // 3. 方向下键 (Down Arrow)
            if event.keyCode == 125 {
                if !filteredItems.isEmpty {
                    selectedIndex = min(filteredItems.count - 1, selectedIndex + 1)
                }
                return nil
            }

            // 4. 方向上键 (Up Arrow)
            if event.keyCode == 126 {
                if !filteredItems.isEmpty {
                    selectedIndex = max(0, selectedIndex - 1)
                }
                return nil
            }

            // 5. 回车键 (Return / Enter) 选中并粘贴
            if event.keyCode == 36 || event.keyCode == 76 {
                if selectedIndex >= 0 && selectedIndex < filteredItems.count {
                    clearHover()
                    selectItem(filteredItems[selectedIndex])
                    return nil
                }
            }

            // 6. Delete / Backspace 键 (⌘ + Backspace 删除当前选中项)
            if event.keyCode == 51 && event.modifierFlags.contains(.command) {
                if selectedIndex >= 0 && selectedIndex < filteredItems.count {
                    let itemToDelete = filteredItems[selectedIndex]
                    clearHover()
                    monitor.deleteItem(itemToDelete)
                    return nil
                }
            }

            return event
        }
    }

    private func removeKeyboardMonitor() {
        if let monitor = localKeyMonitor {
            NSEvent.removeMonitor(monitor)
            localKeyMonitor = nil
        }
    }

    // MARK: - Hover Handlers (Single Shared Popover)
    private func handleRowHover(item: ClipboardItem, isHovered: Bool) {
        if isHovered {
            hoverWorkItem?.cancel()
            let shouldPreview = (item.type == .image) || (item.characterCount > 25) || (item.type == .code) || (item.type == .color)
            guard shouldPreview else {
                previewItem = nil
                return
            }

            let workItem = DispatchWorkItem {
                self.previewItem = item
            }
            self.hoverWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: workItem)
        } else {
            hoverWorkItem?.cancel()
            hoverWorkItem = nil
            if previewItem?.id == item.id {
                previewItem = nil
            }
        }
    }

    private func clearHover() {
        hoverWorkItem?.cancel()
        hoverWorkItem = nil
        previewItem = nil
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
                    clearHover()
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
