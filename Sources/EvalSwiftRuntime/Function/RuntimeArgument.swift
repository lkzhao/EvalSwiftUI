import EvalSwiftIR

public typealias RuntimeParameter = FunctionParameterIR

public struct RuntimeArgument {
    public let name: String
    public let value: RuntimeValue

    public init(name: String, value: RuntimeValue) {
        self.name = name
        self.value = value
    }
}
