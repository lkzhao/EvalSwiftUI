import SwiftUI

public struct RuntimeView: CustomStringConvertible {
    public let typeName: String
    public let arguments: [RuntimeArgument]

    public init(typeName: String, arguments: [RuntimeArgument] = []) {
        self.typeName = typeName
        self.arguments = arguments
    }

    public var description: String {
        let params = arguments.map { param in
            let label = param.label.map { "\($0):" } ?? ""
            return "\(label)\(param.value)"
        }.joined(separator: ", ")
        return "RuntimeView(type: \(typeName), params: [\(params)])"
    }
}

extension RuntimeView {
    @MainActor
    func makeSwiftUIView(scope: RuntimeScope) throws -> AnyView {
        if let builder = scope.builder(named: typeName) {
            return try builder.makeSwiftUIView(arguments: arguments, scope: scope)
        }
        if let definition = scope.viewDefinition(named: typeName) {
            let renderer = try RuntimeViewRenderer(
                definition: definition,
                arguments: arguments,
                scope: scope,
            )
            return AnyView(RuntimeViewHost(renderer: renderer))
        }
        throw RuntimeError.unknownView(typeName)
    }
}
