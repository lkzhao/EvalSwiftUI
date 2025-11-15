
public struct ModuleIR: Hashable {
    public let statements: [StatementIR]
}

public struct DefinitionIR: Hashable {
    public let name: String
    public let inheritedTypes: [String]
    public let bindings: [BindingIR]
    public let staticBindings: [BindingIR]
}

public struct BindingIR: Hashable {
    public let name: String
    public let type: String?
    public let initializer: ExprIR?
}

public struct FunctionIR: Hashable {
    public let parameters: [FunctionParameterIR]
    public let returnType: String?
    public let body: [StatementIR]
}

public struct FunctionParameterIR: Hashable {
    public let label: String?
    public let name: String
    public let type: String?
    public let defaultValue: ExprIR?

    public init(label: String? = nil, name: String, type: String? = nil, defaultValue: ExprIR? = nil) {
        self.label = label
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
    }
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

public indirect enum ExprIR: Hashable {
    case identifier(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case string(String)
    case array([ExprIR])
    case keyPath(KeyPathIR)
    case stringInterpolation([StringInterpolationSegmentIR])
    case member(base: ExprIR?, name: String)
    case call(callee: ExprIR, arguments: [FunctionCallArgumentIR])
    case function(FunctionIR)
    case definition(DefinitionIR)
    case binary(op: BinaryOperatorIR, lhs: ExprIR, rhs: ExprIR)
    case unary(op: UnaryOperatorIR, operand: ExprIR)
    case unknown(String)
}

public enum StringInterpolationSegmentIR: Hashable {
    case literal(String)
    case expression(ExprIR)
}

public struct FunctionCallArgumentIR: Hashable {
    public let label: String?
    public let value: ExprIR
}

public enum StatementIR: Hashable {
    case binding(BindingIR)
    case expression(ExprIR)
    case `return`(ReturnIR)
    case assignment(AssignmentIR)
    case `if`(IfStatementIR)
    case unhandled(String)
}

public struct ReturnIR: Hashable {
    public let value: ExprIR?
}

public struct AssignmentIR: Hashable {
    public let target: ExprIR
    public let value: ExprIR
}

public struct IfStatementIR: Hashable {
    public let condition: ExprIR
    public let body: [StatementIR]
    public let elseBody: [StatementIR]?
}
