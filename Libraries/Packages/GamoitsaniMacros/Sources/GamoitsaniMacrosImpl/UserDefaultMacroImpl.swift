//
//  UserDefaultMacroImpl.swift
//  GamoitsaniMacros
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftCompilerPlugin

public struct UserDefaultMacroImpl: AccessorMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
              let binding = varDecl.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
              let type = binding.typeAnnotation?.type else {
            throw MacroError.message("@UserDefault can only be applied to a variable with a type annotation")
        }

        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self),
              arguments.count >= 2,
              let keyExpr = arguments.first?.expression.as(StringLiteralExprSyntax.self),
              let key = keyExpr.segments.first?.as(StringSegmentSyntax.self)?.content.text,
              let defaultValueExpr = arguments.dropFirst().first?.expression else {
            throw MacroError.message("@UserDefault requires a string key and default value")
        }

        return [
            """
            get {
                let defaults = UserDefaults.standard
                let key = "\(raw: key)"
                if let value = defaults.object(forKey: key) as? \(type) {
                    return value
                }
                return \(defaultValueExpr) as! \(type)
            }
            """,
            """
            set {
                let defaults = UserDefaults.standard
                let key = "\(raw: key)"
                defaults.set(newValue, forKey: key)
                defaults.synchronize()
            }
            """
        ]
    }
}

enum MacroError: Error {
    case message(String)
}

@main
struct GamoitsaniMacrosPlugin: CompilerPlugin {
    var providingMacros: [Macro.Type] = [
        UserDefaultMacroImpl.self
    ]
}
