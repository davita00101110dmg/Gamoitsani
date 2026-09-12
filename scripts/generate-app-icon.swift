#!/usr/bin/env swift
//
//  generate-app-icon.swift
//
//  Redraws the app icon into the asset catalogue. Generated rather than hand-exported so
//  it cannot drift from GamoitsaniDesign.AppMark. Run from the repo root.
//
import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Mirrors GamoitsaniDesign.AppMark. No field corner radius on purpose — iOS masks icons
// itself, and baking one in shows as a dark halo at the corners.
let side: CGFloat = 1024
// Larger than in AppMark: the squircle mask eats the corners, and the unscaled ratios
// leave the mark looking lost on the home screen.
let iconScale: CGFloat = 1.25
let cardW = side * 372.0 / 1024.0 * iconScale
let cardH = side * 504.0 / 1024.0 * iconScale
let radius = cardW * 44.0 / 372.0
let fanAngle: CGFloat = 19 * .pi / 180
let glyphSize = cardH * 330.0 / 504.0
let faceLift = side * 0.0098

func rgb(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

let space = CGColorSpace(name: CGColorSpace.sRGB)!
guard let ctx = CGContext(data: nil, width: Int(side), height: Int(side), bitsPerComponent: 8,
                          bytesPerRow: 0, space: space,
                          bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
    fatalError("could not create context")
}

ctx.setFillColor(rgb(0x10032E))
ctx.fill(CGRect(x: 0, y: 0, width: side, height: side))

func card(fill: UInt32, rotation: CGFloat, dy: CGFloat) {
    ctx.saveGState()
    ctx.translateBy(x: side / 2, y: side / 2 + dy)
    ctx.rotate(by: rotation)
    ctx.addPath(CGPath(roundedRect: CGRect(x: -cardW / 2, y: -cardH / 2, width: cardW, height: cardH),
                       cornerWidth: radius, cornerHeight: radius, transform: nil))
    ctx.setFillColor(rgb(fill))
    ctx.fillPath()
    ctx.restoreGState()
}

card(fill: 0x4756A6, rotation: -fanAngle, dy: 0)
card(fill: 0xFF3D93, rotation: fanAngle, dy: 0)
card(fill: 0xFFFCF5, rotation: 0, dy: faceLift)

// The bundled display face, at the black weight Typography asks for.
let fontURL = URL(fileURLWithPath:
    "Libraries/Packages/GamoitsaniDesign/Sources/GamoitsaniDesign/Resources/NotoSansGeorgian.ttf")
guard CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil) else {
    fatalError("could not register font")
}
// Variable font: the family alone yields the 400 default, but Typography draws the mark
// at .black, so the wght axis is set explicitly.
let desc = CTFontDescriptorCreateWithAttributes([
    kCTFontNameAttribute: "Noto Sans Georgian",
    kCTFontVariationAttribute: [0x77676874: 900],
] as CFDictionary)
let font = CTFontCreateWithFontDescriptor(desc, glyphSize, nil)

let attrs = [kCTFontAttributeName: font, kCTForegroundColorAttributeName: rgb(0x170640)] as CFDictionary
let line = CTLineCreateWithAttributedString(CFAttributedStringCreate(nil, "?" as CFString, attrs)!)
// Path bounds, not line bounds — centring the em box instead sits visibly high.
let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)

ctx.textPosition = CGPoint(x: side / 2 - bounds.midX, y: side / 2 + faceLift - bounds.midY)
CTLineDraw(line, ctx)

let output = "Gamoitsani/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon1024.png"
guard let image = ctx.makeImage(),
      let dest = CGImageDestinationCreateWithURL(
        URL(fileURLWithPath: output) as CFURL, UTType.png.identifier as CFString, 1, nil)
else { fatalError("could not write") }
CGImageDestinationAddImage(dest, image, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("could not finalize") }
print("wrote \(output)")
