import SwiftUI

public struct ForEachValueBuilder: RuntimeValueBuilder {
    public let name = "ForEach"

    public let definitions: [RuntimeBuilderDefinition]

    public init() {
        definitions = [
            Self.makeDefinition(includeID: false),
            Self.makeDefinition(includeID: true)
        ]
    }

    private static func makeDefinition(includeID: Bool) -> RuntimeBuilderDefinition {
        var parameters: [RuntimeParameter] = [
            RuntimeParameter(label: "_", name: "data", type: "[Any]")
        ]
        if includeID {
            parameters.append(RuntimeParameter(label: "id", name: "id", type: "KeyPath"))
        }
        parameters.append(RuntimeParameter(label: "_", name: "content", type: "(Any) -> Content"))

        return RuntimeBuilderDefinition(
            parameters: parameters,
            build: { arguments, _ in
                let dataValue = arguments.value(named: "data")
                let idKeyPath = includeID ? arguments.value(named: "id")?.asKeyPath : nil
                let contentFunction = arguments.value(named: "content")?.asFunction
                return try buildForEach(data: dataValue, idKeyPath: idKeyPath, contentFunction: contentFunction)
            }
        )
    }

    private static func buildForEach(
        data: RuntimeValue?,
        idKeyPath: RuntimeKeyPath?,
        contentFunction: RuntimeFunction?
    ) throws -> RuntimeValue {
        guard let sequence = data?.asArray else {
            throw RuntimeError.invalidArgument("ForEach requires an array or range as its data source.")
        }
        guard let contentFunction else {
            throw RuntimeError.invalidArgument("ForEach requires a content closure.")
        }

        let items = try sequence.enumerated().map { index, element -> RuntimeForEachItem in
            let identifier = try makeIdentifier(for: element, keyPath: idKeyPath, fallbackIndex: index)
            let renderedView = try makeContentView(
                function: contentFunction,
                element: element,
                index: index
            )
            return RuntimeForEachItem(id: identifier, view: renderedView)
        }

        let forEachView = ForEach(items) { item in
            item.view
        }
        return .swiftUI(.view(AnyView(forEachView)))
    }

    private static func makeContentView(
        function: RuntimeFunction,
        element: RuntimeValue,
        index: Int
    ) throws -> AnyView {
        let arguments = makeContentArguments(function: function, element: element, index: index)
        let renderedValues = try function.renderRuntimeViews(arguments: arguments)
        let views = renderedValues.compactMap { $0.asSwiftUIView }
        guard !views.isEmpty else {
            throw RuntimeError.invalidArgument("ForEach content closure must return a SwiftUI view.")
        }

        return AnyView(ForEach(Array(views.enumerated()), id: \.0) { _, view in
            view
        })
    }

    private static func makeContentArguments(
        function: RuntimeFunction,
        element: RuntimeValue,
        index: Int
    ) -> [RuntimeArgument] {
        if let firstParameter = function.parameters.first {
            return [RuntimeArgument(name: firstParameter.name, value: element)]
        } else {
            return [RuntimeArgument(name: "$0", value: element)]
        }
    }

    private static func makeIdentifier(
        for value: RuntimeValue,
        keyPath: RuntimeKeyPath?,
        fallbackIndex: Int
    ) throws -> AnyHashable {
        guard let keyPath else {
            return AnyHashable(fallbackIndex)
        }

        switch keyPath {
        case .self:
            guard let hashable = hashableValue(from: value) else {
                throw RuntimeError.invalidArgument("ForEach(id: \\.self) requires Hashable elements.")
            }
            return hashable
        }
    }

    private static func hashableValue(from value: RuntimeValue) -> AnyHashable? {
        switch value {
        case .int(let int):
            return AnyHashable(int)
        case .double(let double):
            return AnyHashable(double)
        case .string(let string):
            return AnyHashable(string)
        case .bool(let bool):
            return AnyHashable(bool)
        default:
            return nil
        }
    }
}

private struct RuntimeForEachItem: Identifiable {
    let id: AnyHashable
    let view: AnyView
}
