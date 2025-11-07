import SwiftUI

public protocol SwiftUIViewBuilder {
    var name: String { get }
    func makeView(arguments: [ResolvedArgument]) throws -> AnyView
}

public protocol SwiftUIModifierBuilder {
    var name: String { get }
    func apply(arguments: [ResolvedArgument], to base: AnyView) throws -> AnyView
}
