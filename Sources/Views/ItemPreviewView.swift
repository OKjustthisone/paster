import AppKit
import SwiftUI

public struct ItemPreviewView: View {
    let item: ClipboardItem

    public init(item: ClipboardItem) {
        self.item = item
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 顶栏信息：类型徽章、时间、字数/尺寸
            HStack(spacing: 6) {
                Label(item.type.displayName, systemImage: item.type.iconName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(badgeColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(badgeColor.opacity(0.12))
                    .cornerRadius(4)

                if item.type == .text || item.type == .code {
                    Text("\(item.characterCount) 字符")
                        .font(.system(size: 10.5))
                        .foregroundColor(.secondary)
                } else if let dim = item.imageDimensions {
                    Text(dim)
                        .font(.system(size: 10.5))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(item.timestamp.timeAgoDisplay())
                    .font(.system(size: 10.5))
                    .foregroundColor(.secondary)
            }

            Divider()

            // 主体内容大图 / 长文本预览
            contentBody
        }
        .padding(12)
        .frame(minWidth: 260, maxWidth: 320)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
    }

    @ViewBuilder
    private var contentBody: some View {
        switch item.type {
        case .image:
            imagePreviewView

        case .color:
            colorPreviewView

        case .code:
            codePreviewView

        case .text, .link, .file:
            textPreviewView
        }
    }

    // MARK: - Image Preview
    @ViewBuilder
    private var imagePreviewView: some View {
        if let fileName = item.imageFileName,
           let data = StorageService.shared.loadImage(fileName: fileName),
           let nsImage = NSImage(data: data) {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 290, maxHeight: 260)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        } else if let thumbData = item.thumbnailData,
                  let nsImage = NSImage(data: thumbData) {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 290, maxHeight: 260)
                .cornerRadius(6)
        } else {
            Text("(图片数据已丢失)")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Color Preview
    @ViewBuilder
    private var colorPreviewView: some View {
        if let color = item.textContent?.extractColor() {
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: color))
                    .frame(height: 64)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                    )

                Text(item.textContent ?? "")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .textSelection(.enabled)
            }
        }
    }

    // MARK: - Code Preview
    @ViewBuilder
    private var codePreviewView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            Text(item.textContent ?? "")
                .font(.system(size: 11.5, design: .monospaced))
                .foregroundColor(.primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Color(NSColor.textBackgroundColor).opacity(0.6))
                .cornerRadius(6)
        }
        .frame(maxHeight: 220)
    }

    // MARK: - Text Preview
    @ViewBuilder
    private var textPreviewView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            Text(item.textContent ?? "")
                .font(.system(size: 12))
                .foregroundColor(.primary)
                .textSelection(.enabled)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: 220)
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
