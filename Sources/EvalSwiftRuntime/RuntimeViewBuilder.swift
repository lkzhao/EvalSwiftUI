import SwiftUI

public protocol RuntimeViewBuilder {
    var typeName: String { get }
    @MainActor
    func makeSwiftUIView(arguments: [RuntimeArgument], module: RuntimeModule, scope: RuntimeScope) throws -> AnyView
}
