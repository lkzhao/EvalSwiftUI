// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftSyntax
import SwiftParser
import SwiftUI

public func evalSwiftUI(_ source: String) throws -> AnyView {
    let tree: SourceFileSyntax = Parser.parse(source: source)
    let evaluator = SwiftUIEvaluator()
    let view = try evaluator.evaluate(syntax: tree)
    return AnyView(view)
}
