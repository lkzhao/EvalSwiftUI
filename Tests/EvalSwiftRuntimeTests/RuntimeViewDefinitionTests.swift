import Testing
@testable import EvalSwiftRuntime
import EvalSwiftIR

struct RuntimeViewDefinitionTests {
    @Test func instantiatesViewBodyReturnsPropertyValue() throws {
        let property = PropertyIR(name: "title", typeAnnotation: nil, initializer: .literal("\"Hello\""))
        let view = ViewDefinitionIR(
            name: "SampleView",
            parameters: [],
            properties: [property],
            methods: [],
            bodyStatements: [
                .return(ReturnIR(value: .identifier("title")))
            ]
        )
        let binding = BindingIR(name: "SampleView", typeAnnotation: nil, initializer: .view(view))
        let moduleIR = ModuleIR(bindings: [binding], statements: [])
        let module = RuntimeModule(ir: moduleIR)

        guard let value = module.value(for: "SampleView"),
              case .viewDefinition(let compiled) = value else {
            throw TestFailure.expected("Expected compiled view binding")
        }

        let rendered = try compiled.instantiate(scope: module.globalScope)

        guard case .string(let message) = rendered else {
            throw TestFailure.expected("Expected string result, got \(rendered)")
        }

        #expect(message == "Hello")
    }

    @Test func implicitReturnUsesLastExpression() throws {
        let property = PropertyIR(name: "title", typeAnnotation: nil, initializer: .literal("\"Implicit\""))
        let view = ViewDefinitionIR(
            name: "ImplicitView",
            parameters: [],
            properties: [property],
            methods: [],
            bodyStatements: [
                .expression(.literal("\"Ignored\"")),
                .expression(.identifier("title"))
            ]
        )
        let binding = BindingIR(name: "ImplicitView", typeAnnotation: nil, initializer: .view(view))
        let moduleIR = ModuleIR(bindings: [binding], statements: [])
        let module = RuntimeModule(ir: moduleIR)

        guard let value = module.value(for: "ImplicitView"),
              case .viewDefinition(let compiled) = value else {
            throw TestFailure.expected("Expected compiled view binding")
        }

        let rendered = try compiled.instantiate(scope: module.globalScope)

        guard case .string(let message) = rendered else {
            throw TestFailure.expected("Expected string result, got \(rendered)")
        }

        #expect(message == "Implicit")
    }

    @Test func bindsParametersWhenInstantiating() throws {
        let parameter = FunctionParameterIR(externalName: "title", internalName: "title", typeAnnotation: "String")
        let view = ViewDefinitionIR(
            name: "ParamView",
            parameters: [parameter],
            properties: [],
            methods: [],
            bodyStatements: [
                .return(ReturnIR(value: .identifier("title")))
            ]
        )
        let binding = BindingIR(name: "ParamView", typeAnnotation: nil, initializer: .view(view))
        let moduleIR = ModuleIR(bindings: [binding], statements: [])
        let module = RuntimeModule(ir: moduleIR)

        guard let value = module.value(for: "ParamView"),
              case .viewDefinition(let compiled) = value else {
            throw TestFailure.expected("Expected compiled view binding")
        }

        let rendered = try compiled.instantiate(arguments: [.string("Hello")], scope: module.globalScope)

        guard case .string(let message) = rendered else {
            throw TestFailure.expected("Expected string result, got \(rendered)")
        }

        #expect(message == "Hello")
    }
}
