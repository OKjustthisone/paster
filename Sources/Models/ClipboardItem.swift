import AppKit
import Foundation

public struct ClipboardItem: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public var type: ItemType
    public var textContent: String?
    public var imageFileName: String?
    public var thumbnailFileName: String?
    public var timestamp: Date
    public var isPinned: Bool
    public var characterCount: Int
    public var imageDimensions: String?
    public var contentHash: String

    public init(
        id: UUID = UUID(),
        type: ItemType,
        textContent: String? = nil,
        imageFileName: String? = nil,
        thumbnailFileName: String? = nil,
        timestamp: Date = Date(),
        isPinned: Bool = false,
        characterCount: Int = 0,
        imageDimensions: String? = nil,
        contentHash: String = ""
    ) {
        self.id = id
        self.type = type
        self.textContent = textContent
        self.imageFileName = imageFileName
        self.thumbnailFileName = thumbnailFileName
        self.timestamp = timestamp
        self.isPinned = isPinned
        self.characterCount = characterCount
        self.imageDimensions = imageDimensions
        self.contentHash = contentHash
    }

    public var thumbnailImage: NSImage? {
        guard let name = thumbnailFileName else { return nil }
        return StorageService.shared.loadThumbnailImage(fileName: name)
    }

    public var previewText: String {
        switch type {
        case .text, .code, .link, .color:
            guard let text = textContent else { return "(空内容)" }
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let singleLine = trimmed.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .joined(separator: " ⏎ ")
            return singleLine.isEmpty ? "(空白字符)" : singleLine
        case .image:
            if let dim = imageDimensions {
                return "图片 (\(dim))"
            }
            return "图片"
        case .file:
            return textContent ?? "文件"
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.id == rhs.id
    }
}
