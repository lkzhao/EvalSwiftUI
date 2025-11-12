import SwiftUI

public struct RuntimeView: CustomStringConvertible {
    public let typeName: String
    public let arguments: [RuntimeArgument]

    public init(typeName: String, arguments: [RuntimeArgument]) {
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
    func makeSwiftUIView(module: RuntimeModule, scope: RuntimeScope? = nil) throws -> AnyView {
        let scope = scope ?? module.globalScope
        if let builder = module.builder(named: typeName) {
            return try builder.makeSwiftUIView(arguments: arguments, module: module, scope: scope)
        }
        if let definition = module.viewDefinition(named: typeName) {
            let renderer = try RuntimeViewRenderer(
                definition: definition,
                module: module,
                arguments: arguments,
                scope: scope,
            )
            return AnyView(RuntimeViewHost(renderer: renderer))
        }
        throw RuntimeError.unknownView(typeName)
    }
}
