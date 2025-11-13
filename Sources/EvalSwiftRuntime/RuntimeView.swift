import SwiftUI

public struct RuntimeView: CustomStringConvertible {
    public let typeName: String
    public let arguments: [RuntimeArgument]
    public let scope: RuntimeScope

    public init(typeName: String, arguments: [RuntimeArgument] = [], scope: RuntimeScope) {
        self.typeName = typeName
        self.arguments = arguments
        self.scope = scope
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
    func makeSwiftUIView() throws -> AnyView {
        if let builder = try? scope.builder(named: typeName) {
            return try builder.makeSwiftUIView(arguments: arguments, scope: scope)
        }
        if let type = try? scope.type(named: typeName) {
            let renderer = try RuntimeViewRenderer(type: type, arguments: arguments)
            return AnyView(RuntimeViewHost(renderer: renderer))
        }
        throw RuntimeError.unknownView(typeName)
    }
}
