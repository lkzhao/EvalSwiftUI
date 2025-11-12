import SwiftUI

public struct ForEachRuntimeViewBuilder: RuntimeViewBuilder {
    public let typeName = "ForEach"

    public init() {}

    @MainActor
    public func makeSwiftUIView(
        arguments: [RuntimeArgument],
        scope: RuntimeScope
    ) throws -> AnyView {
        guard let dataValue = findDataArgument(in: arguments) else {
            throw RuntimeError.invalidViewArgument("ForEach requires a data collection argument.")
        }

        guard let contentFunction = findContentFunction(in: arguments) else {
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
            return RenderedElement(id: index, view: content)
        }

        return AnyView(ForEach(renderedElements) { element in
            element.view
        })
    }

    private func findDataArgument(in arguments: [RuntimeArgument]) -> RuntimeValue? {
        for argument in arguments {
            if case .function = argument.value {
                continue
            }

            if argument.label == nil || argument.label == "data" {
                return argument.value
            }
        }
        return nil
    }

    private func findContentFunction(in arguments: [RuntimeArgument]) -> Function? {
        for argument in arguments.reversed() {
            if case .function(let function) = argument.value {
                return function
            }
        }
        return nil
    }

    private func makeDataSequence(from value: RuntimeValue) throws -> [RuntimeValue] {
        switch value {
        case .array(let values):
            return values
        default:
            throw RuntimeError.invalidViewArgument("ForEach data must be a range or array expression.")
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
        return AnyView(VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(swiftUIViews.enumerated()), id: \.0) { _, view in
                view
            }
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
}

private struct RenderedElement: Identifiable {
    let id: Int
    let view: AnyView
}
