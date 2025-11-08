// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

@MainActor
public func evalSwiftUI(
    _ source: String,
    context: (any SwiftUIEvaluatorContext)? = nil
) throws -> AnyView {
    let evaluator = SwiftUIEvaluator(context: context)
    let view = try evaluator.evaluate(source: source)
    return AnyView(view)
}

@MainActor
public func evalSwiftUI(
    _ source: () -> String,
    context: (any SwiftUIEvaluatorContext)? = nil
) throws -> AnyView {
    try evalSwiftUI(source(), context: context)
}
