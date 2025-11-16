import SwiftUI

public final class RuntimeInstance: RuntimeScope {
    enum Content {
        case view
        case modifier(RuntimeModifierDefinition, [RuntimeArgument])
    }
    private var content: Content
    private let computedBindingNames: Set<String>

    public var parent: RuntimeScope?
    public var storage: RuntimeScopeStorage = [:] {
        didSet {
            mutationHandler?()
        }
    }
    var mutationHandler: (() -> Void)?

    public init(parent: RuntimeScope? = nil, computedBindings: Set<String> = []) {
        self.parent = parent
        self.content = .view
        self.computedBindingNames = computedBindings
    }

    public init(
        modifierDefinition: RuntimeModifierDefinition,
        arguments: [RuntimeArgument],
        parent: RuntimeInstance
    ) {
        self.parent = parent
        self.content = .modifier(modifierDefinition, arguments)
        self.computedBindingNames = parent.computedBindingNames
    }
}

extension RuntimeInstance {
    private func rawGet(_ name: String) throws -> RuntimeValue {
        if let valueHolder = storage[name], valueHolder.count == 1, let value = valueHolder.values.first {
            return value
        }
        if let valueHolder = storage[name], valueHolder.count > 1 {
            throw RuntimeError.ambiguousIdentifier(name)
        }
        if let parent {
            return try parent.get(name)
        }
        throw RuntimeError.unknownIdentifier(name)
    }

    public func get(_ name: String) throws -> RuntimeValue {
        let value = try rawGet(name)
        guard computedBindingNames.contains(name), case .function(let function) = value else {
            return value
        }
        return try function.invoke() ?? .void
    }

    public func getFunction(_ name: String) throws -> RuntimeFunction {
        let value = try rawGet(name)
        guard case .function(let function) = value else {
            throw RuntimeError.unknownFunction(name)
        }
        return function
    }

    func makeSwiftUIView() throws -> AnyView {
        switch content {
        case .view:
            let renderer = try RuntimeViewRenderer(instance: self)
            return AnyView(RuntimeViewHost(renderer: renderer))
        case .modifier(let definition, let arguments):
            guard let wrapped = parent as? RuntimeInstance else {
                throw RuntimeError.invalidArgument("Modifier can only apply to View instance")
            }
            let view = try wrapped.makeSwiftUIView()
            let baseValue = RuntimeValue.swiftUI(.view(view))
            let modifiedValue = try definition.apply(
                to: baseValue,
                arguments: arguments,
                scope: self
            )
            guard let modifiedView = modifiedValue.asSwiftUIView else {
                throw RuntimeError.invalidArgument("Modifier did not return a SwiftUI view.")
            }
            return modifiedView
        }
    }
}
