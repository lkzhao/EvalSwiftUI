public protocol SwiftUIEvaluatorContext {
    /// Returns a previously captured value for the provided identifier.
    /// - Parameter identifier: The bare identifier name referenced inside the evaluated source.
    /// - Returns: A `SwiftValue` to inject into evaluation, or `nil` to fall back to normal resolution.
    func value(for identifier: String) -> SwiftValue?
}
