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
               let entry = makeViewDefinition(from: structDecl) {
                bindings.append(BindingIR(name: entry.name, typeAnnotation: nil, initializer: .view(entry.definition)))
                continue
            }

            if let classDecl = node.as(ClassDeclSyntax.self),
               let entry = makeViewDefinition(from: classDecl) {
                bindings.append(BindingIR(name: entry.name, typeAnnotation: nil, initializer: .view(entry.definition)))
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

    private func makeViewDefinition(from node: SyntaxProtocol) -> (name: String, definition: ViewDefinitionIR)? {
        guard conformsToView(node) else { return nil }

        let name: String
        let members: MemberBlockItemListSyntax

        switch node {
        case let structDecl as StructDeclSyntax:
            name = structDecl.name.text
            members = structDecl.memberBlock.members
        case let classDecl as ClassDeclSyntax:
            name = classDecl.name.text
            members = classDecl.memberBlock.members
        default:
            return nil
        }

        var bindings: [BindingIR] = []
        var bodyStatements: [StatementIR] = []

        for member in members {
            if let variable = member.decl.as(VariableDeclSyntax.self) {
                if let body = makeBodyStatements(from: variable) {
                    bodyStatements = body
                    continue
                }
                bindings.append(contentsOf: makeBindingList(from: variable))
                continue
            }

            if let functionDecl = member.decl.as(FunctionDeclSyntax.self) {
                bindings.append(makeFunctionBinding(from: functionDecl))
            }
        }

        let definition = ViewDefinitionIR(
            bindings: bindings,
            bodyStatements: bodyStatements
        )
        return (name: name, definition: definition)
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
        return FunctionParameterIR(name: parameter.secondName?.text ?? firstName)
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
            return .literal(literal.segments.description)
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

    private func makeBodyStatements(from node: VariableDeclSyntax) -> [StatementIR]? {
        guard node.bindings.count == 1,
              let binding = node.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
              pattern.identifier.text == "body",
              let accessorBlock = binding.accessorBlock else {
            return nil
        }
        let statements: [StatementIR]?

        switch accessorBlock.accessors {
        case .getter(let getterStatements):
            statements = makeStatements(from: getterStatements)
        case .accessors(let accessorList):
            if let getter = accessorList.first(where: { $0.accessorSpecifier.tokenKind == .keyword(.get) }),
               let body = getter.body {
                statements = makeStatements(from: body.statements)
            } else {
                statements = nil
            }
        }

        return statements
    }

}
