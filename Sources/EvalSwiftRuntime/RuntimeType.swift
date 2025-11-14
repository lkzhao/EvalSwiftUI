import EvalSwiftIR

public final class RuntimeType: RuntimeScope {
    public var storage: [String: RuntimeValue] = [:]
    public var parent: RuntimeScope?

    enum Content {
        case builtInType(RuntimeBuiltInType)
        case builder(RuntimeViewBuilder)
        case definition(DefinitionIR)

        var name: String {
            switch self {
            case .builtInType(let type):
                type.name
            case .builder(let builder):
                builder.typeName
            case .definition(let definition):
                definition.name
            }
        }
    }

    var content: Content

    public var name: String {
        content.name
    }

    public init(ir: DefinitionIR, parent: RuntimeScope?) throws {
        self.content = .definition(ir)
        self.parent = parent
        for binding in ir.staticBindings {
            try define(binding: binding)
        }
    }

    public init(builder: RuntimeViewBuilder, parent: RuntimeScope?) {
        self.content = .builder(builder)
        self.parent = parent
    }

    public init(builtInType: RuntimeBuiltInType, parent: RuntimeScope?) {
        self.content = .builtInType(builtInType)
        self.parent = parent
        builtInType.populate(type: self)
    }

    public func makeInstance(arguments: [RuntimeArgument] = []) throws -> RuntimeValue {
        switch content {
        case .builtInType(let builtInType):
            return try builtInType.makeValue(arguments: arguments, scope: self)
        case .builder(let builder):
            return .instance(RuntimeInstance(builder: builder, arguments: arguments, parent: self))
        case .definition(let definitionIR):
            let instance = RuntimeInstance(parent: self)
            for binding in definitionIR.bindings {
                try instance.define(binding: binding)
            }
            _ = try instance.callFunction("init", arguments: arguments)
            return .instance(instance)
        }
    }
}
