// SPDX-License-Identifier: GPL-3.0-or-later
//
// Unslept — keep your Mac awake while AI codes, even with the lid closed.
// Copyright (C) 2026 unkidotaplug
//
// This program is free software: you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option)
// any later version. Distributed WITHOUT ANY WARRANTY. See the GNU General
// Public License <https://www.gnu.org/licenses/> for more details.
//

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

// Solid base — user-picked colour  R12 G32 B40  (#0C2028)
let cs = CGColorSpaceCreateDeviceRGB()
ctx.setFillColor(CGColor(red: 12/255, green: 32/255, blue: 40/255, alpha: 1))
ctx.fill(rect)

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
let font = NSFont.systemFont(ofSize: size * 0.56, weight: .heavy)
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
