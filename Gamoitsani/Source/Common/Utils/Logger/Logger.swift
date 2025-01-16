//
//  Logger.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 05/01/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import Foundation

/// Represents different logging levels with associated symbols and colors
enum LogLevel: String {
    case debug = "📝"
    case info = "ℹ️"
    case warning = "⚠️"
    case error = "❌"
    case fatal = "💣"
}

#if DEBUG
/// Main logging class with thread-safe singleton access
final class Logger {
    static let shared = Logger()
    private let queue = DispatchQueue(label: "com.gamoitsani.logger")
    
    private init() {}
    
    func log(
        _ level: LogLevel,
        _ message: Any,
        function: String = #function,
        file: String = #file
    ) {
        queue.async {
            let threadName = Thread.current.isMainThread ? "main" : "background"
            let functionName = function.components(separatedBy: "(").first ?? function
            let filename = (file as NSString).lastPathComponent
            
            let formattedMessage = "Logger - \(level.rawValue) \(message) [\(threadName) thread] [function - \(functionName)] [filename - \(filename)]"
            print(formattedMessage)
        }
    }
}

/// Global logging function for DEBUG builds
func log(
    _ level: LogLevel = .debug,
    _ message: Any,
    function: String = #function,
    file: String = #file
) {
    Logger.shared.log(level, message, function: function, file: file)
}

#else
/// Empty logging implementation for RELEASE builds
func log(
    _ level: LogLevel = .debug,
    _ message: Any,
    function: String = #function,
    file: String = #file
) {
    
}
#endif
