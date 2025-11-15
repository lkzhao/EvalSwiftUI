//
//  File.swift
//  EvalSwiftUI
//
//  Created by Luke Zhao on 11/10/25.
//

import Foundation
import SwiftUI
import EvalSwiftRuntime
import EvalSwiftIR

@MainActor
public func evalSwiftUI(
    _ source: String
) throws -> AnyView {
    let module = try RuntimeModule(source: source)
    return try module.makeTopLevelSwiftUIViews()
}

@MainActor
public func evalSwiftUI(
    _ source: () -> String
) throws -> AnyView {
    try evalSwiftUI(source())
}
