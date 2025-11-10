public enum StatementIR {
    case binding(BindingIR)
    case expression(ExprIR)
    case `return`(ReturnIR)
    case unhandled(String)
}

public struct ReturnIR {
    public let value: ExprIR?
}
