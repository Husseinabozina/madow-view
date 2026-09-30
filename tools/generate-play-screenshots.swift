import AppKit
import Foundation

private let canvasWidth: CGFloat = 1080
private let canvasHeight: CGFloat = 1920

private struct Slide {
    let id: String
    let source: String
    let title: String
    let subtitle: String
    let background: NSColor
    let accent: NSColor
}

private func color(_ hex: UInt32) -> NSColor {
    NSColor(
        calibratedRed: CGFloat((hex >> 16) & 0xff) / 255,
        green: CGFloat((hex >> 8) & 0xff) / 255,
        blue: CGFloat(hex & 0xff) / 255,
        alpha: 1
    )
}

private func rectFromTop(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> NSRect {
    NSRect(x: x, y: canvasHeight - y - height, width: width, height: height)
}

private func drawText(
    _ text: String,
    top: CGFloat,
    height: CGFloat,
    fontSize: CGFloat,
    weight: NSFont.Weight,
    textColor: NSColor
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    paragraph.baseWritingDirection = .rightToLeft
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: fontSize, weight: weight),
        .foregroundColor: textColor,
        .paragraphStyle: paragraph
    ]
    (text as NSString).draw(
        in: rectFromTop(55, top, canvasWidth - 110, height),
        withAttributes: attributes
    )
}

private func drawSlide(_ slide: Slide, root: URL, outputDirectory: URL) throws {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(canvasWidth),
        pixelsHigh: Int(canvasHeight),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw NSError(domain: "MadowScreenshot", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not create image canvas"])
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high

    slide.background.setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight)).fill()

    // Soft geometric ornaments keep the set branded without competing with the app screen.
    color(0xe8e5d9).setFill()
    NSBezierPath(ovalIn: rectFromTop(-250, 180, 570, 570)).fill()
    color(0xf0eadb).setFill()
    NSBezierPath(ovalIn: rectFromTop(800, 1370, 470, 470)).fill()
    slide.accent.withAlphaComponent(0.42).setStroke()
    let orbit = NSBezierPath(ovalIn: rectFromTop(126, 318, 828, 1500))
    orbit.lineWidth = 2
    orbit.stroke()

    // Compact identity line.
    let logoURL = root.appendingPathComponent("assets/madow-logo.png")
    if let logo = NSImage(contentsOf: logoURL) {
        logo.draw(in: rectFromTop(78, 53, 72, 72))
    }
    let brandParagraph = NSMutableParagraphStyle()
    brandParagraph.alignment = .left
    let brandAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 30, weight: .bold),
        .foregroundColor: color(0x143c32),
        .paragraphStyle: brandParagraph
    ]
    ("مدعو" as NSString).draw(in: rectFromTop(162, 68, 120, 52), withAttributes: brandAttributes)
    let kickerAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 15, weight: .medium),
        .foregroundColor: slide.accent
    ]
    ("تجربة تطبيق مدعو" as NSString).draw(in: rectFromTop(720, 78, 280, 32), withAttributes: kickerAttributes)

    drawText(slide.title, top: 150, height: 88, fontSize: 55, weight: .bold, textColor: color(0x143c32))
    drawText(slide.subtitle, top: 245, height: 52, fontSize: 25, weight: .regular, textColor: color(0x56635a))

    let sourceURL = root.appendingPathComponent(slide.source)
    guard let screenshot = NSImage(contentsOf: sourceURL) else {
        throw NSError(domain: "MadowScreenshot", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing screenshot: \(sourceURL.path)"])
    }

    let frameWidth: CGFloat = 755
    let frameHeight: CGFloat = 1540
    let frameX = (canvasWidth - frameWidth) / 2
    let frameTop: CGFloat = 345
    let frame = NSBezierPath(roundedRect: rectFromTop(frameX, frameTop, frameWidth, frameHeight), xRadius: 56, yRadius: 56)

    let shadow = NSShadow()
    shadow.shadowColor = color(0x14251f).withAlphaComponent(0.26)
    shadow.shadowBlurRadius = 44
    shadow.shadowOffset = NSSize(width: 0, height: -23)
    shadow.set()
    color(0x132b26).setFill()
    frame.fill()
    NSShadow().set()

    let inset: CGFloat = 24
    let screen = rectFromTop(frameX + inset, frameTop + inset, frameWidth - inset * 2, frameHeight - inset * 2)
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: screen, xRadius: 38, yRadius: 38).addClip()
    screenshot.draw(in: screen)
    NSGraphicsContext.restoreGraphicsState()

    // Fine gold keyline around the device frame.
    slide.accent.withAlphaComponent(0.72).setStroke()
    frame.lineWidth = 2
    frame.stroke()

    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    let filename = "\(slide.id).jpg"
    let outputURL = outputDirectory.appendingPathComponent(filename)
    guard let png = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.9]) else {
        throw NSError(domain: "MadowScreenshot", code: 3, userInfo: [NSLocalizedDescriptionKey: "Could not encode \(filename)"])
    }
    try png.write(to: outputURL, options: .atomic)
    print("Created \(outputURL.path)")
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
let outputDirectory = root.appendingPathComponent("assets/google-play", isDirectory: true)
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

private let slides = [
    Slide(id: "01-home", source: "assets/screenshots/home.png", title: "دعوتك في أجمل صورة", subtitle: "ابدأ رحلتك مع مدعو", background: color(0xf7f4ec), accent: color(0xc39242)),
    Slide(id: "02-occasions", source: "assets/screenshots/occasion-selection.png", title: "كل مناسبة لها حكاية", subtitle: "زفاف · تخرج · مولود · عيد ميلاد", background: color(0xf6f4ee), accent: color(0x9e7c43)),
    Slide(id: "03-templates", source: "assets/screenshots/templates-gallery.png", title: "اختار التصميم اللي يشبه فرحتك", subtitle: "تصفّح قوالب متنوعة لمناسبتك", background: color(0xf8f4ed), accent: color(0xc39242)),
    Slide(id: "04-preview", source: "assets/screenshots/template-selection.png", title: "شوف دعوتك قبل ما تكمل", subtitle: "معاينة واضحة للتصميم المختار", background: color(0xf5f3ed), accent: color(0x9e7c43)),
    Slide(id: "05-packages", source: "assets/screenshots/package-selection.png", title: "اختار الباقة المناسبة", subtitle: "راجع تفاصيل الباقة قبل المتابعة", background: color(0xf7f3ed), accent: color(0xc39242)),
    Slide(id: "06-orders", source: "assets/screenshots/orders-history.png", title: "طلباتك في مكان واحد", subtitle: "ارجع لسجل دعواتك بسهولة", background: color(0xf6f4ee), accent: color(0x9e7c43))
]

for slide in slides {
    try drawSlide(slide, root: root, outputDirectory: outputDirectory)
}
