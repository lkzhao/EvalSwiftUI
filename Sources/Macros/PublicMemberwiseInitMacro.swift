import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum PublicMemberwiseInitMacroError: Error, CustomStringConvertible {
    case onlySupportedOnStructs
    case missingTypeAnnotation(property: String)

    var description: String {
        switch self {
        case .onlySupportedOnStructs:
            return "@PublicMemberwiseInit can only be applied to structs."
        case .missingTypeAnnotation(let property):
            return "Stored property \(property) must have an explicit type annotation."
        }
    }
}

public struct PublicMemberwiseInitMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw PublicMemberwiseInitMacroError.onlySupportedOnStructs
        }

        let properties = try storedProperties(from: structDecl)
        return [makeInitializer(for: properties)]
    }

    private struct StoredProperty {
        var name: String
        var type: String
    }

    private static func storedProperties(from structDecl: StructDeclSyntax) throws -> [StoredProperty] {
        var properties: [StoredProperty] = []

        for member in structDecl.memberBlock.members {
            guard let variableDecl = member.decl.as(VariableDeclSyntax.self) else { continue }
            if variableDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }) {
                continue
            }

            for binding in variableDecl.bindings {
                guard binding.accessorBlock == nil else { continue }
                guard let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }
                guard let typeAnnotation = binding.typeAnnotation?.type.trimmedDescription, !typeAnnotation.isEmpty else {
                    throw PublicMemberwiseInitMacroError.missingTypeAnnotation(property: identifierPattern.identifier.text)
                }
                properties.append(StoredProperty(name: identifierPattern.identifier.text, type: typeAnnotation))
            }
        }

        return properties
    }

    private static func makeInitializer(for properties: [StoredProperty]) -> DeclSyntax {
        let parameterClause = properties
            .map { "\($0.name): \($0.type)" }
            .joined(separator: ", ")

        let assignments = properties
            .map { "        self.\($0.name) = \($0.name)" }
            .joined(separator: "\n")

        if properties.isEmpty {
            return "public init() {}"
        }

        return DeclSyntax(
            """
            public init(\(raw: parameterClause)) {
            \(raw: assignments)
            }
            """
        )
    }
}
