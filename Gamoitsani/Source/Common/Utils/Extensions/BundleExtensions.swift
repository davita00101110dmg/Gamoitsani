//
//  BundleExtensions.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 23/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation

extension Bundle {

    static func forClass(_ `class`: AnyClass) -> Bundle? {
        if let bundle = forClass(`class`, in: Bundle.allBundles.map { $0.bundleURL }) {
            return bundle
        }
        
        let candidates = [
            // Bundle should be present here when the package is linked into an App.
            Bundle.main.resourceURL,
            
            // Bundle should be present here when the package is linked into a framework.
            Bundle(for: `class`).resourceURL,
            
            // For command-line tools.
            Bundle.main.bundleURL
        ].compactMap { try? $0?.resourceValues(forKeys: [.canonicalPathKey]).canonicalPath }
        
        for candidate in candidates {
            guard let files = try? FileManager.default.contentsOfDirectory(atPath: candidate), !files.isEmpty else {
                continue
            }
            
            let URLs = files.compactMap {
                URL(fileURLWithPath: candidate, isDirectory: true).appendingPathComponent($0)
            }.filter { $0.pathExtension == "bundle" }
            
            if let bundle = forClass(`class`, in: URLs) {
                return bundle
            }
        }
        return nil
    }
    
    private static func forClass(_ `class`: AnyClass, in URLs: [URL]) -> Bundle? {
        let targetName = String(reflecting: `class`).split(separator: ".").first.flatMap { String($0) }
        let targetNameParts = targetName?.split(separator: "_") ?? []
        
        if targetNameParts.isEmpty { return nil }
        
        let subRegexp = targetNameParts.joined(separator: "[._]+")
        let regexp = "(_\(subRegexp)$)|(^\(subRegexp)$)"
        
        let url = URLs.first {
            $0.deletingPathExtension().lastPathComponent.range(of: regexp, options: .regularExpression) != nil
        }
        
        return url.flatMap { Bundle(url: $0) }
    }
}
