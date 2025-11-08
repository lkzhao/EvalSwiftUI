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

    @Test func rendersSwitchLiteralCases() throws {
        #expectSnapshot(
            VStack {
                let status = "ready"
                switch status {
                case "ready":
                    Text("Ready")
                case "done":
                    Text("Done")
                default:
                    Text("Unknown")
                }
            }
        )
    }

    @Test func rendersSwitchBindings() throws {
        #expectSnapshot(
            VStack {
                let username: String? = "Morgan"
                switch username {
                case let value?:
                    Text(value)
                default:
                    Text("Anonymous")
                }
            }
        )
    }

    @Test func evaluatesArithmeticComparisons() throws {
        let source = """
        VStack {
            let width = 8
            if width * 2 >= 16 {
                Text("Wide")
            } else {
                Text("Narrow")
            }
        }
        """

        try assertSnapshotsMatch(source: source) {
            VStack {
                Text("Wide")
            }
        }
    }

    @Test func supportsLogicalOperators() throws {
        #expectSnapshot(
            VStack {
                let count = 4
                let isHidden = false
                let hasOverride = true

                if count > 3 && !isHidden {
                    Text("Primary")
                }

                if isHidden || hasOverride {
                    Text("Override")
                }
            }
        )
    }

    @Test func resolvesNilCoalescingExpressions() throws {
        #expectSnapshot(
            VStack {
                let greeting: String? = nil
                Text(greeting ?? "Guest")
            }
        )
    }

    @Test func supportsUnaryOperators() throws {
        #expectSnapshot(
            VStack {
                let isHidden = false
                if !isHidden {
                    Text("Visible")
                }

                let baseOffset = 2
                let offset = -baseOffset
                Text("Offset \(offset)")
            }
        )
    }
}
