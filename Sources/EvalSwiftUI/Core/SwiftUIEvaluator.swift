import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftUI

public final class SwiftUIEvaluator {
    let stateStore: RuntimeStateStore
    private let viewNodeBuilder: ViewNodeBuilder
    private let expressionResolver: ExpressionResolver
    private let viewRegistry: ViewRegistry
    private lazy var viewRenderer: ViewRendering = {
        SwiftUIViewRenderer(
            viewRegistry: viewRegistry,
            memberFunctionRegistry: expressionResolver.memberFunctionRegistry,
            expressionEvaluator: expressionResolver,
            evaluator: self,
            context: context
        )
    }()
    private lazy var inlineStructProcessor: InlineStructProcessor = {
        InlineStructProcessor(viewRegistry: viewRegistry, evaluator: self)
    }()
    private let context: (any SwiftUIEvaluatorContext)?
    private var inlineInstanceTracker: [InlineInstanceKey: Int] = [:]
    private var inlineInstanceNamespace: [String] = []

    public init(viewBuilders: [any SwiftUIViewBuilder] = [],
                memberFunctionHandlers: [any MemberFunctionHandler] = [],
                context: (any SwiftUIEvaluatorContext)? = nil,
                stateStore: RuntimeStateStore? = nil) {
        self.context = context
        self.stateStore = stateStore ?? RuntimeStateStore()
        expressionResolver = ExpressionResolver(
            context: context,
            memberFunctionHandlers: memberFunctionHandlers
        )

        let mutationEvaluator = StatementMutationEvaluator(
            expressionResolver: expressionResolver,
            context: context,
            stateRegistry: self.stateStore,
            modifierDispatcher: expressionResolver.memberFunctionRegistry
        )

        let builder = ViewNodeBuilder(
            expressionResolver: expressionResolver,
            context: context,
            mutationEvaluator: mutationEvaluator
        )
        viewNodeBuilder = builder
        viewRegistry = ViewRegistry(additionalBuilders: viewBuilders)
    }

    @MainActor
    public func evaluate(source: String) throws -> some View {
        let syntax = Parser.parse(source: source)
        return try evaluate(syntax: syntax)
    }

    @MainActor
    private func evaluate(syntax: SourceFileSyntax) throws -> some View {
        stateStore.reset()
        let initialView = try renderSyntax(from: syntax)
        return RuntimeRenderedView(
            initialView: initialView,
            evaluator: self,
            syntax: syntax,
            stateStore: stateStore
        )
    }

    func makeViewContent(from closure: ClosureExprSyntax, scope: ExpressionScope) throws -> ViewContent {
        let nodes = try viewNodeBuilder.lower(
            statements: closure.statements,
            scope: scope,
            allowStateDeclarations: false
        )
        let parameterNames = closureParameterNames(closure)
        let renderers = nodes.map { node in
            { overrides in
                try self.viewRenderer.render(node: node, overrides: overrides)
            }
        }
        return ViewContent(renderers: renderers, parameters: parameterNames)
    }

    func performAction(from closure: ClosureExprSyntax,
                       scope: ExpressionScope,
                       overrides: ExpressionScope = [:]) throws {
        let mergedScope = scope.merging(overrides) { _, new in new }
        _ = try viewNodeBuilder.lower(
            statements: closure.statements,
            scope: mergedScope,
            allowStateDeclarations: false
        )
    }

    func renderSyntax(from syntax: SourceFileSyntax) throws -> AnyView {
        inlineInstanceTracker = [:]
        inlineInstanceNamespace = []
        let filteredStatements = try inlineStructProcessor.filter(statements: syntax.statements)
        let nodes = try viewNodeBuilder.lower(
            statements: filteredStatements,
            scope: [:],
            allowStateDeclarations: true
        )
        return try viewRenderer.render(nodes: nodes)
    }

    private func closureParameterNames(_ closure: ClosureExprSyntax) -> [String] {
        guard let parameterClause = closure.signature?.parameterClause else {
            return []
        }

        switch parameterClause {
        case .parameterClause(let clause):
            return clause.parameters.map { parameter in
                if let secondName = parameter.secondName {
                    return secondName.text
                }
                return parameter.firstName.text
            }
        case .simpleInput(let shorthand):
            return shorthand.map { $0.name.text }
        }
    }

    func resolveExpression(
        _ expression: ExprSyntax,
        scope: ExpressionScope
    ) throws -> SwiftValue {
        try expressionResolver.resolveExpression(expression, scope: scope, context: context)
    }

    func makeStateValue(named identifier: String, initialValue: SwiftValue) -> SwiftValue {
        let reference = stateStore.makeState(identifier: identifier, initialValue: initialValue)
        return reference.read()
    }

    func nextInlineInstanceIdentifier(for name: String) -> String {
        let key = InlineInstanceKey(namespace: inlineInstanceNamespace, name: name)
        let next = inlineInstanceTracker[key, default: 0]
        inlineInstanceTracker[key] = next + 1
        guard inlineInstanceNamespace.isEmpty else {
            let prefix = inlineInstanceNamespace.joined(separator: ".")
            return "\(prefix).\(name)#\(next)"
        }
        return "\(name)#\(next)"
    }

    func withInlineInstanceNamespace<T>(_ components: [String], perform: () throws -> T) rethrows -> T {
        guard !components.isEmpty else { return try perform() }
        inlineInstanceNamespace.append(contentsOf: components)
        defer { inlineInstanceNamespace.removeLast(components.count) }
        return try perform()
    }

    func renderStructBody(
        statements: CodeBlockItemListSyntax,
        scope: ExpressionScope
    ) throws -> AnyView {
        let result = try viewNodeBuilder.lower(
            statements: statements,
            scope: scope,
            allowStateDeclarations: false
        )
        guard !result.isEmpty else {
            throw SwiftUIEvaluatorError.missingRootExpression
        }

        return try viewRenderer.render(nodes: result)
    }

}

private struct InlineInstanceKey: Hashable {
    let namespace: [String]
    let name: String
}

private struct InlineStructDefinition {
    struct StateProperty {
        let name: String
        let initializer: ExprSyntax
    }

    let name: String
    let bodyStatements: CodeBlockItemListSyntax
    let stateProperties: [StateProperty]
}

private final class InlineStructViewBuilder: SwiftUIViewBuilder {
    let name: String
    private unowned let evaluator: SwiftUIEvaluator
    private let definition: InlineStructDefinition

    init(definition: InlineStructDefinition, evaluator: SwiftUIEvaluator) {
        self.name = definition.name
        self.definition = definition
        self.evaluator = evaluator
    }

    func makeView(arguments: [ResolvedArgument]) throws -> AnyView {
        var scope: ExpressionScope = [:]
        let instanceIdentifier = evaluator.nextInlineInstanceIdentifier(for: definition.name)
        for property in definition.stateProperties {
            let initialValue = try evaluator.resolveExpression(property.initializer, scope: [:])
            let namespacedIdentifier = "\(instanceIdentifier).\(property.name)"
            scope[property.name] = evaluator.makeStateValue(named: namespacedIdentifier, initialValue: initialValue)
        }
        return try evaluator.renderStructBody(statements: definition.bodyStatements, scope: scope)
    }
}

private extension StructDeclSyntax {
    var conformsToView: Bool {
        guard let inherited = inheritanceClause else { return false }
        return inherited.inheritedTypes.contains { inheritedType in
            inheritedType.type.trimmedDescription == "View"
        }
    }
}

private final class InlineStructProcessor {
    private let viewRegistry: ViewRegistry
    private unowned let evaluator: SwiftUIEvaluator

    init(viewRegistry: ViewRegistry, evaluator: SwiftUIEvaluator) {
        self.viewRegistry = viewRegistry
        self.evaluator = evaluator
    }

    func filter(statements: CodeBlockItemListSyntax) throws -> CodeBlockItemListSyntax {
        var retainedItems: [CodeBlockItemSyntax] = []
        for item in statements {
            if let structDecl = item.item.as(StructDeclSyntax.self) {
                try registerInlineStruct(structDecl)
                continue
            }
            retainedItems.append(item)
        }

        return CodeBlockItemListSyntax {
            for item in retainedItems {
                item
            }
        }
    }

    private func registerInlineStruct(_ decl: StructDeclSyntax) throws {
        guard decl.conformsToView else { return }
        let name = decl.name.text
        let bodyStatements = try structBodyStatements(from: decl)
        let stateProperties = try structStateProperties(from: decl)
        let definition = InlineStructDefinition(
            name: name,
            bodyStatements: bodyStatements,
            stateProperties: stateProperties
        )
        let builder = InlineStructViewBuilder(definition: definition, evaluator: evaluator)
        viewRegistry.register(builder: builder)
    }

    private func structBodyStatements(from decl: StructDeclSyntax) throws -> CodeBlockItemListSyntax {
        for member in decl.memberBlock.members {
            guard let variableDecl = member.decl.as(VariableDeclSyntax.self) else { continue }
            for binding in variableDecl.bindings {
                guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
                      identifier.identifier.text == "body" else { continue }

                guard let accessorBlock = binding.accessorBlock else {
                    throw SwiftUIEvaluatorError.invalidArguments("Inline View structs must implement a computed body.")
                }

                switch accessorBlock.accessors {
                case .getter(let statements):
                    return statements
                case .accessors(let list):
                    if let getter = list.first(where: { $0.accessorSpecifier.tokenKind == .keyword(.get) }),
                       let body = getter.body {
                        return body.statements
                    }
                }

                throw SwiftUIEvaluatorError.invalidArguments("Inline View bodies must provide a getter implementation.")
            }
        }

        throw SwiftUIEvaluatorError.invalidArguments("Inline View structs must declare a body property.")
    }

    private func structStateProperties(from decl: StructDeclSyntax) throws -> [InlineStructDefinition.StateProperty] {
        var properties: [InlineStructDefinition.StateProperty] = []
        for member in decl.memberBlock.members {
            guard let variableDecl = member.decl.as(VariableDeclSyntax.self),
                  variableDecl.attributes.containsStateAttribute else { continue }

            for binding in variableDecl.bindings {
                guard let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self),
                      let initializer = binding.initializer else {
                    throw SwiftUIEvaluatorError.invalidArguments("@State properties require an initializer.")
                }
                properties.append(
                    InlineStructDefinition.StateProperty(
                        name: identifierPattern.identifier.text,
                        initializer: ExprSyntax(initializer.value)
                    )
                )
            }
        }
        return properties
    }
}
