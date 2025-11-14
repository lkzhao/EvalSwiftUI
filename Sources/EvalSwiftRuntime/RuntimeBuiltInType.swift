

public protocol RuntimeBuiltInType {
    var name: String { get }
    func makeValue(arguments: [RuntimeArgument], scope: RuntimeScope) throws -> RuntimeValue
    func populate(type: RuntimeType)
}

extension RuntimeBuiltInType {
    public func populate(type: RuntimeType) {
        // Default implementation does nothing
    }
}
