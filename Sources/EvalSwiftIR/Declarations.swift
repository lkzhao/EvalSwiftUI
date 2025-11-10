
public struct ModuleIR {
    public let bindings: [BindingIR]
    public let statements: [StatementIR]
}

public struct ViewDefinitionIR {
    public let name: String
    public let bindings: [BindingIR]
    public let bodyStatements: [StatementIR]
}

public struct BindingIR {
    public let name: String
    public let typeAnnotation: String?
    public let initializer: ExprIR?
}

public struct FunctionIR {
    public let name: String
    public let parameters: [FunctionParameterIR]
    public let returnType: String?
    public let body: [StatementIR]
}

public struct FunctionParameterIR {
    public let name: String
}
