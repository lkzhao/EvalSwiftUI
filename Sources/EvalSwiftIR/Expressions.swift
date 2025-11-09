public indirect enum ExprIR {
    case identifier(String)
    case literal(String)
    case member(base: ExprIR, name: String)
    case call(callee: ExprIR, arguments: [FunctionCallArgumentIR])
    case unknown(String)
}

public struct FunctionCallArgumentIR {
    public let label: String?
    public let value: ExprIR
}
