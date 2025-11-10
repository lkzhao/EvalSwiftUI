import SwiftUI
import SwiftUI

public protocol RuntimeViewBuilder {
    var typeName: String { get }
    func makeSwiftUIView(parameters: [RuntimeView.Parameter], module: RuntimeModule, scope: RuntimeScope) throws -> AnyView
}
