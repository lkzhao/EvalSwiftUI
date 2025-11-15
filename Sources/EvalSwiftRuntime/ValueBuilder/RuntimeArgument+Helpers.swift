extension Array where Element == RuntimeArgument {
    func value(named name: String) -> RuntimeValue? {
        first(where: { $0.name == name })?.value
    }
}
