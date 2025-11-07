import SwiftUI

public struct ViewContent {
    private let renderers: [(ExpressionScope) throws -> AnyView]
    let parameters: [String]

    init(renderers: [(ExpressionScope) throws -> AnyView], parameters: [String]) {
        self.renderers = renderers
        self.parameters = parameters
    }

    public func renderViews() throws -> [AnyView] {
        try renderViews(overriding: [:])
    }

    func renderViews(overriding scopeOverrides: ExpressionScope) throws -> [AnyView] {
        try renderers.map { try $0(scopeOverrides) }
    }
}
