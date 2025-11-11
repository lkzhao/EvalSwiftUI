//
//  TextRuntimeViewBuilder.swift
//  EvalSwiftUI
//
//  Created by Luke Zhao on 11/10/25.
//

import SwiftUI

public struct TextRuntimeViewBuilder: RuntimeViewBuilder {
    public let typeName = "Text"

    public init() {
    }

    @MainActor
    public func makeSwiftUIView(parameters: [RuntimeParameter], module: RuntimeModule, scope: RuntimeScope) throws -> AnyView {
        guard let first = parameters.first, let string = first.value.asString else {
            throw RuntimeError.invalidViewArgument("Text expects a string parameter")
        }
        return AnyView(Text(string))
    }
}
