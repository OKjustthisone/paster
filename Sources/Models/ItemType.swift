import Foundation

public enum ItemType: String, Codable, CaseIterable {
    case text
    case image
    case code
    case link
    case color
    case file

    public var displayName: String {
        switch self {
        case .text: return "文本"
        case .image: return "图片"
        case .code: return "代码"
        case .link: return "链接"
        case .color: return "颜色"
        case .file: return "文件"
        }
    }

    public var iconName: String {
        switch self {
        case .text: return "doc.text"
        case .image: return "photo"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .link: return "link"
        case .color: return "paintpalette"
        case .file: return "folder"
        }
    }
}
