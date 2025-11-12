import Foundation

public final class RuntimeInstance: RuntimeScope, CustomStringConvertible {
    public var storage: [String: RuntimeValue] = [:] {
        didSet {
            mutationHandler?()
        }
    }
    public let parent: RuntimeScope?
    var mutationHandler: (() -> Void)?

    public init(parent: RuntimeScope? = nil) {
        self.parent = parent
    }
}
