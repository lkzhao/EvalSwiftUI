import SwiftUI

public final class RuntimeInstance: RuntimeScope {
    enum Content {
        case view
        case builder(RuntimeViewBuilder, [RuntimeArgument])
        case modifier(RuntimeModifierBuilder, [RuntimeArgument])
    }
    private var content: Content

    public var parent: RuntimeScope?
    public var storage: [String: RuntimeValue] = [:] {
        didSet {
            mutationHandler?()
        }
    }
    var mutationHandler: (() -> Void)?

    public init(parent: RuntimeScope? = nil) {
        self.parent = parent
        self.content = .view
    }

    public init(builder: RuntimeViewBuilder, arguments: [RuntimeArgument], parent: RuntimeScope? = nil) {
        self.parent = parent
        self.content = .builder(builder, arguments)
    }

    public init(modifierBuilder: RuntimeModifierBuilder, arguments: [RuntimeArgument], parent: RuntimeInstance) {
        self.parent = parent
        self.content = .modifier(modifierBuilder, arguments)
    }
}

extension RuntimeInstance {
    @MainActor
    func makeSwiftUIView() throws -> AnyView {
        switch content {
        case .builder(let builder, let arguments):
            return try builder.makeSwiftUIView(arguments: arguments, scope: self)
        case .view:
            let renderer = try RuntimeViewRenderer(instance: self)
            return AnyView(RuntimeViewHost(renderer: renderer))
        case .modifier(let builder, let arguments):
            guard let wrapped = parent as? RuntimeInstance else {
                throw RuntimeError.invalidViewArgument("Modifier can only apply to View instance")
            }
            let view = try wrapped.makeSwiftUIView()
            return try builder.applyModifier(
                to: view,
                arguments: arguments,
                scope: self
            )
        }
    }
}
