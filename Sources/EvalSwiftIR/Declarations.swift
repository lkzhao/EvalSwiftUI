public struct ModuleIR {
    public let bindings: [BindingIR]
    public let statements: [StatementIR]

    public init(bindings: [BindingIR], statements: [StatementIR]) {
        self.bindings = bindings
        self.statements = statements
    }
}

public struct ViewDefinitionIR {
    public let name: String
    public let parameters: [FunctionParameterIR]
    public let properties: [PropertyIR]
    public let methods: [FunctionIR]
    public let bodyStatements: [StatementIR]

    public init(
        name: String,
        parameters: [FunctionParameterIR],
        properties: [PropertyIR],
        methods: [FunctionIR],
        bodyStatements: [StatementIR]
    ) {
        self.name = name
        self.parameters = parameters
        self.properties = properties
        self.methods = methods
        self.bodyStatements = bodyStatements
    }
}

public struct PropertyIR {
    public let name: String
    public let typeAnnotation: String?
    public let initializer: ExprIR?

    public init(name: String, typeAnnotation: String?, initializer: ExprIR?) {
        self.name = name
        self.typeAnnotation = typeAnnotation
        self.initializer = initializer
    }
}

public struct BindingIR {
    public let name: String
    public let typeAnnotation: String?
    public let initializer: ExprIR?

    public init(name: String, typeAnnotation: String?, initializer: ExprIR?) {
        self.name = name
        self.typeAnnotation = typeAnnotation
        self.initializer = initializer
    }
}

public struct FunctionIR {
    public let name: String
    public let parameters: [FunctionParameterIR]
    public let returnType: String?
    public let body: [StatementIR]

    public init(
        name: String,
        parameters: [FunctionParameterIR],
        returnType: String?,
        body: [StatementIR]
    ) {
        self.name = name
        self.parameters = parameters
        self.returnType = returnType
        self.body = body
    }
}

public struct FunctionParameterIR {
    public let externalName: String?
    public let internalName: String
    public let typeAnnotation: String?

    public init(externalName: String?, internalName: String, typeAnnotation: String?) {
        self.externalName = externalName
        self.internalName = internalName
        self.typeAnnotation = typeAnnotation
    }
}
