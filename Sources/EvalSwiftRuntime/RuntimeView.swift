 public struct RuntimeView: CustomStringConvertible {
     public struct Parameter {
        public let label: String?
        public let value: RuntimeValue

        public init(label: String?, value: RuntimeValue) {
            self.label = label
            self.value = value
        }
    }

    public let typeName: String
    public let parameters: [Parameter]

    public init(typeName: String, parameters: [Parameter]) {
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
