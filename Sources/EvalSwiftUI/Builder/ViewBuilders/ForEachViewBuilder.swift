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

        guard content.parameters.count == 1, let parameterName = content.parameters.first else {
            throw SwiftUIEvaluatorError.invalidArguments("ForEach content must declare exactly one parameter.")
        }

        let sequence = try sequenceValues(from: dataArgument.value)
        let renderedRows = try sequence.enumerated().map { offset, element -> AnyView in
            var overrides: ExpressionScope = [:]
            overrides[parameterName] = element
            let views = try content.renderViews(overriding: overrides)
            guard let view = views.first, views.count == 1 else {
                throw SwiftUIEvaluatorError.invalidArguments("ForEach content must return exactly one view.")
            }
            return view
        }

        return AnyView(
            ForEach(Array(renderedRows.enumerated()), id: \.0) { _, view in
                view
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
}
