extension Dictionary where Key == String, Value == SwiftValue {
    func cloningForCapture() -> [String: SwiftValue] {
        var cloned: [String: SwiftValue] = [:]
        cloned.reserveCapacity(count)
        for (key, value) in self {
            cloned[key] = value.copy()
        }
        return cloned
    }
}
