import AppKit
import Combine
import Foundation

public final class ClipboardMonitor: ObservableObject {
    public static let shared = ClipboardMonitor()

    @Published public var items: [ClipboardItem] = []
    @Published public var maxItemCount: Int = 50

    private var timer: Timer?
    private var lastChangeCount: Int = -1
    private var ignoreNextCount = false
    private let pasteboard = NSPasteboard.general

    private init() {
        self.items = StorageService.shared.loadHistory()
        self.lastChangeCount = pasteboard.changeCount
    }

    public func startMonitoring(interval: TimeInterval = 0.5) {
        stopMonitoring()
        self.lastChangeCount = pasteboard.changeCount

        // 采用低开销 Timer 轮询 changeCount
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    public func markSelfWrite() {
        ignoreNextCount = true
        lastChangeCount = pasteboard.changeCount + 1
    }

    // MARK: - Check Pasteboard
    private func checkPasteboard() {
        let currentCount = pasteboard.changeCount
        guard currentCount != lastChangeCount else { return }
        
        lastChangeCount = currentCount

        if ignoreNextCount {
            ignoreNextCount = false
            return
        }

        processPasteboardContent()
    }

    private func processPasteboardContent() {
        // 1. 检查图片内容
        if let image = extractImageFromPasteboard() {
            handleNewImage(image)
            return
        }

        // 2. 检查文本内容
        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            handleNewText(text)
            return
        }

        // 3. 检查文件 URL
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], let firstURL = urls.first {
            handleNewFile(firstURL)
            return
        }
    }

    // MARK: - Extractors
    private func extractImageFromPasteboard() -> NSImage? {
        if let images = pasteboard.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage],
           let firstImage = images.first {
            return firstImage
        }
        if let data = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff),
           let image = NSImage(data: data) {
            return image
        }
        return nil
    }

    // MARK: - Handlers
    private func handleNewImage(_ image: NSImage) {
        let id = UUID()
        let thumbnail = image.resizedThumbnail(maxDimension: 160)
        let thumbData = thumbnail.pngData()
        let fullData = image.pngData() ?? image.tiffRepresentation

        var imageFileName: String? = nil
        if let data = fullData {
            imageFileName = StorageService.shared.saveImage(data: data, id: id)
        }

        let dimensions = "\(Int(image.size.width)) × \(Int(image.size.height))"
        let hash = (thumbData ?? Data()).base64EncodedString().sha256Hash

        // 避免重复连续拷贝相同图片
        if let first = items.first, first.type == .image && first.contentHash == hash {
            updateItemTimestamp(id: first.id)
            return
        }

        let item = ClipboardItem(
            id: id,
            type: .image,
            textContent: nil,
            imageFileName: imageFileName,
            thumbnailData: thumbData,
            timestamp: Date(),
            isPinned: false,
            characterCount: 0,
            imageDimensions: dimensions,
            contentHash: hash
        )

        insertItem(item)
    }

    private func handleNewText(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var type: ItemType = .text
        if text.isLikelyURL {
            type = .link
        } else if text.isLikelyHexColor {
            type = .color
        } else if text.isLikelyCode {
            type = .code
        }

        let hash = text.sha256Hash

        // 查重：若已存在相同内容，移至顶部并更新时间
        if let existingIndex = items.firstIndex(where: { $0.contentHash == hash }) {
            var existingItem = items.remove(at: existingIndex)
            existingItem.timestamp = Date()
            items.insert(existingItem, at: 0)
            persist()
            return
        }

        let item = ClipboardItem(
            id: UUID(),
            type: type,
            textContent: text,
            imageFileName: nil,
            thumbnailData: nil,
            timestamp: Date(),
            isPinned: false,
            characterCount: text.count,
            imageDimensions: nil,
            contentHash: hash
        )

        insertItem(item)
    }

    private func handleNewFile(_ url: URL) {
        let path = url.path
        let hash = path.sha256Hash

        if let existingIndex = items.firstIndex(where: { $0.contentHash == hash }) {
            var existingItem = items.remove(at: existingIndex)
            existingItem.timestamp = Date()
            items.insert(existingItem, at: 0)
            persist()
            return
        }

        let item = ClipboardItem(
            id: UUID(),
            type: .file,
            textContent: path,
            timestamp: Date(),
            characterCount: path.count,
            contentHash: hash
        )

        insertItem(item)
    }

    // MARK: - List Management
    private func insertItem(_ item: ClipboardItem) {
        items.insert(item, at: 0)
        trimHistory()
        persist()
    }

    private func updateItemTimestamp(id: UUID) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].timestamp = Date()
            let updated = items.remove(at: index)
            items.insert(updated, at: 0)
            persist()
        }
    }

    private func trimHistory() {
        // 保留所有已置顶项，非置顶项按 FIFO 淘汰至 maxItemCount
        let pinnedItems = items.filter { $0.isPinned }
        let unpinnedItems = items.filter { !$0.isPinned }

        let allowedUnpinned = max(10, maxItemCount - pinnedItems.count)
        if unpinnedItems.count > allowedUnpinned {
            let toRemove = unpinnedItems.suffix(from: allowedUnpinned)
            for item in toRemove {
                if let fileName = item.imageFileName {
                    StorageService.shared.deleteImage(fileName: fileName)
                }
            }
            let keptUnpinned = Array(unpinnedItems.prefix(allowedUnpinned))
            // 重新组合并按时间排序 (置顶项可排前面)
            items = (pinnedItems + keptUnpinned).sorted {
                if $0.isPinned != $1.isPinned {
                    return $0.isPinned && !$1.isPinned
                }
                return $0.timestamp > $1.timestamp
            }
        }
    }

    public func deleteItem(_ item: ClipboardItem) {
        if let fileName = item.imageFileName {
            StorageService.shared.deleteImage(fileName: fileName)
        }
        items.removeAll(where: { $0.id == item.id })
        persist()
    }

    public func togglePin(_ item: ClipboardItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isPinned.toggle()
            items.sort {
                if $0.isPinned != $1.isPinned {
                    return $0.isPinned && !$1.isPinned
                }
                return $0.timestamp > $1.timestamp
            }
            persist()
        }
    }

    public func clearAll(preservePinned: Bool = true) {
        if preservePinned {
            let unpinned = items.filter { !$0.isPinned }
            for item in unpinned {
                if let fileName = item.imageFileName {
                    StorageService.shared.deleteImage(fileName: fileName)
                }
            }
            items.removeAll(where: { !$0.isPinned })
        } else {
            StorageService.shared.clearAllImages()
            items.removeAll()
        }
        persist()
    }

    private func persist() {
        StorageService.shared.saveHistory(items)
    }
}
