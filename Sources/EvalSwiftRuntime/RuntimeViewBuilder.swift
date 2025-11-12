import SwiftUI

public protocol RuntimeViewBuilder {
    var typeName: String { get }
    @MainActor
    func makeSwiftUIView(parameters: [RuntimeParameter], module: RuntimeModule, instance: RuntimeInstance) throws -> AnyView
}
