import SwiftUI
import SwiftUI

public protocol RuntimeViewBuilder {
    var typeName: String { get }
    func makeSwiftUIView(parameters: [RuntimeParameter], module: RuntimeModule, scope: RuntimeScope) throws -> AnyView
}
