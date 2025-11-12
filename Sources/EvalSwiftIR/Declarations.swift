
public struct ModuleIR {
    public let statements: [StatementIR]
}

public struct ViewDefinitionIR {
    public let bindings: [BindingIR]
}

public struct BindingIR {
    public let name: String
    public let typeAnnotation: String?
    public let initializer: ExprIR?
}

public struct FunctionIR {
    public let parameters: [FunctionParameterIR]
    public let returnType: String?
    public let body: [StatementIR]
}

public struct FunctionParameterIR {
    public let label: String?
    public let name: String
    public let defaultValue: ExprIR?
}

public indirect enum ExprIR {
    case identifier(String)
    case literal(String)
    case stringInterpolation([StringInterpolationSegmentIR])
    case member(base: ExprIR, name: String)
    case call(callee: ExprIR, arguments: [FunctionCallArgumentIR])
    case function(FunctionIR)
    case view(ViewDefinitionIR)
    case unknown(String)
}

public enum StringInterpolationSegmentIR {
    case literal(String)
    case expression(ExprIR)
}

public struct FunctionCallArgumentIR {
    public let label: String?
    public let value: ExprIR
}

public enum StatementIR {
    case binding(BindingIR)
    case expression(ExprIR)
    case `return`(ReturnIR)
    case assignment(AssignmentIR)
    case unhandled(String)
}

public struct ReturnIR {
    public let value: ExprIR?
}

public struct AssignmentIR {
    public let target: ExprIR
    public let value: ExprIR
}
