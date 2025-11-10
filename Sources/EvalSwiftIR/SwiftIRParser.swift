import SwiftParser
import SwiftSyntax

public struct SwiftIRParser {
    public init() {}

    public func parseModule(source: String) -> ModuleIR {
        let syntax = Parser.parse(source: source)
        var bindings: [BindingIR] = []
        var statements: [StatementIR] = []

        for item in syntax.statements {
            let node = item.item

            if let structDecl = node.as(StructDeclSyntax.self),
               let definition = makeViewDefinition(from: structDecl) {
                bindings.append(BindingIR(name: structDecl.name.text, typeAnnotation: nil, initializer: .view(definition)))
                continue
            }

            if let functionDecl = node.as(FunctionDeclSyntax.self) {
                let functionIR = makeFunctionIR(from: functionDecl)
                let binding = BindingIR(
                    name: functionDecl.name.text,
                    typeAnnotation: nil,
                    initializer: .function(functionIR)
                )
                bindings.append(binding)
                continue
            }

            if let variableDecl = node.as(VariableDeclSyntax.self) {
                bindings.append(contentsOf: makeBindingList(from: variableDecl))
                continue
            }

            if let expressionStmt = node.as(ExpressionStmtSyntax.self) {
                statements.append(.expression(makeExpr(expressionStmt.expression)))
                continue
            }
        }

        return ModuleIR(
            bindings: bindings,
            statements: statements
        )
    }

    private func makeViewDefinition(from node: StructDeclSyntax) -> ViewDefinitionIR? {
        guard conformsToView(node) else { return nil }

        let members: MemberBlockItemListSyntax = node.memberBlock.members

        var instanceBindings: [BindingIR] = []
        var storedProperties: [BindingIR] = []
        var hasExplicitInitializer = false

        for member in members {
            if let variable = member.decl.as(VariableDeclSyntax.self) {
                if let computedBinding = makeComputedBinding(from: variable) {
                    instanceBindings.append(computedBinding)
                    continue
                }

                let bindings = makeBindingList(from: variable)
                storedProperties.append(contentsOf: bindings)
                instanceBindings.append(contentsOf: bindings)
                continue
            }

            if let functionDecl = member.decl.as(FunctionDeclSyntax.self) {
                let binding = makeFunctionBinding(from: functionDecl)
                instanceBindings.append(binding)
                continue
            }

            if let initializerDecl = member.decl.as(InitializerDeclSyntax.self) {
                instanceBindings.append(makeInitializerBinding(from: initializerDecl))
                hasExplicitInitializer = true
                continue
            }
        }

        if !hasExplicitInitializer {
            instanceBindings.insert(synthesizeInitializer(from: storedProperties), at: 0)
        }

        return ViewDefinitionIR(bindings: instanceBindings)
    }

    private func makeFunctionIR(from node: FunctionDeclSyntax) -> FunctionIR {
        let params = node.signature.parameterClause.parameters.map(makeParameter)
        let returnType = node.signature.returnClause?.type.trimmedDescription
        let bodyStatements = node.body.map(makeStatements) ?? []
        return FunctionIR(
            parameters: params,
            returnType: returnType,
            body: bodyStatements
        )
    }

    private func makeParameter(_ parameter: FunctionParameterSyntax) -> FunctionParameterIR {
        let firstName = parameter.firstName.text
        let label = firstName == "_" ? nil : firstName
        let name = parameter.secondName?.text ?? firstName
        let defaultValue = parameter.defaultValue.map { makeExpr($0.value) }
        return FunctionParameterIR(label: label, name: name, defaultValue: defaultValue)
    }

    private func makeBindingList(from node: VariableDeclSyntax) -> [BindingIR] {
        node.bindings.compactMap { binding in
            guard let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self) else { return nil }
            let initializerExpr = binding.initializer.map { makeExpr($0.value) }
            let typeAnnotation = binding.typeAnnotation?.type.trimmedDescription
            return BindingIR(
                name: identifierPattern.identifier.text,
                typeAnnotation: typeAnnotation,
                initializer: initializerExpr
            )
        }
    }

    private func makeFunctionBinding(from node: FunctionDeclSyntax) -> BindingIR {
        let functionIR = makeFunctionIR(from: node)
        return BindingIR(
            name: node.name.text,
            typeAnnotation: nil,
            initializer: .function(functionIR)
        )
    }

    private func makeStatements(from block: CodeBlockSyntax) -> [StatementIR] {
        makeStatements(from: block.statements)
    }

    private func makeStatements(from statements: CodeBlockItemListSyntax) -> [StatementIR] {
        statements.map { statement in
            if let returnStmt = statement.item.as(ReturnStmtSyntax.self) {
                return .return(ReturnIR(value: returnStmt.expression.map(makeExpr)))
            }

            if let varDecl = statement.item.as(VariableDeclSyntax.self),
               let binding = makeBinding(from: varDecl) {
                return .binding(binding)
            }

            if let assignment = makeAssignment(from: statement) {
                return .assignment(assignment)
            }

            if let exprStmt = statement.item.as(ExpressionStmtSyntax.self) {
                return .expression(makeExpr(exprStmt.expression))
            }

            if let expr = statement.item.as(ExprSyntax.self) {
                return .expression(makeExpr(expr))
            }

            return .unhandled(statement.item.trimmedDescription)
        }
    }

    private func makeBinding(from node: VariableDeclSyntax) -> BindingIR? {
        guard let binding = node.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self) else {
            return nil
        }

        let initializer = binding.initializer.map { makeExpr($0.value) }
        let typeAnnotation = binding.typeAnnotation?.type.trimmedDescription

        return BindingIR(
            name: identifier.identifier.text,
            typeAnnotation: typeAnnotation,
            initializer: initializer
        )
    }

    private func makeExpr(_ expr: ExprSyntax) -> ExprIR {
        if let literal = expr.as(IntegerLiteralExprSyntax.self) {
            return .literal(literal.literal.text)
        }

        if let literal = expr.as(FloatLiteralExprSyntax.self) {
            return .literal(literal.literal.text)
        }

        if let literal = expr.as(StringLiteralExprSyntax.self) {
            let containsInterpolation = literal.segments.contains(where: { $0.as(ExpressionSegmentSyntax.self) != nil })

            if !containsInterpolation {
                let text = literal.segments.compactMap { segment -> String? in
                    segment.as(StringSegmentSyntax.self)?.content.text
                }.joined()
                return .literal(text)
            }

            var segments: [StringInterpolationSegmentIR] = []
            for segment in literal.segments {
                if let stringSegment = segment.as(StringSegmentSyntax.self) {
                    segments.append(.literal(stringSegment.content.text))
                    continue
                }

                if let interpolation = segment.as(ExpressionSegmentSyntax.self) {
                    guard interpolation.expressions.count == 1,
                          let expression = interpolation.expressions.first else {
                        return .unknown(literal.trimmedDescription)
                    }
                    segments.append(.expression(makeExpr(expression.expression)))
                    continue
                }
            }

            return .stringInterpolation(segments)
        }

        if let literal = expr.as(BooleanLiteralExprSyntax.self) {
            return .literal(literal.literal.text)
        }

        if let reference = expr.as(DeclReferenceExprSyntax.self) {
            return .identifier(reference.baseName.text)
        }

        if let member = expr.as(MemberAccessExprSyntax.self) {
            if let base = member.base {
                return .member(base: makeExpr(base), name: member.declName.baseName.text)
            }
            return .identifier(member.declName.baseName.text)
        }

        if let call = expr.as(FunctionCallExprSyntax.self) {
            var arguments = call.arguments.map {
                FunctionCallArgumentIR(label: $0.label?.text, value: makeExpr($0.expression))
            }

            if let trailingClosure = call.trailingClosure {
                let functionIR = makeClosureFunction(trailingClosure)
                arguments.append(FunctionCallArgumentIR(label: nil, value: .function(functionIR)))
            }

            return .call(callee: makeExpr(call.calledExpression), arguments: arguments)
        }

        if let closure = expr.as(ClosureExprSyntax.self) {
            return .function(makeClosureFunction(closure))
        }

        return .unknown(expr.trimmedDescription)
    }

    private func makeClosureFunction(_ closure: ClosureExprSyntax) -> FunctionIR {
        let statements = makeStatements(from: closure.statements)
        return FunctionIR(parameters: [], returnType: nil, body: statements)
    }

    private func conformsToView(_ node: SyntaxProtocol) -> Bool {
        let inheritance: InheritanceClauseSyntax?
        switch node {
        case let structDecl as StructDeclSyntax:
            inheritance = structDecl.inheritanceClause
        case let classDecl as ClassDeclSyntax:
            inheritance = classDecl.inheritanceClause
        default:
            inheritance = nil
        }
        guard let inheritance else { return false }
        return inheritance.inheritedTypes.contains { $0.type.trimmedDescription == "View" }
    }

    private func makeComputedBinding(from node: VariableDeclSyntax) -> BindingIR? {
        guard node.bindings.count == 1,
              let binding = node.bindings.first,
              binding.accessorBlock != nil,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
            return nil
        }

        guard let getterStatements = makeAccessorStatements(from: binding) else {
            return nil
        }

        let functionIR = FunctionIR(
            parameters: [],
            returnType: binding.typeAnnotation?.type.trimmedDescription,
            body: getterStatements
        )

        return BindingIR(
            name: pattern.identifier.text,
            typeAnnotation: binding.typeAnnotation?.type.trimmedDescription,
            initializer: .function(functionIR)
        )
    }

    private func makeInitializerBinding(from node: InitializerDeclSyntax) -> BindingIR {
        let params = node.signature.parameterClause.parameters.map(makeParameter)
        let bodyStatements = node.body.map(makeStatements) ?? []
        let functionIR = FunctionIR(parameters: params, returnType: nil, body: bodyStatements)
        return BindingIR(name: "init", typeAnnotation: nil, initializer: .function(functionIR))
    }

    private func synthesizeInitializer(from properties: [BindingIR]) -> BindingIR {
        let parameters = properties.map { property in
            FunctionParameterIR(label: property.name, name: property.name, defaultValue: property.initializer)
        }
        let assignments: [StatementIR] = properties.map { property in
            let target = ExprIR.member(base: .identifier("self"), name: property.name)
            let value = ExprIR.identifier(property.name)
            return .assignment(AssignmentIR(target: target, value: value))
        }
        let functionIR = FunctionIR(parameters: parameters, returnType: nil, body: assignments)
        return BindingIR(name: "init", typeAnnotation: nil, initializer: .function(functionIR))
    }

    private func makeAccessorStatements(from binding: PatternBindingSyntax) -> [StatementIR]? {
        guard let accessorBlock = binding.accessorBlock else { return nil }

        switch accessorBlock.accessors {
        case .getter(let getterStatements):
            return makeStatements(from: getterStatements)
        case .accessors(let accessorList):
            if let getter = accessorList.first(where: { $0.accessorSpecifier.tokenKind == .keyword(.get) }),
               let body = getter.body {
                return makeStatements(from: body.statements)
            }
            return nil
        }
    }

    private func makeAssignment(from item: CodeBlockItemSyntax) -> AssignmentIR? {
        guard let sequence = item.item.as(SequenceExprSyntax.self) else { return nil }
        let elements = Array(sequence.elements)
        guard elements.count == 3,
              elements[1].as(AssignmentExprSyntax.self) != nil else {
            return nil
        }
        return AssignmentIR(target: makeExpr(elements[0]), value: makeExpr(elements[2]))
    }

}

private struct StoredProperty {
    let name: String
    let typeAnnotation: String?
    let initializer: ExprIR?
}
