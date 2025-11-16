import SwiftUI

public protocol RuntimeModifierDefinition {
    var parameters: [RuntimeParameter] { get }
    func apply(
        to base: RuntimeValue,
        arguments: [RuntimeArgument],
        scope: RuntimeScope
    ) throws -> RuntimeValue
}

public struct RuntimeViewModifierDefinition: RuntimeModifierDefinition {
    public let parameters: [RuntimeParameter]

    private let applyClosure: (AnyView, [RuntimeArgument], RuntimeScope) throws -> AnyView

    public init(
        parameters: [RuntimeParameter],
        apply: @escaping (AnyView, [RuntimeArgument], RuntimeScope) throws -> AnyView
    ) {
        self.parameters = parameters
        self.applyClosure = apply
    }

    public func apply(
        to base: RuntimeValue,
        arguments: [RuntimeArgument],
        scope: RuntimeScope
    ) throws -> RuntimeValue {
        guard let view = base.asSwiftUIView else {
            throw RuntimeError.invalidArgument("Modifier requires a SwiftUI view as the receiver.")
        }
        let modified = try applyClosure(view, arguments, scope)
        return .swiftUI(.view(modified))
    }
}

public struct RuntimeValueModifierDefinition: RuntimeModifierDefinition {
    public let parameters: [RuntimeParameter]
    private let applyClosure: (RuntimeValue, [RuntimeArgument], RuntimeScope) throws -> RuntimeValue

    public init(
        parameters: [RuntimeParameter],
        apply: @escaping (RuntimeValue, [RuntimeArgument], RuntimeScope) throws -> RuntimeValue
    ) {
        self.parameters = parameters
        self.applyClosure = apply
    }

    public func apply(
        to base: RuntimeValue,
        arguments: [RuntimeArgument],
        scope: RuntimeScope
    ) throws -> RuntimeValue {
        try applyClosure(base, arguments, scope)
    }
}

public protocol RuntimeModifierBuilder {
    var name: String { get }
    var definitions: [RuntimeModifierDefinition] { get }
}
