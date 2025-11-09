public protocol SwiftUIEvaluatorContext {
    /// Returns a previously captured value for the provided identifier.
    /// - Parameter identifier: The bare identifier name referenced inside the evaluated source.
    /// - Returns: A `SwiftValue` to inject into evaluation, or `nil` to fall back to normal resolution.
    func value(for identifier: String) -> SwiftValue?

    /// Writes a value for the provided identifier so subsequent lookups can observe the mutation.
    /// Default implementations may choose to ignore writes if they are read-only.
    func setValue(_ value: SwiftValue?, for identifier: String)
}

public extension SwiftUIEvaluatorContext {
    func setValue(_ value: SwiftValue?, for identifier: String) {}
}
