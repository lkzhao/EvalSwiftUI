import SwiftUI

public protocol RuntimeViewBuilder {
    var typeName: String { get }
    @MainActor
    func makeSwiftUIView(arguments: [RuntimeArgument], scope: RuntimeScope) throws -> AnyView
}
