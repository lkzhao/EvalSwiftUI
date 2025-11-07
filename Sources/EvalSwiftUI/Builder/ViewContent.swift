import SwiftUI

public struct ViewContent {
    private let renderers: [() throws -> AnyView]

    init(renderers: [() throws -> AnyView]) {
        self.renderers = renderers
    }

    public func renderViews() throws -> [AnyView] {
        try renderers.map { try $0() }
    }
}
