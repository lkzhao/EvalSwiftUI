extension Dictionary where Key == String, Value == SwiftValue {
    func cloningForCapture() -> [String: SwiftValue] {
        var cloned: [String: SwiftValue] = [:]
        cloned.reserveCapacity(count)
        for (key, value) in self {
            if value.stateIdentifierValue() != nil {
                cloned[key] = value
            } else {
                cloned[key] = value.copy()
            }
        }
        return cloned
    }
}
