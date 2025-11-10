public enum StatementIR {
    case binding(BindingIR)
    case expression(ExprIR)
    case `return`(ReturnIR)
    case unhandled(String)
}

public struct ReturnIR {
    public let value: ExprIR?

    public init(value: ExprIR?) {
        self.value = value
    }
}
