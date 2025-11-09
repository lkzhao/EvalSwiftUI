import SwiftUI

public protocol SwiftUIViewBuilder {
    var name: String { get }
    func makeView(arguments: [ResolvedArgument]) throws -> AnyView
}
