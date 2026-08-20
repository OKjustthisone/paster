import AppKit

// 载入用户提供的胶棒图像
let sourcePath = "Resources/glue_stick.png"
let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "build/icon_512.png"

guard let sourceImage = NSImage(contentsOfFile: sourcePath) else {
    print("Error loading source image from \(sourcePath)")
    exit(1)
}

let size: CGFloat = 512
let appIcon = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
    guard let context = NSGraphicsContext.current?.cgContext else { return false }
    let scale = size / 512.0

    // 1. macOS 风格圆角矩形背景
    let bgRect = CGRect(x: 32 * scale, y: 32 * scale, width: 448 * scale, height: 448 * scale)
    let bgPath = CGPath(roundedRect: bgRect, cornerWidth: 100 * scale, cornerHeight: 100 * scale, transform: nil)

    context.saveGState()
    context.addPath(bgPath)
    context.clip()

    // 优雅微渐变纯净背景 (浅色灰白至微蓝)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let gradientColors = [
        NSColor(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0).cgColor,
        NSColor(red: 0.92, green: 0.94, blue: 0.97, alpha: 1.0).cgColor
    ] as CFArray
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: [0.0, 1.0]) {
        context.drawLinearGradient(gradient, start: CGPoint(x: 256 * scale, y: 480 * scale), end: CGPoint(x: 256 * scale, y: 32 * scale), options: [])
    }
    context.restoreGState()

    // 2. 绘制居中的胶棒图案
    let iconRect = CGRect(x: 96 * scale, y: 96 * scale, width: 320 * scale, height: 320 * scale)
    sourceImage.draw(in: iconRect, from: NSRect(origin: .zero, size: sourceImage.size), operation: .sourceOver, fraction: 1.0)

    return true
}

if let tiff = appIcon.tiffRepresentation,
   let rep = NSBitmapImageRep(data: tiff),
   let png = rep.representation(using: .png, properties: [:]) {
    try? png.write(to: URL(fileURLWithPath: outputPath))
}
