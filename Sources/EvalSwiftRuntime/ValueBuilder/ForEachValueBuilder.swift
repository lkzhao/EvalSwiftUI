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

        let resolvedValue = try resolveKeyPath(keyPath, on: value)
        guard let hashable = resolvedValue.asAnyHashable else {
            throw RuntimeError.invalidArgument("ForEach(id:) key path must resolve to a Hashable value.")
        }
        return hashable
    }

    private static func resolveKeyPath(
        _ keyPath: RuntimeKeyPath,
        on value: RuntimeValue
    ) throws -> RuntimeValue {
        switch keyPath {
        case .self:
            return value
        case .relative(let components):
            return try apply(components: components, to: value)
        case .absolute(_, let components):
            return try apply(components: components, to: value)
        }
    }

    private static func apply(
        components: [RuntimeKeyPath.Component],
        to initialValue: RuntimeValue
    ) throws -> RuntimeValue {
        var current = initialValue

        for component in components {
            switch component {
            case .property(let name):
                current = try propertyValue(named: name, from: current)
            case .optionalChain:
                guard !isNil(current) else {
                    return .void
                }
            case .forceUnwrap:
                guard !isNil(current) else {
                    throw RuntimeError.invalidArgument("KeyPath force-unwrapped a nil value.")
                }
            case .subscriptIndex(let index):
                current = try subscriptValue(at: index, from: current)
            case .subscriptKey(let key):
                current = try subscriptValue(key: AnyHashable(key), from: current)
            }
        }

        return current
    }

    private static func propertyValue(
        named name: String,
        from value: RuntimeValue
    ) throws -> RuntimeValue {
        switch value {
        case .instance(let instance):
            return try instance.get(name)
        case .type(let type):
            return try type.get(name)
        default:
            throw RuntimeError.invalidArgument("Cannot access member '\(name)' on \(value.valueType).")
        }
    }

    private static func subscriptValue(
        at index: Int,
        from value: RuntimeValue
    ) throws -> RuntimeValue {
        switch value {
        case .array(let values):
            guard values.indices.contains(index) else {
                throw RuntimeError.invalidArgument("KeyPath subscript index \(index) is out of bounds.")
            }
            return values[index]
        case .dictionary(let dictionary):
            return dictionary[AnyHashable(index)] ?? .void
        default:
            throw RuntimeError.invalidArgument("Cannot subscript \(value.valueType).")
        }
    }

    private static func subscriptValue(
        key: AnyHashable,
        from value: RuntimeValue
    ) throws -> RuntimeValue {
        switch value {
        case .dictionary(let dictionary):
            return dictionary[key] ?? .void
        default:
            throw RuntimeError.invalidArgument("Cannot subscript \(value.valueType).")
        }
    }

    private static func isNil(_ value: RuntimeValue) -> Bool {
        if case .void = value {
            return true
        }
        return false
    }
}

private struct RuntimeForEachItem: Identifiable {
    let id: AnyHashable
    let view: AnyView
}
