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
    public func makeSwiftUIView(parameters: [RuntimeParameter], module: RuntimeModule, instance: RuntimeInstance) throws -> AnyView {
        var spacing: CGFloat?
        var childViews: [AnyView] = []

        for parameter in parameters {
            if parameter.label == "spacing" {
                spacing = parameter.value.asDouble.map { CGFloat($0) }
                continue
            }

            switch parameter.value {
            case .array(let values):
                for value in values {
                    childViews.append(try module.realize(runtimeValue: value, instance: instance))
                }
            case .view(let runtimeView):
                childViews.append(try module.makeSwiftUIView(typeName: runtimeView.typeName, parameters: runtimeView.parameters, instance: instance))
            case .function(let function):
                let views = try module.runtimeViews(from: function, instance: instance)
                for runtimeView in views {
                    childViews.append(try module.makeSwiftUIView(typeName: runtimeView.typeName, parameters: runtimeView.parameters, instance: instance))
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
