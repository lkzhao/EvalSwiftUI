import Foundation

public final class RuntimeInstance: RuntimeScope {
    public var storage: [String: RuntimeValue] = [:] {
        didSet {
            mutationHandler?()
        }
    }
    public weak var parent: RuntimeScope?
    var mutationHandler: (() -> Void)?

    public init(parent: RuntimeScope? = nil) {
        self.parent = parent
    }
}
