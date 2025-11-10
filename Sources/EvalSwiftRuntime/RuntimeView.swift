public struct RuntimeView: CustomStringConvertible {
    public let typeName: String
    public let parameters: [RuntimeParameter]

    public init(typeName: String, parameters: [RuntimeParameter]) {
        self.typeName = typeName
        self.parameters = parameters
    }

    public var description: String {
        let params = parameters.map { param in
            let label = param.label.map { "\($0):" } ?? ""
            return "\(label)\(param.value)"
        }.joined(separator: ", ")
        return "RuntimeView(type: \(typeName), params: [\(params)])"
    }
}
