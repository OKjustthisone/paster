import AppKit
import CoreGraphics
import Foundation

public final class IconFactory {

    /// 生成适配 macOS 菜单栏的胶棒（Glue Stick）矢量模板图标
    public static func createMenuBarIcon() -> NSImage {
        let targetSize = NSSize(width: 18, height: 18)
        let icon = NSImage(size: targetSize)
        var hasAddedRep = false

        // 尝试加载 @2x Retina 分辨率位图
        if let url2x = findResourceURL(name: "glue_stick_18@2x", ext: "png"),
           let data2x = try? Data(contentsOf: url2x),
           let rep2x = NSBitmapImageRep(data: data2x) {
            rep2x.size = targetSize
            icon.addRepresentation(rep2x)
            hasAddedRep = true
        }

        // 尝试加载 @1x 标准分辨率位图
        if let url1x = findResourceURL(name: "glue_stick_18", ext: "png"),
           let data1x = try? Data(contentsOf: url1x),
           let rep1x = NSBitmapImageRep(data: data1x) {
            rep1x.size = targetSize
            icon.addRepresentation(rep1x)
            hasAddedRep = true
        }

        // 若未找到资源文件，采用原生矢量代码精确绘制（无外部文件依赖）
        if !hasAddedRep {
            let vectorImage = NSImage(size: targetSize, flipped: false) { rect in
                guard let context = NSGraphicsContext.current?.cgContext else { return false }

                let strokeColor = NSColor.black.cgColor
                context.setLineWidth(3.0)
                context.setStrokeColor(strokeColor)
                context.setLineCap(.round)
                context.setLineJoin(.round)

                // 1. 顶部旋钮盖帽 (Top Cap)
                let capRect = CGRect(x: 2.2, y: 12.8, width: 5.6, height: 3.2)
                context.stroke(capRect)

                // 盖帽垂直刻度线 (2条分割线分成3格)
                context.setLineWidth(2.2)
                context.move(to: CGPoint(x: 4.1, y: 12.8))
                context.addLine(to: CGPoint(x: 4.1, y: 16.0))
                context.move(to: CGPoint(x: 5.9, y: 12.8))
                context.addLine(to: CGPoint(x: 5.9, y: 16.0))
                context.strokePath()

                // 2. 胶棒圆柱主体管身 (Main Tube Body)
                context.setLineWidth(3.0)
                let bodyRect = CGRect(x: 2.7, y: 5.4, width: 4.6, height: 7.4)
                context.stroke(bodyRect)

                // 3. 底部探出的圆角固体胶体 (Exposed Glue Tip)
                let glueRect = CGRect(x: 3.2, y: 2.4, width: 3.6, height: 3.0)
                let gluePath = CGPath(roundedRect: glueRect, cornerWidth: 1.2, cornerHeight: 1.2, transform: nil)
                context.addPath(gluePath)
                context.strokePath()

                // 4. 底部向右延伸的涂抹胶水轨迹横线 (Trailing Glue Line)
                context.move(to: CGPoint(x: 3.2, y: 2.4))
                context.addLine(to: CGPoint(x: 16.2, y: 2.4))
                context.strokePath()

                return true
            }
            vectorImage.isTemplate = true
            return vectorImage
        }

        icon.isTemplate = true
        return icon
    }

    private static func findResourceURL(name: String, ext: String) -> URL? {
        if let bundleURL = Bundle.main.url(forResource: name, withExtension: ext) {
            return bundleURL
        }
        let localPath = "Resources/\(name).\(ext)"
        if FileManager.default.fileExists(atPath: localPath) {
            return URL(fileURLWithPath: localPath)
        }
        return nil
    }

    /// 生成应用大图标
    public static func createAppIcon(size: CGFloat = 512) -> NSImage {
        if let url = findResourceURL(name: "glue_stick_512", ext: "png"),
           let img = NSImage(contentsOf: url) {
            return img
        }
        if let url = findResourceURL(name: "glue_stick", ext: "png"),
           let img = NSImage(contentsOf: url) {
            return img
        }
        return createMenuBarIcon()
    }
}
