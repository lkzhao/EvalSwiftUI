import SwiftUI

public struct ForEachRuntimeViewBuilder: RuntimeViewBuilder {
    public let typeName = "ForEach"

    public init() {}

    @MainActor
    public func makeSwiftUIView(
        arguments: [RuntimeArgument],
        scope: RuntimeScope
    ) throws -> AnyView {
        var dataValue: RuntimeValue?
        var contentFunction: Function?
        var idStrategy: IDStrategy = .index

        for argument in arguments {
            if argument.label == "id" {
                idStrategy = try strategy(from: argument.value)
                continue
            }

            if case .function(let function) = argument.value {
                contentFunction = function
                continue
            }

            if dataValue == nil && (argument.label == nil || argument.label == "data") {
                dataValue = argument.value
            }
        }

        guard let dataValue else {
            throw RuntimeError.invalidViewArgument("ForEach requires a data collection argument.")
        }

        guard let contentFunction else {
            throw RuntimeError.invalidViewArgument("ForEach requires a content closure.")
        }

        guard contentFunction.parameters.count <= 2 else {
            throw RuntimeError.invalidViewArgument("ForEach content closures support at most two parameters (element and optional index).")
        }

        let dataValues = try makeDataSequence(from: dataValue)
        let renderedElements = try dataValues.enumerated().map { (index, element) in
            let content = try renderContent(
                for: element,
                index: index,
                function: contentFunction,
                scope: scope
            )
            let elementID = makeElementIdentifier(
                element: element,
                index: index,
                strategy: idStrategy
            )
            return RenderedElement(id: elementID, view: content)
        }

        return AnyView(ForEach(renderedElements) { element in
            element.view
        })
    }

    private func makeDataSequence(from value: RuntimeValue) throws -> [RuntimeValue] {
        switch value {
        case .array(let values):
            return values
        default:
            throw RuntimeError.invalidViewArgument("ForEach data must be a range or array expression.")
        }
    }

    private func strategy(from value: RuntimeValue) throws -> IDStrategy {
        switch value {
        case .keyPath(let keyPath) where keyPath == .self:
            return .element
        default:
            throw RuntimeError.invalidViewArgument("ForEach currently only supports id: \\.self")
        }
    }

    @MainActor
    private func renderContent(
        for element: RuntimeValue,
        index: Int,
        function: Function,
        scope: RuntimeScope
    ) throws -> AnyView {
        let arguments = makeContentArguments(
            for: element,
            index: index,
            function: function
        )
        let runtimeViews = try function.renderRuntimeViews(arguments: arguments, scope: scope)
        guard !runtimeViews.isEmpty else {
            throw RuntimeError.invalidViewArgument("ForEach content closures must produce at least one view.")
        }

        if runtimeViews.count == 1 {
            return try runtimeViews[0].makeSwiftUIView(scope: scope)
        }

        let swiftUIViews = try runtimeViews.map { try $0.makeSwiftUIView(scope: scope) }
        return AnyView(ForEach(Array(swiftUIViews.enumerated()), id: \.0) { _, view in
            view
        })
    }

    private func makeContentArguments(
        for element: RuntimeValue,
        index: Int,
        function: Function
    ) -> [RuntimeArgument] {
        guard !function.parameters.isEmpty else { return [] }

        var arguments: [RuntimeArgument] = []
        let firstParameter = function.parameters[0]
        arguments.append(RuntimeArgument(label: firstParameter.label, value: element))

        if function.parameters.count > 1 {
            let second = function.parameters[1]
            arguments.append(RuntimeArgument(label: second.label, value: .int(index)))
        }

        return arguments
    }

    private func makeElementIdentifier(
        element: RuntimeValue,
        index: Int,
        strategy: IDStrategy
    ) -> String {
        switch strategy {
        case .index:
            return "index-\(index)"
        case .element:
            return "self-\(elementIdentifierComponent(from: element, fallback: index))"
        }
    }

    private func elementIdentifierComponent(from value: RuntimeValue, fallback: Int) -> String {
        switch value {
        case .int(let number):
            return String(number)
        case .double(let number):
            return String(number)
        case .string(let string):
            return string
        case .bool(let bool):
            return String(bool)
        default:
            return String(fallback)
        }
    }
}

private struct RenderedElement: Identifiable {
    let id: String
    let view: AnyView
}

private enum IDStrategy {
    case index
    case element
}
