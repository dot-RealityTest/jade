import AppKit

struct IconColor {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat

    var nsColor: NSColor {
        NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha)
    }

    init(_ hex: Int, alpha: CGFloat = 1) {
        red = CGFloat((hex >> 16) & 0xff) / 255
        green = CGFloat((hex >> 8) & 0xff) / 255
        blue = CGFloat(hex & 0xff) / 255
        self.alpha = alpha
    }
}

let rootURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let macIconURL = rootURL.appendingPathComponent("Muxy/Resources/Assets.xcassets/AppIcon.appiconset")
let mobileIconURL = rootURL.appendingPathComponent("MuxyMobile/Resources/Assets.xcassets/AppIcon.appiconset")

func path(_ body: (NSBezierPath) -> Void) -> NSBezierPath {
    let path = NSBezierPath()
    body(path)
    return path
}

func drawGradient(in rect: CGRect, colors: [NSColor]) {
    NSGradient(colors: colors)?.draw(in: rect, angle: 90)
}

func fill(_ path: NSBezierPath, _ color: NSColor) {
    color.setFill()
    path.fill()
}

func stroke(_ path: NSBezierPath, _ color: NSColor, width: CGFloat) {
    color.setStroke()
    path.lineWidth = width
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    path.stroke()
}

func rounded(_ rect: CGRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func oval(_ rect: CGRect) -> NSBezierPath {
    NSBezierPath(ovalIn: rect)
}

func drawHeart(center: CGPoint, size: CGFloat, fillColor: NSColor, strokeColor: NSColor, strokeWidth: CGFloat) {
    let x = center.x
    let y = center.y
    let s = size
    let heart = path { p in
        p.move(to: CGPoint(x: x, y: y - s * 0.32))
        p.curve(
            to: CGPoint(x: x - s * 0.5, y: y + s * 0.12),
            controlPoint1: CGPoint(x: x - s * 0.48, y: y - s * 0.02),
            controlPoint2: CGPoint(x: x - s * 0.62, y: y + s * 0.1)
        )
        p.curve(
            to: CGPoint(x: x, y: y + s * 0.44),
            controlPoint1: CGPoint(x: x - s * 0.34, y: y + s * 0.42),
            controlPoint2: CGPoint(x: x - s * 0.08, y: y + s * 0.42)
        )
        p.curve(
            to: CGPoint(x: x + s * 0.5, y: y + s * 0.12),
            controlPoint1: CGPoint(x: x + s * 0.08, y: y + s * 0.42),
            controlPoint2: CGPoint(x: x + s * 0.34, y: y + s * 0.42)
        )
        p.curve(
            to: CGPoint(x: x, y: y - s * 0.32),
            controlPoint1: CGPoint(x: x + s * 0.62, y: y + s * 0.1),
            controlPoint2: CGPoint(x: x + s * 0.48, y: y - s * 0.02)
        )
        p.close()
    }
    fill(heart, fillColor)
    stroke(heart, strokeColor, width: strokeWidth)
}

func drawKey(rect: CGRect, scale: CGFloat) {
    fill(rounded(rect, radius: rect.height * 0.28), IconColor(0xffc5d7).nsColor)
    stroke(rounded(rect.insetBy(dx: scale * 1.5, dy: scale * 1.5), radius: rect.height * 0.22), IconColor(0xffffff, alpha: 0.28).nsColor, width: scale * 1.8)
}

func drawIcon(size: CGFloat) throws -> NSBitmapImageRep {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size),
        pixelsHigh: Int(size),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "IconGeneration", code: 1)
    }
    bitmap.size = CGSize(width: size, height: size)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

    let scale = size / 1024
    let canvas = CGRect(x: 0, y: 0, width: size, height: size)

    drawGradient(
        in: canvas,
        colors: [
            IconColor(0xf9bfd1).nsColor,
            IconColor(0xd37f9d).nsColor
        ]
    )

    fill(oval(CGRect(x: 140 * scale, y: 106 * scale, width: 744 * scale, height: 184 * scale)), IconColor(0xbb5170, alpha: 0.12).nsColor)

    let keyboard = CGRect(x: 82 * scale, y: 92 * scale, width: 860 * scale, height: 312 * scale)
    fill(rounded(keyboard, radius: 84 * scale), IconColor(0x61d4d7).nsColor)
    stroke(rounded(keyboard.insetBy(dx: 16 * scale, dy: 16 * scale), radius: 68 * scale), IconColor(0xffffff, alpha: 0.25).nsColor, width: 10 * scale)
    stroke(rounded(keyboard, radius: 84 * scale), IconColor(0x632b25).nsColor, width: 12 * scale)

    let keyWidth = 72 * scale
    let keyHeight = 40 * scale
    for row in 0 ..< 3 {
        let y = (318 - CGFloat(row) * 56) * scale
        let offset = row == 1 ? 32 * scale : 0
        for col in 0 ..< 9 {
            let x = 172 * scale + offset + CGFloat(col) * 78 * scale
            drawKey(rect: CGRect(x: x, y: y, width: keyWidth, height: keyHeight), scale: scale)
        }
    }
    drawKey(rect: CGRect(x: 300 * scale, y: 154 * scale, width: 424 * scale, height: 46 * scale), scale: scale)

    let head = CGRect(x: 246 * scale, y: 344 * scale, width: 532 * scale, height: 520 * scale)
    fill(oval(head), IconColor(0xf3cfc0).nsColor)
    stroke(oval(head), IconColor(0x63301e).nsColor, width: 12 * scale)

    let hairTop = path { p in
        p.move(to: CGPoint(x: 282 * scale, y: 686 * scale))
        p.curve(
            to: CGPoint(x: 690 * scale, y: 850 * scale),
            controlPoint1: CGPoint(x: 356 * scale, y: 878 * scale),
            controlPoint2: CGPoint(x: 630 * scale, y: 898 * scale)
        )
        p.curve(
            to: CGPoint(x: 740 * scale, y: 690 * scale),
            controlPoint1: CGPoint(x: 744 * scale, y: 806 * scale),
            controlPoint2: CGPoint(x: 758 * scale, y: 742 * scale)
        )
        p.curve(
            to: CGPoint(x: 282 * scale, y: 686 * scale),
            controlPoint1: CGPoint(x: 616 * scale, y: 650 * scale),
            controlPoint2: CGPoint(x: 432 * scale, y: 626 * scale)
        )
        p.close()
    }
    fill(hairTop, IconColor(0xf2d7a8).nsColor)
    stroke(hairTop, IconColor(0x63301e).nsColor, width: 10 * scale)

    let leftHair = path { p in
        p.move(to: CGPoint(x: 272 * scale, y: 714 * scale))
        p.curve(
            to: CGPoint(x: 230 * scale, y: 294 * scale),
            controlPoint1: CGPoint(x: 192 * scale, y: 608 * scale),
            controlPoint2: CGPoint(x: 196 * scale, y: 432 * scale)
        )
        p.curve(
            to: CGPoint(x: 334 * scale, y: 406 * scale),
            controlPoint1: CGPoint(x: 266 * scale, y: 322 * scale),
            controlPoint2: CGPoint(x: 308 * scale, y: 356 * scale)
        )
        p.curve(
            to: CGPoint(x: 272 * scale, y: 714 * scale),
            controlPoint1: CGPoint(x: 338 * scale, y: 508 * scale),
            controlPoint2: CGPoint(x: 322 * scale, y: 634 * scale)
        )
        p.close()
    }
    let rightHair = path { p in
        p.move(to: CGPoint(x: 752 * scale, y: 714 * scale))
        p.curve(
            to: CGPoint(x: 794 * scale, y: 294 * scale),
            controlPoint1: CGPoint(x: 832 * scale, y: 608 * scale),
            controlPoint2: CGPoint(x: 828 * scale, y: 432 * scale)
        )
        p.curve(
            to: CGPoint(x: 690 * scale, y: 406 * scale),
            controlPoint1: CGPoint(x: 758 * scale, y: 322 * scale),
            controlPoint2: CGPoint(x: 716 * scale, y: 356 * scale)
        )
        p.curve(
            to: CGPoint(x: 752 * scale, y: 714 * scale),
            controlPoint1: CGPoint(x: 686 * scale, y: 508 * scale),
            controlPoint2: CGPoint(x: 702 * scale, y: 634 * scale)
        )
        p.close()
    }
    fill(leftHair, IconColor(0x64d9dc).nsColor)
    fill(rightHair, IconColor(0x64d9dc).nsColor)
    stroke(leftHair, IconColor(0x63301e).nsColor, width: 10 * scale)
    stroke(rightHair, IconColor(0x63301e).nsColor, width: 10 * scale)

    let leftEye = CGRect(x: 344 * scale, y: 534 * scale, width: 116 * scale, height: 74 * scale)
    let rightEye = CGRect(x: 564 * scale, y: 534 * scale, width: 116 * scale, height: 74 * scale)
    for eye in [leftEye, rightEye] {
        fill(oval(eye), IconColor(0x5bdceb).nsColor)
        stroke(oval(eye), IconColor(0x63301e).nsColor, width: 8 * scale)
        fill(oval(eye.insetBy(dx: 24 * scale, dy: 12 * scale).offsetBy(dx: -6 * scale, dy: 10 * scale)), IconColor(0x573322).nsColor)
        fill(oval(CGRect(x: eye.maxX - 36 * scale, y: eye.maxY - 22 * scale, width: 18 * scale, height: 18 * scale)), NSColor.white)
    }

    stroke(path { p in
        p.move(to: CGPoint(x: 484 * scale, y: 624 * scale))
        p.curve(
            to: CGPoint(x: 540 * scale, y: 624 * scale),
            controlPoint1: CGPoint(x: 500 * scale, y: 650 * scale),
            controlPoint2: CGPoint(x: 524 * scale, y: 650 * scale)
        )
    }, IconColor(0xa95050).nsColor, width: 7 * scale)

    let smile = path { p in
        p.move(to: CGPoint(x: 402 * scale, y: 494 * scale))
        p.curve(
            to: CGPoint(x: 622 * scale, y: 494 * scale),
            controlPoint1: CGPoint(x: 442 * scale, y: 380 * scale),
            controlPoint2: CGPoint(x: 582 * scale, y: 380 * scale)
        )
        p.curve(
            to: CGPoint(x: 402 * scale, y: 494 * scale),
            controlPoint1: CGPoint(x: 606 * scale, y: 438 * scale),
            controlPoint2: CGPoint(x: 418 * scale, y: 438 * scale)
        )
        p.close()
    }
    fill(smile, IconColor(0xb94f68).nsColor)
    stroke(smile, IconColor(0x63301e).nsColor, width: 10 * scale)
    fill(rounded(CGRect(x: 448 * scale, y: 482 * scale, width: 128 * scale, height: 34 * scale), radius: 16 * scale), NSColor.white)

    fill(oval(CGRect(x: 306 * scale, y: 448 * scale, width: 106 * scale, height: 54 * scale)), IconColor(0xff9fb4, alpha: 0.45).nsColor)
    fill(oval(CGRect(x: 612 * scale, y: 448 * scale, width: 106 * scale, height: 54 * scale)), IconColor(0xff9fb4, alpha: 0.45).nsColor)

    let leftHand = CGRect(x: 292 * scale, y: 340 * scale, width: 100 * scale, height: 102 * scale)
    let rightHand = CGRect(x: 632 * scale, y: 340 * scale, width: 100 * scale, height: 102 * scale)
    fill(oval(leftHand), IconColor(0xf3cfc0).nsColor)
    fill(oval(rightHand), IconColor(0xf3cfc0).nsColor)
    stroke(oval(leftHand), IconColor(0x63301e).nsColor, width: 9 * scale)
    stroke(oval(rightHand), IconColor(0x63301e).nsColor, width: 9 * scale)

    drawHeart(
        center: CGPoint(x: 512 * scale, y: 224 * scale),
        size: 112 * scale,
        fillColor: IconColor(0xff91ad).nsColor,
        strokeColor: IconColor(0x8a3a43).nsColor,
        strokeWidth: 8 * scale
    )
    fill(oval(CGRect(x: 470 * scale, y: 246 * scale, width: 42 * scale, height: 18 * scale)), IconColor(0xffffff, alpha: 0.35).nsColor)

    NSGraphicsContext.restoreGraphicsState()
    return bitmap
}

func write(_ bitmap: NSBitmapImageRep, to url: URL) throws {
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "IconGeneration", code: 1)
    }
    try data.write(to: url)
}

func writeIcon(_ pixelSize: Int, name: String, to directory: URL) throws {
    try write(try drawIcon(size: CGFloat(pixelSize)), to: directory.appendingPathComponent(name))
}

try FileManager.default.createDirectory(at: macIconURL, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: mobileIconURL, withIntermediateDirectories: true)

let macSizes: [(Int, String)] = [
    (16, "icon_16.png"),
    (32, "icon_16@2x.png"),
    (32, "icon_32.png"),
    (64, "icon_32@2x.png"),
    (128, "icon_128.png"),
    (256, "icon_128@2x.png"),
    (256, "icon_256.png"),
    (512, "icon_256@2x.png"),
    (512, "icon_512.png"),
    (1024, "icon_512@2x.png")
]

for icon in macSizes {
    try writeIcon(icon.0, name: icon.1, to: macIconURL)
}

try writeIcon(1024, name: "AppIcon-1024.png", to: mobileIconURL)
print("Generated Muxy app icons")
