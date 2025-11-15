
public protocol RuntimeBuiltInFunction {
    var name: String { get }
    var parameters: [RuntimeParameter] { get }
    func call(arguments: [RuntimeArgument], scope: RuntimeScope) throws -> RuntimeValue?
}
