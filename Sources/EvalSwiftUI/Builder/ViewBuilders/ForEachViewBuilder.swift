import Foundation
import SwiftUI

struct ForEachViewBuilder: SwiftUIViewBuilder {
    let name = "ForEach"

    func makeView(arguments: [ResolvedArgument]) throws -> AnyView {
        guard let dataArgument = arguments.first(where: { argument in
            if case .closure = argument.value { return false }
            return argument.label == nil
        }) else {
            throw SwiftUIEvaluatorError.invalidArguments("ForEach requires an unlabeled data argument.")
        }

        guard let closure = arguments.first(where: { argument in
            argument.value.resolvedClosure != nil
        })?.value.resolvedClosure else {
            throw SwiftUIEvaluatorError.invalidArguments("ForEach requires a trailing content closure.")
        }
        let content = try closure.makeViewContent()

        let parameterName: String
        if let explicit = content.parameters.first {
            guard content.parameters.count == 1 else {
                throw SwiftUIEvaluatorError.invalidArguments("ForEach content must declare exactly one parameter.")
            }
            parameterName = explicit
        } else {
            parameterName = "$0"
        }

        let idStrategy = try makeIdentifierStrategy(from: arguments.first { $0.label == "id" }?.value)
        let sequence = try sequenceValues(from: dataArgument.value)
        let rows = try sequence.enumerated().map { offset, element -> RenderedRow in
            var overrides: ExpressionScope = [:]
            overrides[parameterName] = element
            let identifier = try idStrategy.makeIdentifier(for: element, index: offset)
            let namespace = inlineNamespaceComponents(
                for: identifier,
                closureIdentifier: closure.identifier
            )
            let views = try closure.renderViews(
                using: content,
                overriding: overrides,
                inlineNamespace: namespace
            )
            guard let view = views.first, views.count == 1 else {
                throw SwiftUIEvaluatorError.invalidArguments("ForEach content must return exactly one view.")
            }
            return RenderedRow(id: identifier, view: view)
        }

        return AnyView(
            ForEach(rows) { row in
                row.view
            }
        )
    }

    private func sequenceValues(from value: SwiftValue) throws -> [SwiftValue] {
        switch value {
        case .state(let reference):
            return try sequenceValues(from: reference.read())
        case .binding(let binding):
            return try sequenceValues(from: binding.read())
        case .array(let elements):
            return elements
        case .range(let rangeValue):
            return rangeValue.elements().map { .number(Double($0)) }
        case .optional(let wrapped):
            guard let unwrapped = wrapped?.unwrappedOptional() else {
                throw SwiftUIEvaluatorError.invalidArguments("ForEach data source cannot be nil.")
            }
            return try sequenceValues(from: unwrapped)
        default:
            throw SwiftUIEvaluatorError.invalidArguments("ForEach supports array or range data sources.")
        }
    }

    private func makeIdentifierStrategy(from value: SwiftValue?) throws -> IdentifierStrategy {
        guard let value else { return .index }
        guard case .keyPath(let keyPath) = value else {
            throw SwiftUIEvaluatorError.invalidArguments("id: expects a key path literal such as \\.self.")
        }
        return .keyPath(keyPath)
    }

    private enum IdentifierStrategy {
        case index
        case keyPath(KeyPathValue)

        func makeIdentifier(for element: SwiftValue, index: Int) throws -> AnyHashable {
            switch self {
            case .index:
                return AnyHashable(index)
            case .keyPath(let keyPath):
                let value = try value(at: keyPath.components[...], in: element)
                return try hashableValue(from: value)
            }
        }

        private func hashableValue(from value: SwiftValue) throws -> AnyHashable {
            switch value {
            case .string(let string):
                return AnyHashable(string)
            case .number(let number):
                if number.truncatingRemainder(dividingBy: 1) == 0 {
                    return AnyHashable(Int(number))
                }
                return AnyHashable(number)
            case .bool(let flag):
                return AnyHashable(flag)
            case .optional(let wrapped):
                guard let unwrapped = wrapped?.unwrappedOptional() else {
                    throw SwiftUIEvaluatorError.invalidArguments("id: key path resolved to nil.")
                }
                return try hashableValue(from: unwrapped)
            default:
                throw SwiftUIEvaluatorError.invalidArguments("id: key paths must produce string, number, or boolean values.")
            }
        }

        private func value(at keyPath: ArraySlice<String>, in element: SwiftValue) throws -> SwiftValue {
            guard let head = keyPath.first else {
                return element
            }

            if head == "self" {
                return try value(at: keyPath.dropFirst(), in: element)
            }

            let remaining = keyPath.dropFirst()
            switch element {
            case .dictionary(let dictionary):
                guard let next = dictionary[head] else {
                    throw SwiftUIEvaluatorError.invalidArguments("id: key path component \(head) was not found.")
                }
                return try value(at: remaining, in: next)
            case .optional(let wrapped):
                guard let unwrapped = wrapped?.unwrappedOptional() else {
                    throw SwiftUIEvaluatorError.invalidArguments("id: key path encountered nil while resolving \(head).")
                }
                return try value(at: keyPath, in: unwrapped)
            default:
                throw SwiftUIEvaluatorError.invalidArguments("id: key paths require dictionary elements, received \(element.typeDescription).")
            }
        }
    }

    private struct RenderedRow: Identifiable {
        let id: AnyHashable
        let view: AnyView
    }

    private func inlineNamespaceComponents(
        for identifier: AnyHashable,
        closureIdentifier: String
    ) -> [String] {
        [
            "ForEach",
            sanitizedNamespaceComponent(closureIdentifier),
            "row-\(sanitizedNamespaceComponent(String(describing: identifier)))"
        ]
    }

    private func sanitizedNamespaceComponent(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        let mappedScalars = value.unicodeScalars.map { scalar -> Character in
            if allowed.contains(scalar) {
                return Character(scalar)
            }
            return "_"
        }
        let sanitized = String(mappedScalars).trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        return sanitized.isEmpty ? "value" : sanitized
    }
}
