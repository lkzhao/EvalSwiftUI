//
//  VStackRuntimeViewBuilder.swift
//  EvalSwiftUI
//
//  Created by Luke Zhao on 11/10/25.
//

import SwiftUI

public struct VStackRuntimeViewBuilder: RuntimeViewBuilder {
    public let typeName = "VStack"

    public init() {
    }

    @MainActor
    public func makeSwiftUIView(arguments: [RuntimeArgument], scope: RuntimeScope) throws -> AnyView {
        var spacing: CGFloat?
        var childViews: [AnyView] = []

        for parameter in arguments {
            if parameter.label == "spacing" {
                spacing = parameter.value.asDouble.map { CGFloat($0) }
                continue
            }

            switch parameter.value {
            case .array(let values):
                for value in values {
                    guard case .view(let runtimeView) = value else {
                        throw RuntimeError.invalidViewArgument("VStack only accepts views as children.")
                    }
                    childViews.append(try runtimeView.makeSwiftUIView())
                }
            case .view(let runtimeView):
                childViews.append(try runtimeView.makeSwiftUIView())
            case .function(let function):
                let views = try function.renderRuntimeViews(scope: scope)
                for runtimeView in views {
                    childViews.append(try runtimeView.makeSwiftUIView())
                }
            default:
                continue
            }
        }

        return AnyView(VStack(spacing: spacing) {
            ForEach(Array(childViews.enumerated()), id: \.0) { _, view in
                view
            }
        })
    }
}
