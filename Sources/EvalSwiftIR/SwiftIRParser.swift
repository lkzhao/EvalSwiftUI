import SwiftParser
import SwiftSyntax

public struct SwiftIRParser {
    public init() {}

    public func parseModule(source: String) -> ModuleIR {
        let syntax = Parser.parse(source: source)
        var statements: [StatementIR] = []

        for item in syntax.statements {
            let node = item.item

            if let structDecl = node.as(StructDeclSyntax.self),
               let definition = makeDefinition(from: structDecl) {
                statements.append(.binding(BindingIR(name: structDecl.name.text, type: nil, initializer: .definition(definition))))
                continue
            }

            if let functionDecl = node.as(FunctionDeclSyntax.self) {
                let functionIR = makeFunctionIR(from: functionDecl)
                let binding = BindingIR(
                    name: functionDecl.name.text,
                    type: nil,
                    initializer: .function(functionIR)
                )
                statements.append(.binding(binding))
                continue
            }

            if let variableDecl = node.as(VariableDeclSyntax.self) {
                statements.append(contentsOf: makeBindingList(from: variableDecl).map({ .binding($0) }))
                continue
            }

            if let expressionStmt = node.as(ExpressionStmtSyntax.self) {
                if let assignment = makeAssignment(from: expressionStmt.expression) {
                    statements.append(.assignment(assignment))
                } else {
                    statements.append(.expression(makeExpr(expressionStmt.expression)))
                }
                continue
            }

            if let expression = node.as(ExprSyntax.self) {
                if let assignment = makeAssignment(from: expression) {
                    statements.append(.assignment(assignment))
                } else {
                    statements.append(.expression(makeExpr(expression)))
                }
                continue
            }
        }

        return ModuleIR(statements: statements)
    }

    private func makeDefinition(from node: StructDeclSyntax) -> DefinitionIR? {
        let members: MemberBlockItemListSyntax = node.memberBlock.members

        var instanceBindings: [BindingIR] = []
        var staticBindings: [BindingIR] = []
        var storedProperties: [BindingIR] = []
        var hasExplicitInitializer = false

        for member in members {
            if let structDecl = member.decl.as(StructDeclSyntax.self),
               let definition = makeDefinition(from: structDecl) {
                staticBindings.append(
                    BindingIR(
                        name: structDecl.name.text,
                        type: nil,
                        initializer: .definition(definition)
                    )
                )
                continue
            }

            if let variable = member.decl.as(VariableDeclSyntax.self) {
                let isStatic = hasStaticModifier(variable.modifiers)
                if let computedBinding = makeComputedBinding(from: variable) {
                    if isStatic {
                        staticBindings.append(computedBinding)
                    } else {
                        instanceBindings.append(computedBinding)
                    }
                    continue
                }

                let bindings = makeBindingList(from: variable)
                if isStatic {
                    staticBindings.append(contentsOf: bindings)
                } else {
                    storedProperties.append(contentsOf: bindings)
                    instanceBindings.append(contentsOf: bindings)
                }
                continue
            }

            if let functionDecl = member.decl.as(FunctionDeclSyntax.self) {
                let binding = makeFunctionBinding(from: functionDecl)
                if hasStaticModifier(functionDecl.modifiers) {
                    staticBindings.append(binding)
                } else {
                    instanceBindings.append(binding)
                }
                continue
            }

            if let initializerDecl = member.decl.as(InitializerDeclSyntax.self) {
                instanceBindings.append(makeInitializerBinding(from: initializerDecl))
                hasExplicitInitializer = true
                continue
            }

            print("Unhandled member in View definition: \(member.decl.trimmedDescription)")
        }

        if !hasExplicitInitializer {
            instanceBindings.insert(synthesizeInitializer(from: storedProperties), at: 0)
        }

        return DefinitionIR(
            name: node.name.text,
            inheritedTypes: makeInheritedTypes(node),
            bindings: instanceBindings,
            staticBindings: staticBindings
        )
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
        return FunctionParameterIR(label: label, name: name, type: parameter.type.trimmedDescription, defaultValue: defaultValue)
    }

    private func makeBindingList(from node: VariableDeclSyntax) -> [BindingIR] {
        return node.bindings.compactMap { binding in
            guard let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self) else { return nil }
            let initializerExpr = binding.initializer.map { makeExpr($0.value) }
            let typeAnnotation = binding.typeAnnotation?.type.trimmedDescription
            return BindingIR(
                name: identifierPattern.identifier.text,
                type: typeAnnotation,
                initializer: initializerExpr
            )
        }
    }

    private func makeFunctionBinding(from node: FunctionDeclSyntax) -> BindingIR {
        let functionIR = makeFunctionIR(from: node)
        return BindingIR(
            name: node.name.text,
            type: nil,
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
            type: typeAnnotation,
            initializer: initializer
        )
    }

    private func makeExpr(_ expr: ExprSyntax) -> ExprIR {
        if let literal = expr.as(IntegerLiteralExprSyntax.self),
           let value = Int(literal.literal.text) {
            return .int(value)
        }

        if let literal = expr.as(FloatLiteralExprSyntax.self),
           let value = Double(literal.literal.text) {
            return .double(value)
        }

        if let literal = expr.as(StringLiteralExprSyntax.self) {
            let containsInterpolation = literal.segments.contains(where: { $0.as(ExpressionSegmentSyntax.self) != nil })

            if !containsInterpolation {
                let text = literal.segments.compactMap { segment -> String? in
                    segment.as(StringSegmentSyntax.self)?.content.text
                }.joined()
                return .string(text)
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
            return .bool(literal.literal.text == "true")
        }

        if let array = expr.as(ArrayExprSyntax.self) {
            let elements = array.elements.map { makeExpr($0.expression) }
            return .array(elements)
        }

        if expr.trimmedDescription == "\\.self" {
            return .keyPath(.self)
        }

        if let prefix = expr.as(PrefixOperatorExprSyntax.self),
           let op = unaryOperator(from: prefix) {
            return .unary(op: op, operand: makeExpr(prefix.expression))
        }

        if let sequence = expr.as(SequenceExprSyntax.self),
           let binaryExpr = makeBinaryExpr(from: Array(sequence.elements)) {
            return binaryExpr
        }

        if let reference = expr.as(DeclReferenceExprSyntax.self) {
            return .identifier(reference.baseName.text)
        }

        if let member = expr.as(MemberAccessExprSyntax.self) {
            return .member(base: member.base.map(makeExpr), name: member.declName.baseName.text)
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
        let parameters = makeClosureParameters(from: closure.signature)
        return FunctionIR(parameters: parameters, returnType: nil, body: statements)
    }

    private func makeInheritedTypes(_ node: SyntaxProtocol) -> [String] {
        let inheritance: InheritanceClauseSyntax?
        switch node {
        case let structDecl as StructDeclSyntax:
            inheritance = structDecl.inheritanceClause
        case let classDecl as ClassDeclSyntax:
            inheritance = classDecl.inheritanceClause
        default:
            inheritance = nil
        }
        guard let inheritance else { return [] }
        return inheritance.inheritedTypes.map { $0.type.trimmedDescription }
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
            type: binding.typeAnnotation?.type.trimmedDescription,
            initializer: .function(functionIR)
        )
    }

    private func makeInitializerBinding(from node: InitializerDeclSyntax) -> BindingIR {
        let params = node.signature.parameterClause.parameters.map(makeParameter)
        let bodyStatements = node.body.map(makeStatements) ?? []
        let functionIR = FunctionIR(parameters: params, returnType: nil, body: bodyStatements)
        return BindingIR(name: "init", type: nil, initializer: .function(functionIR))
    }

    private func synthesizeInitializer(from properties: [BindingIR]) -> BindingIR {
        let parameters = properties.map { property in
            FunctionParameterIR(label: property.name, name: property.name, type: property.type, defaultValue: property.initializer)
        }
        let assignments: [StatementIR] = properties.map { property in
            let target = ExprIR.member(base: .identifier("self"), name: property.name)
            let value = ExprIR.identifier(property.name)
            return .assignment(AssignmentIR(target: target, value: value))
        }
        let functionIR = FunctionIR(parameters: parameters, returnType: nil, body: assignments)
        return BindingIR(name: "init", type: nil, initializer: .function(functionIR))
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

    private func hasStaticModifier(_ modifiers: DeclModifierListSyntax?) -> Bool {
        guard let modifiers else { return false }
        for modifier in modifiers {
            switch modifier.name.tokenKind {
            case .keyword(.static), .keyword(.class):
                return true
            default:
                continue
            }
        }
        return false
    }

    private func makeAssignment(from item: CodeBlockItemSyntax) -> AssignmentIR? {
        guard let expression = item.item.as(ExprSyntax.self) else { return nil }
        return makeAssignment(from: expression)
    }

    private func makeAssignment(from expression: ExprSyntax) -> AssignmentIR? {
        guard let sequence = expression.as(SequenceExprSyntax.self) else { return nil }
        let elements = Array(sequence.elements)
        if let assignmentIndex = elements.firstIndex(where: { $0.as(AssignmentExprSyntax.self) != nil }),
           assignmentIndex > 0,
           assignmentIndex < elements.count - 1 {
            let target = makeExpr(elements[assignmentIndex - 1])
            let valueElements = elements[(assignmentIndex + 1)...]
            let value = makeExpr(fromSequenceElements: valueElements)
            return AssignmentIR(target: target, value: value)
        }

        if elements.count >= 3,
           let op = compoundAssignmentOperator(from: elements[1]) {
            let rhsElements = elements[2...]
            guard !rhsElements.isEmpty else { return nil }
            let target = makeExpr(elements[0])
            let rhs = makeExpr(fromSequenceElements: rhsElements)
            let value = ExprIR.binary(op: op, lhs: target, rhs: rhs)
            return AssignmentIR(target: target, value: value)
        }

        return nil
    }

    private func makeExpr(fromSequenceElements elements: ArraySlice<ExprSyntax>) -> ExprIR {
        let list = Array(elements)
        if list.isEmpty {
            return .unknown("")
        }
        if list.count == 1, let first = list.first {
            return makeExpr(first)
        }
        return makeBinaryExpr(from: list) ?? .unknown(list.map { $0.trimmedDescription }.joined(separator: " "))
    }

    private func makeBinaryExpr(from elements: [ExprSyntax]) -> ExprIR? {
        guard elements.count >= 3,
              elements.count % 2 == 1,
              !elements.contains(where: { $0.as(AssignmentExprSyntax.self) != nil }) else {
            return nil
        }

        var values: [ExprIR] = []
        var operators: [BinaryOperatorIR] = []

        for (index, element) in elements.enumerated() {
            if index % 2 == 0 {
                values.append(makeExpr(element))
            } else {
                guard let op = binaryOperator(from: element) else {
                    return nil
                }

                while let last = operators.last,
                      last.precedence >= op.precedence,
                      values.count >= 2 {
                    let rhs = values.removeLast()
                    let lhs = values.removeLast()
                    let popped = operators.removeLast()
                    values.append(.binary(op: popped, lhs: lhs, rhs: rhs))
                }

                operators.append(op)
            }
        }

        while let op = operators.popLast(),
              values.count >= 2 {
            let rhs = values.removeLast()
            let lhs = values.removeLast()
            values.append(.binary(op: op, lhs: lhs, rhs: rhs))
        }

        return values.first
    }

    private func binaryOperator(from expr: ExprSyntax) -> BinaryOperatorIR? {
        if let reference = expr.as(DeclReferenceExprSyntax.self) {
            return BinaryOperatorIR(rawValue: reference.baseName.text)
        }
        if let binary = expr.as(BinaryOperatorExprSyntax.self) {
            return BinaryOperatorIR(rawValue: binary.operator.text)
        }
        let token = expr.trimmedDescription
        return BinaryOperatorIR(rawValue: token)
    }

    private func compoundAssignmentOperator(from expr: ExprSyntax) -> BinaryOperatorIR? {
        let token = expr.trimmedDescription
        guard token.hasSuffix("="),
              token.count > 1 else {
            return nil
        }
        let opSymbol = String(token.dropLast())
        return BinaryOperatorIR(rawValue: opSymbol)
    }

    private func unaryOperator(from expr: PrefixOperatorExprSyntax) -> UnaryOperatorIR? {
        UnaryOperatorIR(rawValue: expr.operator.text)
    }

    private func makeClosureParameters(from signature: ClosureSignatureSyntax?) -> [FunctionParameterIR] {
        guard let signature, let clause = signature.parameterClause else {
            return []
        }

        switch clause {
        case .parameterClause(let parameterClause):
            return parameterClause.parameters.map(makeClosureParameter)
        case .simpleInput(let shorthandList):
            return shorthandList.map { shorthand in
                let name = shorthand.name.text
                let label = name == "_" ? nil : name
                return FunctionParameterIR(label: label, name: name, type: nil, defaultValue: nil)
            }
        }
    }

    private func makeClosureParameter(_ parameter: ClosureParameterSyntax) -> FunctionParameterIR {
        let firstName = parameter.firstName.text
        let label = firstName == "_" ? nil : firstName
        let name = parameter.secondName?.text ?? firstName
        return FunctionParameterIR(label: label, name: name, type: parameter.type?.trimmedDescription, defaultValue: nil)
    }
}
