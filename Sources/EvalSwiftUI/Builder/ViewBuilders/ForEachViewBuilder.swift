import SwiftUI

struct ForEachViewBuilder: SwiftUIViewBuilder {
    let name = "ForEach"

    func makeView(arguments: [ResolvedArgument]) throws -> AnyView {
        guard let dataArgument = arguments.first(where: { argument in
            if case .viewContent = argument.value { return false }
            return argument.label == nil
        }) else {
            throw SwiftUIEvaluatorError.invalidArguments("ForEach requires an unlabeled data argument.")
        }

        guard let contentArgument = arguments.first(where: { argument in
            if case .viewContent = argument.value { return true }
            return false
        }), case let .viewContent(content) = contentArgument.value else {
            throw SwiftUIEvaluatorError.invalidArguments("ForEach requires a trailing content closure.")
        }

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
            let views = try content.renderViews(overriding: overrides)
            guard let view = views.first, views.count == 1 else {
                throw SwiftUIEvaluatorError.invalidArguments("ForEach content must return exactly one view.")
            }
            let identifier = try idStrategy.makeIdentifier(for: element, index: offset)
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
        guard keyPath.components.count == 1, keyPath.components.first == "self" else {
            throw SwiftUIEvaluatorError.invalidArguments("Only \\.self identifiers are supported today.")
        }
        return .selfValue
    }

    private enum IdentifierStrategy {
        case index
        case selfValue

        func makeIdentifier(for element: SwiftValue, index: Int) throws -> AnyHashable {
            switch self {
            case .index:
                return AnyHashable(index)
            case .selfValue:
                return try hashableValue(from: element)
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
                throw SwiftUIEvaluatorError.invalidArguments("id: \\.self requires string, number, or boolean elements.")
            }
        }
    }

    private struct RenderedRow: Identifiable {
        let id: AnyHashable
        let view: AnyView
    }
}
