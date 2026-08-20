import AppKit
import CryptoKit
import Foundation

// MARK: - Date Formatter Extension
extension Date {
    public func timeAgoDisplay() -> String {
        let seconds = Int(-self.timeIntervalSinceNow)
        if seconds < 10 {
            return "刚刚"
        } else if seconds < 60 {
            return "\(seconds)秒前"
        } else if seconds < 3600 {
            return "\(seconds / 60)分钟前"
        } else if seconds < 86400 {
            return "\(seconds / 3600)小时前"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM-dd HH:mm"
            return formatter.string(from: self)
        }
    }
}

// MARK: - String Utilities
extension String {
    public var sha256Hash: String {
        let inputData = Data(self.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    public var isLikelyURL: Bool {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return false
        }
        let matches = detector.matches(in: trimmed, options: [], range: NSRange(location: 0, length: trimmed.utf16.count))
        return matches.count == 1 && matches.first?.range.length == trimmed.utf16.count
    }

    public var isLikelyHexColor: Bool {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = "^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$"
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }

    public var isLikelyCode: Bool {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.contains("\n") {
            let codeKeywords = ["func ", "let ", "var ", "const ", "function ", "def ", "class ", "import ", "export ", "<html", "<div", "{", "}", "SELECT ", "public ", "private ", "struct ", "return "]
            for kw in codeKeywords {
                if trimmed.contains(kw) {
                    return true
                }
            }
        }
        return false
    }

    public func extractColor() -> NSColor? {
        var str = self.trimmingCharacters(in: .whitespacesAndNewlines)
        if str.hasPrefix("#") {
            str.removeFirst()
        }
        guard let hexNumber = UInt64(str, radix: 16) else { return nil }
        
        if str.count == 6 {
            let r = CGFloat((hexNumber & 0xFF0000) >> 16) / 255.0
            let g = CGFloat((hexNumber & 0x00FF00) >> 8) / 255.0
            let b = CGFloat(hexNumber & 0x0000FF) / 255.0
            return NSColor(srgbRed: r, green: g, blue: b, alpha: 1.0)
        } else if str.count == 8 {
            let r = CGFloat((hexNumber & 0xFF000000) >> 24) / 255.0
            let g = CGFloat((hexNumber & 0x00FF0000) >> 16) / 255.0
            let b = CGFloat((hexNumber & 0x0000FF00) >> 8) / 255.0
            let a = CGFloat(hexNumber & 0x000000FF) / 255.0
            return NSColor(srgbRed: r, green: g, blue: b, alpha: a)
        }
        return nil
    }
}

// MARK: - NSImage Utilities
extension NSImage {
    public func pngData() -> Data? {
        guard let tiffRepresentation = self.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else {
            return nil
        }
        return bitmapImage.representation(using: .png, properties: [:])
    }

    public func jpegData(compressionQuality: CGFloat = 0.8) -> Data? {
        guard let tiffRepresentation = self.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else {
            return nil
        }
        return bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
    }

    public func resizedThumbnail(maxDimension: CGFloat = 160) -> NSImage {
        let size = self.size
        guard size.width > 0 && size.height > 0 else { return self }
        
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        if ratio >= 1.0 {
            return self
        }
        
        let newSize = NSSize(width: max(1, size.width * ratio), height: max(1, size.height * ratio))
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        self.draw(in: NSRect(origin: .zero, size: newSize),
                  from: NSRect(origin: .zero, size: size),
                  operation: .copy,
                  fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }
}
