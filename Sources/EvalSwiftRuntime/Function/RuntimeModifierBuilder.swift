import SwiftUI

public protocol RuntimeModifierBuilder {
    var name: String { get }

    var parameters: [RuntimeParameter] { get }

    func applyModifier(
        to view: AnyView,
        arguments: [RuntimeArgument],
        scope: RuntimeScope
    ) throws -> AnyView
}
