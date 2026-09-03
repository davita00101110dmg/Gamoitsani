#!/usr/bin/env swift
//
//  verify-launch-background.swift
//
//  The launch colour is read before any code runs, so it cannot reference `Tokens.surface`
//  and the value lives in two places. Fails if they drift. Run from the repo root.

import Foundation

let colorset = "Gamoitsani2/Resources/Assets.xcassets/LaunchBackground.colorset/Contents.json"
let tokens = "Libraries/Packages/GamoitsaniDesign/Sources/GamoitsaniDesign/Tokens.swift"

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("error: \(message)\n".utf8))
    exit(1)
}

// MARK: - The token

guard let source = try? String(contentsOfFile: tokens, encoding: .utf8) else {
    fail("cannot read \(tokens)")
}
let pattern = #"static let surface = DesignColor\(light: RGB\(0x([0-9A-Fa-f]{6})\), dark: RGB\(0x([0-9A-Fa-f]{6})\)\)"#
guard let regex = try? NSRegularExpression(pattern: pattern),
      let match = regex.firstMatch(in: source, range: NSRange(source.startIndex..., in: source)),
      let lightRange = Range(match.range(at: 1), in: source),
      let darkRange = Range(match.range(at: 2), in: source)
else {
    fail("could not find `Tokens.surface` in \(tokens) — has its declaration changed shape?")
}
let expected = [
    "light": String(source[lightRange]).uppercased(),
    "dark": String(source[darkRange]).uppercased(),
]

// MARK: - The asset

struct Colorset: Decodable {
    struct Entry: Decodable {
        struct Appearance: Decodable { let value: String }
        struct Color: Decodable {
            struct Components: Decodable { let red: String, green: String, blue: String }
            let components: Components
        }
        let appearances: [Appearance]?
        let color: Color
    }
    let colors: [Entry]
}

guard let data = FileManager.default.contents(atPath: colorset),
      let parsed = try? JSONDecoder().decode(Colorset.self, from: data)
else {
    fail("cannot read \(colorset)")
}

var actual: [String: String] = [:]
for entry in parsed.colors {
    // No `appearances` key is the light/any variant.
    let mode = entry.appearances?.first?.value ?? "light"
    let c = entry.color.components
    // "0xF6" -> "F6".
    let hex = [c.red, c.green, c.blue]
        .map { $0.replacingOccurrences(of: "0x", with: "").uppercased() }
        .joined()
    actual[mode] = hex
}

// MARK: - Compare

var problems: [String] = []
for (mode, want) in expected {
    guard let got = actual[mode] else {
        problems.append("\(mode): missing from the colorset")
        continue
    }
    if got != want {
        problems.append("\(mode): colorset has #\(got), Tokens.surface has #\(want)")
    }
}

guard problems.isEmpty else {
    fail("LaunchBackground no longer matches Tokens.surface:\n  " + problems.joined(separator: "\n  "))
}

print("LaunchBackground matches Tokens.surface (light #\(expected["light"]!), dark #\(expected["dark"]!))")
