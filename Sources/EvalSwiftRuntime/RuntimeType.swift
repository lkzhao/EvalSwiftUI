import EvalSwiftIR

public final class RuntimeType: RuntimeScope {
    public var storage: RuntimeScopeStorage = [:]
    public var parent: RuntimeScope?

    enum Content {
        case builder(RuntimeValueBuilder)
        case definition(DefinitionIR)

        var name: String {
            switch self {
            case .builder(let builder):
                builder.name
            case .definition(let definition):
                definition.name
            }
        }
    }

    var content: Content

    public var name: String {
        content.name
    }

    var fullName: String {
        if let parentType = parent as? RuntimeType {
            return "\(parentType.fullName).\(name)"
        }
        return name
    }

    var inheritedTypeNames: [String] {
        switch content {
        case .builder:
            return []
        case .definition(let ir):
            return ir.inheritedTypes
        }
    }

    func conforms(to typeName: String) -> Bool {
        inheritedTypeNames.contains(typeName)
    }

    public init(ir: DefinitionIR, parent: RuntimeScope?) throws {
        self.content = .definition(ir)
        self.parent = parent
        for binding in ir.staticBindings {
            try define(binding: binding)
        }
        if ir.kind == .enumeration {
            let enumTypeName = fullName
            for enumCase in ir.enumCases {
                let value = RuntimeValue.enumCase(RuntimeEnumCase(typeName: enumTypeName, caseName: enumCase.name))
                define(enumCase.name, value: value)
            }
        }
    }

    public init(builder: RuntimeValueBuilder, parent: RuntimeScope?) {
        self.content = .builder(builder)
        self.parent = parent
        builder.populate(type: self)
    }

    var definitions: [RuntimeBuilderDefinition] {
        switch content {
        case .builder(let builder):
            return builder.definitions
        case .definition(let definitionIR):
            return definitionIR.bindings.filter { $0.name == "init" }.compactMap { binding in
                if case .function(let functionDef) = binding.initializer {
                    let parameters = functionDef.parameters.compactMap {
                        try? RuntimeParameter(ir: $0, scope: self)
                    }
                    return RuntimeBuilderDefinition(parameters: parameters) { [weak self] arguments, scope in
                        guard let self else { return .void }
                        let instance = RuntimeInstance(parent: self)
                        for binding in definitionIR.bindings {
                            try instance.define(binding: binding)
                        }
                        _ = try instance.callFunction("init", arguments: arguments)
                        return .instance(instance)
                    }
                }
                return nil
            }
        }
    }
}
