import SwiftUI

public protocol RuntimeModifierBuilder {
    var modifierName: String { get }
    @MainActor
    func applyModifier(
        to view: AnyView,
        arguments: [RuntimeArgument],
        scope: RuntimeScope
    ) throws -> AnyView
}
