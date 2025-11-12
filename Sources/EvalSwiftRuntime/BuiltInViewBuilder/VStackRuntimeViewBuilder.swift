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
                    childViews.append(try runtimeView.makeSwiftUIView(scope: scope))
                }
            case .view(let runtimeView):
                childViews.append(try runtimeView.makeSwiftUIView(scope: scope))
            case .function(let function):
                let views = try StatementInterpreter(scope: scope)
                    .executeAndCollectRuntimeViews(statements: function.body)
                for runtimeView in views {
                    childViews.append(try runtimeView.makeSwiftUIView(scope: scope))
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
