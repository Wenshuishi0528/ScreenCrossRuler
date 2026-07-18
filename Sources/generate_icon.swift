import AppKit

guard CommandLine.arguments.count == 2 else {
    fputs("usage: generate_icon <output.png>\n", stderr)
    exit(2)
}

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()

let background = NSBezierPath(roundedRect: NSRect(x: 52, y: 52, width: 920, height: 920), xRadius: 210, yRadius: 210)
NSColor(calibratedRed: 0.10, green: 0.12, blue: 0.16, alpha: 1).setFill()
background.fill()

NSColor(calibratedRed: 1.0, green: 0.76, blue: 0.10, alpha: 1).setStroke()
let axes = NSBezierPath()
axes.lineWidth = 28
axes.lineCapStyle = .round
axes.move(to: NSPoint(x: 170, y: 512))
axes.line(to: NSPoint(x: 854, y: 512))
axes.move(to: NSPoint(x: 512, y: 170))
axes.line(to: NSPoint(x: 512, y: 854))
axes.stroke()

for index in -8...8 {
    let offset = CGFloat(index) * 38
    let major = index % 4 == 0
    let tick = major ? CGFloat(38) : CGFloat(22)
    let horizontal = NSBezierPath()
    horizontal.lineWidth = major ? 18 : 12
    horizontal.move(to: NSPoint(x: 512 + offset, y: 512 - tick))
    horizontal.line(to: NSPoint(x: 512 + offset, y: 512 + tick))
    horizontal.stroke()

    let vertical = NSBezierPath()
    vertical.lineWidth = major ? 18 : 12
    vertical.move(to: NSPoint(x: 512 - tick, y: 512 + offset))
    vertical.line(to: NSPoint(x: 512 + tick, y: 512 + offset))
    vertical.stroke()
}

NSColor(calibratedWhite: 0.06, alpha: 1).setFill()
NSBezierPath(ovalIn: NSRect(x: 450, y: 450, width: 124, height: 124)).fill()
NSColor(calibratedRed: 1.0, green: 0.76, blue: 0.10, alpha: 1).setFill()
NSBezierPath(ovalIn: NSRect(x: 470, y: 470, width: 84, height: 84)).fill()

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("could not render icon\n", stderr)
    exit(1)
}

try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
