import SwiftUI
import Testing
@testable import EvalSwiftUI

@MainActor
struct SwiftUIEvaluatorInterpolationSnapshotTests {
    @Test func rendersTextWithStringInterpolation() throws {
        #expectSnapshot(
            VStack {
                let name = "Taylor"
                Text("Hello \(name)")
            }
        )
    }

    @Test func rendersTextUsingExternalContext() throws {
        let source = """
        Text("Welcome \\(username)")
        """
        let context = DictionaryContext(values: ["username": .string("Morgan")])

        try assertSnapshotsMatch(source: source, context: context) {
            Text("Welcome Morgan")
        }
    }

    @Test func rendersTextWithBooleanInterpolation() throws {
        let source = """
        VStack {
            let isEnabled = true
            Text("Enabled: \\(isEnabled)")
        }
        """

        try assertSnapshotsMatch(source: source) {
            VStack {
                Text("Enabled: true")
            }
        }
    }

    @Test func rendersTextUsingBooleanContext() throws {
        let source = """
        Text("Flag: \\(isEnabled)")
        """
        let context = DictionaryContext(values: ["isEnabled": .bool(true)])

        try assertSnapshotsMatch(source: source, context: context) {
            Text("Flag: true")
        }
    }
}
