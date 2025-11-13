import SwiftUI

public final class RuntimeInstance: RuntimeScope {
    public var storage: [String: RuntimeValue] = [:] {
        didSet {
            mutationHandler?()
        }
    }
    public var parent: RuntimeScope?
    public var builderData: (RuntimeViewBuilder, [RuntimeArgument])?
    var mutationHandler: (() -> Void)?

    public init(parent: RuntimeScope? = nil) {
        self.parent = parent
    }
    
    public init(builder: RuntimeViewBuilder, arguments: [RuntimeArgument], parent: RuntimeScope? = nil) {
        self.parent = parent
        self.builderData = (builder, arguments)
    }
}

extension RuntimeInstance {
    @MainActor
    func makeSwiftUIView() throws -> AnyView {
        if let (builder, arguments) = builderData {
            return try builder.makeSwiftUIView(arguments: arguments, scope: self)
        }
        let renderer = try RuntimeViewRenderer(instance: self)
        return AnyView(RuntimeViewHost(renderer: renderer))
    }
}
