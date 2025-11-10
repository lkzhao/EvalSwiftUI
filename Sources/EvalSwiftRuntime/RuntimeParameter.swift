public struct RuntimeParameter {
    public let label: String?
    public let value: RuntimeValue

    public init(label: String?, value: RuntimeValue) {
        self.label = label
        self.value = value
    }
}
