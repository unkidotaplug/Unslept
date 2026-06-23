import AppKit

// Renders the Unslept app icon: a Blue "Midnight" squircle with a white "UT"
// monogram (After Effects "Ae" style). Output: 1024×1024 PNG.
// Usage: swift make_icon.swift <output.png>

let size: CGFloat = 1024
let img = NSImage(size: NSSize(width: size, height: size))
img.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext

let rect = CGRect(x: 0, y: 0, width: size, height: size)
let radius = size * 0.2237   // macOS squircle corner ratio

// clip to rounded-rect
let clip = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
ctx.addPath(clip)
ctx.clip()

// Blue gradient  #1B2333 → #0E1422  (top-left to bottom-right)
let cs = CGColorSpaceCreateDeviceRGB()
let grad = CGGradient(colorsSpace: cs, colors: [
    CGColor(red: 0x1B/255, green: 0x23/255, blue: 0x33/255, alpha: 1),
    CGColor(red: 0x0E/255, green: 0x14/255, blue: 0x22/255, alpha: 1),
] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: size),
                       end: CGPoint(x: size, y: 0), options: [])

// soft top sheen
let sheen = CGGradient(colorsSpace: cs, colors: [
    CGColor(red: 1, green: 1, blue: 1, alpha: 0.10),
    CGColor(red: 1, green: 1, blue: 1, alpha: 0.0),
] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(sheen, start: CGPoint(x: 0, y: size),
                       end: CGPoint(x: 0, y: size * 0.55), options: [])

// "UT" monogram
let text = "UT"
let para = NSMutableParagraphStyle(); para.alignment = .center
let font = NSFont.systemFont(ofSize: size * 0.40, weight: .heavy)
let attrs: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor.white,
    .paragraphStyle: para,
    .kern: -size * 0.012,
]
let astr = NSAttributedString(string: text, attributes: attrs)
let tsize = astr.size()
// optical vertical centering (caps sit a touch above geometric center)
let x = (size - tsize.width) / 2
let y = (size - tsize.height) / 2 - size * 0.02
astr.draw(at: NSPoint(x: x, y: y))

img.unlockFocus()

let tiff = img.tiffRepresentation!
let rep = NSBitmapImageRep(data: tiff)!
let png = rep.representation(using: .png, properties: [:])!
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon.png"
try! png.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
