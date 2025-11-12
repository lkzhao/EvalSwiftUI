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
