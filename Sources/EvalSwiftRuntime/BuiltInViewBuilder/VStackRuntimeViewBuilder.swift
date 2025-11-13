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
                    guard case .instance(let instance) = value else {
                        throw RuntimeError.invalidViewArgument("VStack only accepts views as children.")
                    }
                    childViews.append(try instance.makeSwiftUIView())
                }
            case .instance(let instance):
                childViews.append(try instance.makeSwiftUIView())
            case .function(let function):
                let views = try function.renderRuntimeViews()
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
