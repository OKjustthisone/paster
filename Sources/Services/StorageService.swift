import AppKit
import Foundation

public final class StorageService {
    public static let shared = StorageService()

    private let fileManager = FileManager.default
    private let baseDirectory: URL
    private let imagesDirectory: URL
    private let thumbnailsDirectory: URL
    private let historyFileURL: URL

    // 内存受限缓存：最大保留 25 张缩略图，最大内存开销不超过 2MB
    private let thumbnailCache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 25
        cache.totalCostLimit = 2 * 1024 * 1024
        return cache
    }()

    private init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        baseDirectory = appSupport.appendingPathComponent("com.nutcracker.paster", isDirectory: true)
        imagesDirectory = baseDirectory.appendingPathComponent("images", isDirectory: true)
        thumbnailsDirectory = baseDirectory.appendingPathComponent("thumbs", isDirectory: true)
        historyFileURL = baseDirectory.appendingPathComponent("history.json")

        createDirectoriesIfNeeded()
    }

    private func createDirectoriesIfNeeded() {
        do {
            if !fileManager.fileExists(atPath: baseDirectory.path) {
                try fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            if !fileManager.fileExists(atPath: imagesDirectory.path) {
                try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            if !fileManager.fileExists(atPath: thumbnailsDirectory.path) {
                try fileManager.createDirectory(at: thumbnailsDirectory, withIntermediateDirectories: true, attributes: nil)
            }
        } catch {
            print("[StorageService] Failed to create directories: \(error)")
        }
    }

    // MARK: - Load & Save History
    public func loadHistory() -> [ClipboardItem] {
        guard fileManager.fileExists(atPath: historyFileURL.path) else {
            return []
        }
        do {
            let data = try Data(contentsOf: historyFileURL)
            let items = try JSONDecoder().decode([ClipboardItem].self, from: data)
            return items
        } catch {
            print("[StorageService] Failed to load history: \(error)")
            return []
        }
    }

    public func saveHistory(_ items: [ClipboardItem]) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            do {
                let data = try JSONEncoder().encode(items)
                try data.write(to: self.historyFileURL, options: .atomic)
            } catch {
                print("[StorageService] Failed to save history: \(error)")
            }
        }
    }

    // MARK: - Image Storage
    public func saveImage(data: Data, id: UUID) -> String? {
        let fileName = "\(id.uuidString).png"
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL, options: .atomic)
            return fileName
        } catch {
            print("[StorageService] Failed to save image: \(error)")
            return nil
        }
    }

    public func saveThumbnail(data: Data, id: UUID) -> String? {
        let fileName = "\(id.uuidString)_thumb.png"
        let fileURL = thumbnailsDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL, options: .atomic)
            return fileName
        } catch {
            print("[StorageService] Failed to save thumbnail: \(error)")
            return nil
        }
    }

    public func loadThumbnailImage(fileName: String) -> NSImage? {
        let key = fileName as NSString
        if let cached = thumbnailCache.object(forKey: key) {
            return cached
        }

        let fileURL = thumbnailsDirectory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: fileURL),
              let img = NSImage(data: data) else {
            return nil
        }

        thumbnailCache.setObject(img, forKey: key, cost: data.count)
        return img
    }

    public func loadImage(fileName: String) -> Data? {
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        return try? Data(contentsOf: fileURL)
    }

    public func deleteImage(fileName: String) {
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        try? fileManager.removeItem(at: fileURL)
        
        let thumbName = fileName.replacingOccurrences(of: ".png", with: "_thumb.png")
        let thumbURL = thumbnailsDirectory.appendingPathComponent(thumbName)
        try? fileManager.removeItem(at: thumbURL)
        thumbnailCache.removeObject(forKey: thumbName as NSString)
    }

    public func clearAllImages() {
        thumbnailCache.removeAllObjects()
        guard let imgFiles = try? fileManager.contentsOfDirectory(atPath: imagesDirectory.path) else { return }
        for file in imgFiles {
            let fileURL = imagesDirectory.appendingPathComponent(file)
            try? fileManager.removeItem(at: fileURL)
        }
        guard let thumbFiles = try? fileManager.contentsOfDirectory(atPath: thumbnailsDirectory.path) else { return }
        for file in thumbFiles {
            let fileURL = thumbnailsDirectory.appendingPathComponent(file)
            try? fileManager.removeItem(at: fileURL)
        }
    }
}
