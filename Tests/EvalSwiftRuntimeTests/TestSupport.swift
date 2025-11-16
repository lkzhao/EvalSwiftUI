enum TestFailure: Error {
    case expected(String)
}

@freestanding(expression)
macro expectSnapshot(
    _ view: Any
) -> Void = #externalMacro(module: "Macros", type: "SnapshotExpectationMacro")
