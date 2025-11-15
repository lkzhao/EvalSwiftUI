import SwiftUI

public struct RuntimeModifierDefinition {
    public let parameters: [RuntimeParameter]
    public let apply: (AnyView, [RuntimeArgument], RuntimeScope) throws -> AnyView

    public init(
        parameters: [RuntimeParameter],
        apply: @escaping (AnyView, [RuntimeArgument], RuntimeScope) throws -> AnyView
    ) {
        self.parameters = parameters
        self.apply = apply
    }
}

public protocol RuntimeModifierBuilder {
    var name: String { get }
    var definitions: [RuntimeModifierDefinition] { get }
}
