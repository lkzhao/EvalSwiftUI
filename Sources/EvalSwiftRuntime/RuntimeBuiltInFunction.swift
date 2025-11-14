
import EvalSwiftIR

public protocol RuntimeBuiltInFunction {
    var name: String { get }
    var parameters: [FunctionParameterIR] { get }
    func call(arguments: [RuntimeArgument], scope: RuntimeScope) throws -> RuntimeValue?
}

extension RuntimeBuiltInFunction {
    public var parameters: [FunctionParameterIR] {
        []
    }
}
