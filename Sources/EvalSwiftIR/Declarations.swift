
public struct ModuleIR {
    public let statements: [StatementIR]
}

public struct DefinitionIR {
    public let name: String
    public let inheritedTypes: [String]
    public let bindings: [BindingIR]
    public let staticBindings: [BindingIR]
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

public enum BinaryOperatorIR: String {
    case addition = "+"
    case subtraction = "-"
    case multiplication = "*"
    case division = "/"
    case remainder = "%"
    case rangeExclusive = "..<"
    case rangeInclusive = "..."

    var precedence: Int {
        switch self {
        case .rangeExclusive, .rangeInclusive:
            return 3
        case .multiplication, .division, .remainder:
            return 2
        case .addition, .subtraction:
            return 1
        }
    }
}

public enum UnaryOperatorIR: String {
    case plus = "+"
    case minus = "-"
}

public enum KeyPathIR: Equatable {
    case `self`
}

public indirect enum ExprIR {
    case identifier(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case string(String)
    case array([ExprIR])
    case keyPath(KeyPathIR)
    case stringInterpolation([StringInterpolationSegmentIR])
    case member(base: ExprIR, name: String)
    case call(callee: ExprIR, arguments: [FunctionCallArgumentIR])
    case function(FunctionIR)
    case definition(DefinitionIR)
    case binary(op: BinaryOperatorIR, lhs: ExprIR, rhs: ExprIR)
    case unary(op: UnaryOperatorIR, operand: ExprIR)
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
