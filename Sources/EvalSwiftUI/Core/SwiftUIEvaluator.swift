import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftUI

public final class SwiftUIEvaluator {
    let stateStore: RuntimeStateStore
    private let viewNodeBuilder: ViewNodeBuilder
    private let expressionResolver: ExpressionResolver
    private let viewRegistry: ViewRegistry
    private let modifierRegistry: ModifierRegistry
    private let context: (any SwiftUIEvaluatorContext)?
    private var inlineInstanceTracker: [String: Int] = [:]

    public init(expressionResolver: ExpressionResolver? = nil,
                viewBuilders: [any SwiftUIViewBuilder] = [],
                modifierBuilders: [any SwiftUIModifierBuilder] = [],
                context: (any SwiftUIEvaluatorContext)? = nil,
                stateStore: RuntimeStateStore? = nil) {
        self.context = context
        self.stateStore = stateStore ?? RuntimeStateStore()
        let resolver = expressionResolver ?? ExpressionResolver(context: context)
        self.expressionResolver = resolver
        viewNodeBuilder = ViewNodeBuilder(
            expressionResolver: resolver,
            context: context,
            stateStore: self.stateStore
        )
        viewRegistry = ViewRegistry(additionalBuilders: viewBuilders)
        modifierRegistry = ModifierRegistry(additionalBuilders: modifierBuilders)
    }

    @MainActor
    public func evaluate(source: String) throws -> some View {
        let syntax = Parser.parse(source: source)
        return try evaluate(syntax: syntax)
    }

    @MainActor
    private func evaluate(syntax: SourceFileSyntax) throws -> some View {
        stateStore.reset()
        let coordinator = RuntimeRenderCoordinator(evaluator: self, syntax: syntax)
        let initialView = try coordinator.render()
        return RuntimeRenderedView(
            initialView: initialView,
            coordinator: coordinator,
            stateStore: stateStore
        )
    }

    private func buildView(from node: ViewNode, scopeOverrides: ExpressionScope = [:]) throws -> AnyView {
        let scope = node.scope.merging(scopeOverrides) { _, new in new }
        let resolvedConstructorArguments = try resolveArguments(node.constructor.arguments, scope: scope)
        var view = try viewRegistry.makeView(
            from: node.constructor,
            arguments: resolvedConstructorArguments
        )
        for modifier in node.modifiers {
            let resolvedModifierArguments = try resolveArguments(modifier.arguments, scope: scope)
            view = try modifierRegistry.applyModifier(
                modifier,
                arguments: resolvedModifierArguments,
                to: view
            )
        }
        return view
    }

    private func resolveArguments(_ arguments: [ArgumentNode], scope: ExpressionScope) throws -> [ResolvedArgument] {
        try arguments.map { argument in
            switch argument.value {
            case .expression(let expression):
                let value = try expressionResolver.resolveExpression(
                    expression,
                    scope: scope,
                    context: context
                )
                return ResolvedArgument(label: argument.label, value: value)
            case .closure(let closure, let capturedScope):
                let mergedScope = capturedScope.merging(scope) { _, new in new }
                let resolvedClosure = ResolvedClosure(
                    evaluator: self,
                    closure: closure,
                    scope: mergedScope
                )
                return ResolvedArgument(label: argument.label, value: .closure(resolvedClosure))
            }
        }
    }

    func makeViewContent(from closure: ClosureExprSyntax, scope: ExpressionScope) throws -> ViewContent {
        let nodes = try viewNodeBuilder.buildViewNodes(from: closure, scope: scope)
        let parameterNames = closureParameterNames(closure)
        let renderers = nodes.map { node in
            { overrides in
                try self.buildView(from: node, scopeOverrides: overrides)
            }
        }
        return ViewContent(renderers: renderers, parameters: parameterNames)
    }

    func performAction(from closure: ClosureExprSyntax,
                       scope: ExpressionScope,
                       overrides: ExpressionScope = [:]) throws {
        let mergedScope = scope.merging(overrides) { _, new in new }
        _ = try viewNodeBuilder.buildViewNodes(
            in: closure.statements,
            scope: mergedScope,
            allowStateDeclarations: false
        )
    }

    func renderSyntax(from syntax: SourceFileSyntax) throws -> AnyView {
        inlineInstanceTracker = [:]
        let filteredStatements = try filteredTopLevelStatements(from: syntax.statements)
        let result = try viewNodeBuilder.buildViewNodes(
            in: filteredStatements,
            scope: [:],
            allowStateDeclarations: true
        )
        guard let viewNode = result.nodes.last else {
            throw SwiftUIEvaluatorError.missingRootExpression
        }

        if result.nodes.count > 1 {
            let views = try result.nodes.map { try buildView(from: $0) }
            return wrapInStack(views)
        }

        return try buildView(from: viewNode)
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

    private func wrapInStack(_ views: [AnyView]) -> AnyView {
        AnyView(
            VStack(alignment: .center, spacing: 0) {
                ForEach(Array(views.enumerated()), id: \.0) { _, view in
                    view
                }
            }
        )
    }

    private func filteredTopLevelStatements(
        from statements: CodeBlockItemListSyntax
    ) throws -> CodeBlockItemListSyntax {
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
        let builder = InlineStructViewBuilder(definition: definition, evaluator: self)
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

    func resolveExpression(
        _ expression: ExprSyntax,
        scope: ExpressionScope
    ) throws -> SwiftValue {
        try expressionResolver.resolveExpression(expression, scope: scope, context: context)
    }

    func makeStateValue(named identifier: String, initialValue: SwiftValue) -> SwiftValue {
        .state(stateStore.makeState(identifier: identifier, initialValue: initialValue))
    }

    func nextInlineInstanceIdentifier(for name: String) -> String {
        let next = inlineInstanceTracker[name, default: 0]
        inlineInstanceTracker[name] = next + 1
        return "\(name)#\(next)"
    }

    func renderStructBody(
        statements: CodeBlockItemListSyntax,
        scope: ExpressionScope
    ) throws -> AnyView {
        let result = try viewNodeBuilder.buildViewNodes(
            in: statements,
            scope: scope,
            allowStateDeclarations: false
        )
        guard !result.nodes.isEmpty else {
            throw SwiftUIEvaluatorError.missingRootExpression
        }

        if result.nodes.count == 1 {
            return try buildView(from: result.nodes[0])
        }

        let views = try result.nodes.map { try buildView(from: $0) }
        return wrapInStack(views)
    }
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
