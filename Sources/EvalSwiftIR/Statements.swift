public enum StatementIR {
    case binding(BindingIR)
    case expression(ExprIR)
    case `return`(ReturnIR)
    case unhandled(String)
}

@PublicMemberwiseInit
public struct ReturnIR {
    public let value: ExprIR?
}
