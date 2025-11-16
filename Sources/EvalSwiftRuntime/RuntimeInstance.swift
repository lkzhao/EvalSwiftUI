import SwiftUI

public final class RuntimeInstance: RuntimeScope {
    enum Content {
        case view
        case modifier(RuntimeModifierDefinition, [RuntimeArgument])
    }
    private var content: Content

    public var parent: RuntimeScope?
    public var storage: RuntimeScopeStorage = [:] {
        didSet {
            mutationHandler?()
        }
    }
    var mutationHandler: (() -> Void)?

    public init(parent: RuntimeScope? = nil) {
        self.parent = parent
        self.content = .view
    }

    public init(
        modifierDefinition: RuntimeModifierDefinition,
        arguments: [RuntimeArgument],
        parent: RuntimeInstance
    ) {
        self.parent = parent
        self.content = .modifier(modifierDefinition, arguments)
    }
}

extension RuntimeInstance {
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
