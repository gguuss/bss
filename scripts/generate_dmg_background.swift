import AppKit

let width: CGFloat = 600
let height: CGFloat = 400
let scale: CGFloat = 2.0 // Retina

let imgSize = NSSize(width: width * scale, height: height * scale)
let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(imgSize.width),
    pixelsHigh: Int(imgSize.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!

rep.size = NSSize(width: width, height: height)

NSGraphicsContext.saveGraphicsState()
let context = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = context

let cgContext = context.cgContext

// 1. Background Gradient (Modern Apple translucent gray / silver gradient)
let colorSpace = CGColorSpaceCreateDeviceRGB()
let gradientColors = [
    NSColor(calibratedRed: 0.94, green: 0.95, blue: 0.97, alpha: 1.0).cgColor,
    NSColor(calibratedRed: 0.88, green: 0.90, blue: 0.93, alpha: 1.0).cgColor
] as CFArray
let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: [0.0, 1.0])!
cgContext.drawLinearGradient(gradient, start: CGPoint(x: 0, y: height), end: CGPoint(x: 0, y: 0), options: [])

// 2. Title Header
let paragraphStyle = NSMutableParagraphStyle()
paragraphStyle.alignment = .center

let titleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 22, weight: .bold),
    .foregroundColor: NSColor(calibratedWhite: 0.15, alpha: 1.0),
    .paragraphStyle: paragraphStyle
]
let title = "Install Better Screen Shot"
title.draw(in: NSRect(x: 0, y: height - 55, width: width, height: 30), withAttributes: titleAttributes)

let subtitleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 13, weight: .medium),
    .foregroundColor: NSColor(calibratedWhite: 0.45, alpha: 1.0),
    .paragraphStyle: paragraphStyle
]
let subtitle = "Drag the app into your Applications folder"
subtitle.draw(in: NSRect(x: 0, y: height - 80, width: width, height: 20), withAttributes: subtitleAttributes)

// 3. Arrow pointing from left (140, 190) to right (460, 190)
// AppKit origin is bottom-left. create-dmg (140, 190) from top-left is:
// y = 400 - 190 = 210 in AppKit coordinates
let startX: CGFloat = 220
let endX: CGFloat = 380
let arrowY: CGFloat = 210

let arrowPath = NSBezierPath()
arrowPath.move(to: NSPoint(x: startX, y: arrowY))
arrowPath.line(to: NSPoint(x: endX, y: arrowY))
arrowPath.lineWidth = 4.0
arrowPath.lineCapStyle = .round
NSColor.systemBlue.withAlphaComponent(0.6).setStroke()
arrowPath.stroke()

// Arrow Head
let headPath = NSBezierPath()
headPath.move(to: NSPoint(x: endX - 14, y: arrowY + 10))
headPath.line(to: NSPoint(x: endX + 4, y: arrowY))
headPath.line(to: NSPoint(x: endX - 14, y: arrowY - 10))
headPath.lineJoinStyle = .round
headPath.lineWidth = 4.0
headPath.lineCapStyle = .round
headPath.stroke()

// Footer hint
let footerAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 11, weight: .regular),
    .foregroundColor: NSColor(calibratedWhite: 0.55, alpha: 1.0),
    .paragraphStyle: paragraphStyle
]
let footer = "Tip: On first launch, right-click the app in Applications and choose Open."
footer.draw(in: NSRect(x: 0, y: 20, width: width, height: 18), withAttributes: footerAttributes)

NSGraphicsContext.restoreGraphicsState()

if let pngData = rep.representation(using: .png, properties: [:]) {
    let outputURL = URL(fileURLWithPath: "Assets/dmg_background.png")
    try! pngData.write(to: outputURL)
    print("Generated Assets/dmg_background.png successfully")
}
