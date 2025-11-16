import SwiftUI

public protocol RuntimeMethodDefinition {
    var parameters: [RuntimeParameter] { get }
    func apply(
        to base: RuntimeValue,
        setter: ((RuntimeValue) throws -> Void)?
        ,
        arguments: [RuntimeArgument],
        scope: RuntimeScope
    ) throws -> RuntimeValue
}

public struct RuntimeViewMethodDefinition: RuntimeMethodDefinition {
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
        setter: ((RuntimeValue) throws -> Void)?,
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

public struct RuntimeValueMethodDefinition: RuntimeMethodDefinition {
    public let parameters: [RuntimeParameter]
    private let applyClosure: (RuntimeValue, ((RuntimeValue) throws -> Void)?, [RuntimeArgument], RuntimeScope) throws -> RuntimeValue

    public init(
        parameters: [RuntimeParameter],
        apply: @escaping (RuntimeValue, ((RuntimeValue) throws -> Void)?, [RuntimeArgument], RuntimeScope) throws -> RuntimeValue
    ) {
        self.parameters = parameters
        self.applyClosure = apply
    }

    public init(
        parameters: [RuntimeParameter],
        apply: @escaping (RuntimeValue, [RuntimeArgument], RuntimeScope) throws -> RuntimeValue
    ) {
        self.parameters = parameters
        self.applyClosure = { base, _, arguments, scope in
            try apply(base, arguments, scope)
        }
    }

    public func apply(
        to base: RuntimeValue,
        setter: ((RuntimeValue) throws -> Void)?,
        arguments: [RuntimeArgument],
        scope: RuntimeScope
    ) throws -> RuntimeValue {
        try applyClosure(base, setter, arguments, scope)
    }
}

public protocol RuntimeMethodBuilder {
    var name: String { get }
    var definitions: [RuntimeMethodDefinition] { get }
    var supportsMemberAccess: Bool { get }
}

public extension RuntimeMethodBuilder {
    var supportsMemberAccess: Bool { false }
}
