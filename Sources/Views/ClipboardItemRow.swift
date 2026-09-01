import AppKit
import SwiftUI

public struct ClipboardItemRow: View {
    let item: ClipboardItem
    let index: Int?
    let isSelected: Bool
    let onSelect: (ClipboardItem) -> Void
    let onTogglePin: (ClipboardItem) -> Void
    let onDelete: (ClipboardItem) -> Void
    let onHoverChange: (ClipboardItem, Bool) -> Void

    @State private var isHovered = false

    public init(
        item: ClipboardItem,
        index: Int? = nil,
        isSelected: Bool = false,
        onSelect: @escaping (ClipboardItem) -> Void,
        onTogglePin: @escaping (ClipboardItem) -> Void,
        onDelete: @escaping (ClipboardItem) -> Void,
        onHoverChange: @escaping (ClipboardItem, Bool) -> Void
    ) {
        self.item = item
        self.index = index
        self.isSelected = isSelected
        self.onSelect = onSelect
        self.onTogglePin = onTogglePin
        self.onDelete = onDelete
        self.onHoverChange = onHoverChange
    }

    public var body: some View {
        Button(action: {
            onSelect(item)
        }) {
            HStack(alignment: .center, spacing: 8) {
                // 1. 左侧紧凑图标 / 缩略图 (20x20)
                leadingThumbnailOrIcon
                    .frame(width: 22, height: 22)

                // 2. 中间单行文本内容 (1行显示)
                Text(item.previewText)
                    .font(.system(size: 12, weight: isSelected ? .medium : .regular))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(isSelected ? .accentColor : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 4)

                // 3. 右侧状态 / 快捷键 / 操作区
                trailingAccessoryView
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered || isSelected ? Color.accentColor.opacity(0.14) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
            onHoverChange(item, hovering)
        }
    }

    // MARK: - Leading Icon / Thumbnail
    @ViewBuilder
    private var leadingThumbnailOrIcon: some View {
        switch item.type {
        case .image:
            if let thumb = item.thumbnailImage {
                Image(nsImage: thumb)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 22, height: 22)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                    )
            } else {
                compactIcon(icon: "photo", color: .purple)
            }

        case .color:
            if let color = item.textContent?.extractColor() {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(nsColor: color))
                    .frame(width: 20, height: 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5)
                    )
            } else {
                compactIcon(icon: "paintpalette", color: .pink)
            }

        case .code:
            compactIcon(icon: "chevron.left.forwardslash.chevron.right", color: .indigo)

        case .link:
            compactIcon(icon: "link", color: .blue)

        case .file:
            compactIcon(icon: "folder", color: .orange)

        case .text:
            compactIcon(icon: "doc.text", color: .secondary)
        }
    }

    private func compactIcon(icon: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(color.opacity(0.12))
                .frame(width: 20, height: 20)
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(color)
        }
    }

    // MARK: - Trailing Accessory View
    @ViewBuilder
    private var trailingAccessoryView: some View {
        HStack(spacing: 4) {
            if isHovered {
                // 收藏置顶按钮
                Button(action: { onTogglePin(item) }) {
                    Image(systemName: item.isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 10))
                        .foregroundColor(item.isPinned ? .orange : .secondary)
                        .padding(3)
                }
                .buttonStyle(.plain)
                .help(item.isPinned ? "取消置顶" : "置顶收藏")

                // 删除按钮
                Button(action: {
                    onDelete(item)
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .padding(3)
                }
                .buttonStyle(.plain)
                .help("删除此项")
            } else {
                // 时间显示
                Text(item.timestamp.timeAgoDisplay())
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.8))

                if item.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.orange)
                        .padding(.trailing, 1)
                } else if let idx = index, idx < 9 {
                    Text("⌘\(idx + 1)")
                        .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                        .foregroundColor(isSelected ? .accentColor : .secondary.opacity(0.6))
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .background(
                            isSelected
                            ? Color.accentColor.opacity(0.18)
                            : Color(NSColor.quaternaryLabelColor).opacity(0.2)
                        )
                        .cornerRadius(3)
                }
            }
        }
    }
}
