@PublicMemberwiseInit
public struct ModuleIR {
    public let bindings: [BindingIR]
    public let statements: [StatementIR]
}

@PublicMemberwiseInit
public struct ViewDefinitionIR {
    public let name: String
    public let parameters: [FunctionParameterIR]
    public let properties: [PropertyIR]
    public let methods: [FunctionIR]
    public let bodyStatements: [StatementIR]
}

@PublicMemberwiseInit
public struct PropertyIR {
    public let name: String
    public let typeAnnotation: String?
    public let initializer: ExprIR?
}

@PublicMemberwiseInit
public struct BindingIR {
    public let name: String
    public let typeAnnotation: String?
    public let initializer: ExprIR?
}

@PublicMemberwiseInit
public struct FunctionIR {
    public let name: String
    public let parameters: [FunctionParameterIR]
    public let returnType: String?
    public let body: [StatementIR]
}

@PublicMemberwiseInit
public struct FunctionParameterIR {
    public let externalName: String?
    public let internalName: String
    public let typeAnnotation: String?
}
