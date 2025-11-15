

public struct RuntimeFunctionDefinition {
    var parameters: [RuntimeParameter]
    var build: ([RuntimeArgument], RuntimeScope) throws -> RuntimeValue
}

public protocol RuntimeValueBuilder {
    var name: String { get }
    var definitions: [RuntimeFunctionDefinition] { get }
    func populate(type: RuntimeType)
}

extension RuntimeValueBuilder {
    public func populate(type: RuntimeType) {
        // Default implementation does nothing
    }
}
