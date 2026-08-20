import AppKit
import SwiftUI

public struct ClipboardItemRow: View {
    let item: ClipboardItem
    let index: Int?
    let onSelect: (ClipboardItem) -> Void
    let onTogglePin: (ClipboardItem) -> Void
    let onDelete: (ClipboardItem) -> Void

    @State private var isHovered = false

    public init(
        item: ClipboardItem,
        index: Int? = nil,
        onSelect: @escaping (ClipboardItem) -> Void,
        onTogglePin: @escaping (ClipboardItem) -> Void,
        onDelete: @escaping (ClipboardItem) -> Void
    ) {
        self.item = item
        self.index = index
        self.onSelect = onSelect
        self.onTogglePin = onTogglePin
        self.onDelete = onDelete
    }

    public var body: some View {
        Button(action: {
            onSelect(item)
        }) {
            HStack(alignment: .center, spacing: 10) {
                // 左侧类型图标 / 颜色块 / 缩略图
                leadingThumbnailOrIcon

                // 中间主要内容与元信息
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.previewText)
                        .font(.system(size: 12.5, weight: .regular))
                        .lineLimit(2)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 6) {
                        Text(item.timestamp.timeAgoDisplay())
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)

                        if item.type != .text {
                            Text(item.type.displayName)
                                .font(.system(size: 9.5, weight: .medium))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(badgeColor.opacity(0.15))
                                .foregroundColor(badgeColor)
                                .cornerRadius(4)
                        }

                        if item.characterCount > 0 && item.type == .text {
                            Text("\(item.characterCount) 字符")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary.opacity(0.8))
                        }

                        Spacer()
                    }
                }

                Spacer(minLength: 4)

                // 右侧操作区与快捷键标记
                HStack(spacing: 4) {
                    if isHovered {
                        // 收藏置顶按钮
                        Button(action: { onTogglePin(item) }) {
                            Image(systemName: item.isPinned ? "pin.fill" : "pin")
                                .font(.system(size: 11))
                                .foregroundColor(item.isPinned ? .orange : .secondary)
                                .padding(4)
                        }
                        .buttonStyle(.plain)
                        .help(item.isPinned ? "取消置顶" : "置顶收藏")

                        // 删除按钮
                        Button(action: { onDelete(item) }) {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .padding(4)
                        }
                        .buttonStyle(.plain)
                        .help("删除此项")
                    } else {
                        if item.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                                .padding(.trailing, 2)
                        } else if let idx = index, idx < 9 {
                            Text("⌘\(idx + 1)")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondary.opacity(0.6))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color(NSColor.quaternaryLabelColor).opacity(0.2))
                                .cornerRadius(3)
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
    }

    @ViewBuilder
    private var leadingThumbnailOrIcon: some View {
        switch item.type {
        case .image:
            if let thumbData = item.thumbnailData, let nsImage = NSImage(data: thumbData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            } else {
                defaultIconView(icon: "photo", color: .purple)
            }

        case .color:
            if let color = item.textContent?.extractColor() {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(nsColor: color))
                    .frame(width: 34, height: 34)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            } else {
                defaultIconView(icon: "paintpalette", color: .pink)
            }

        case .code:
            defaultIconView(icon: "curlybraces", color: .indigo)

        case .link:
            defaultIconView(icon: "link", color: .blue)

        case .file:
            defaultIconView(icon: "folder", color: .orange)

        case .text:
            defaultIconView(icon: "doc.text", color: .secondary)
        }
    }

    private func defaultIconView(icon: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.12))
                .frame(width: 32, height: 32)
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
        }
    }

    private var badgeColor: Color {
        switch item.type {
        case .image: return .purple
        case .color: return .pink
        case .code: return .indigo
        case .link: return .blue
        case .file: return .orange
        case .text: return .secondary
        }
    }
}
