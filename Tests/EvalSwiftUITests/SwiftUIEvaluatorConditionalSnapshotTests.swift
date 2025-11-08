import SwiftUI
import Testing
@testable import EvalSwiftUI

@MainActor
struct SwiftUIEvaluatorConditionalSnapshotTests {
    @Test func rendersConditionalContent() throws {
        #expectSnapshot(
            VStack {
                let showGreeting = true
                if showGreeting {
                    Text("Hello")
                }
            }
        )
    }

    @Test func rendersConditionalElseBranches() throws {
        let source = """
        VStack {
            let showPrimary = false
            let showSecondary = true
            if showPrimary {
                Text("Primary")
            } else if showSecondary {
                Text("Secondary")
            } else {
                Text("Fallback")
            }
        }
        """

        try assertSnapshotsMatch(source: source) {
            VStack {
                Text("Secondary")
            }
        }
    }

    @Test func rendersOptionalBinding() throws {
        #expectSnapshot(
            VStack {
                let optionalGreeting: String? = "Hello"
                if let greeting = optionalGreeting {
                    Text(greeting)
                }
            }
        )
    }

    @Test func rendersOptionalBindingElseBranch() throws {
        #expectSnapshot(
            VStack {
                let optionalGreeting: String? = nil
                if let greeting = optionalGreeting {
                    Text(greeting)
                } else {
                    Text("Fallback")
                }
            }
        )
    }

    @Test func rendersOptionalBindingFromContext() throws {
        let source = """
        VStack {
            if let username = username {
                Text(username)
            }
        }
        """
        let context = DictionaryContext(values: ["username": .optional(.string("Morgan"))])

        try assertSnapshotsMatch(source: source, context: context) {
            VStack {
                Text("Morgan")
            }
        }
    }

    @Test func rendersOptionalBindingShorthand() throws {
        #expectSnapshot(
            VStack {
                let username: String? = "Taylor"
                if let username {
                    Text(username)
                }
            }
        )
    }

    @Test func rendersOptionalBindingShorthandFromContext() throws {
        let source = """
        VStack {
            if let username {
                Text(username)
            }
        }
        """
        let context = DictionaryContext(values: ["username": .optional(.string("Morgan"))])

        try assertSnapshotsMatch(source: source, context: context) {
            VStack {
                Text("Morgan")
            }
        }
    }

    @Test func supportsLetBindingsInsideClosures() throws {
        #expectSnapshot(
            VStack {
                let value = "scoped"
                Text(value)
            }
        )
    }

    @Test func propagatesBindingsToNestedClosures() throws {
        #expectSnapshot(
            VStack {
                let label = "outer"
                HStack {
                    Text(label)
                }
            }
        )
    }
}
