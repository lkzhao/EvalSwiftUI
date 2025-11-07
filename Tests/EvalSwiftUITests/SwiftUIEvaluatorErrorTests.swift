import Testing
@testable import EvalSwiftUI

enum TestFailure: Error {
    case expected(String)
}

struct SwiftUIEvaluatorErrorTests {
    @Test func textRejectsUnsupportedInterpolationValues() throws {
        let source = """
        Text("Hello \\(Text("World"))")
        """

        do {
            _ = try evalSwiftUI(source)
            throw TestFailure.expected("Expected invalid arguments error")
        } catch let error as SwiftUIEvaluatorError {
            guard case .invalidArguments(let message) = error else {
                throw TestFailure.expected("Unexpected error: \(error)")
            }
            #expect(message.contains("string, numeric, boolean, or optional"))
        }
    }

    @Test func fontRequiresKnownMember() throws {
        let source = """
        Text("Hi")
            .font(.unknown)
        """

        do {
            _ = try evalSwiftUI(source)
            throw TestFailure.expected("Expected invalid arguments error")
        } catch let error as SwiftUIEvaluatorError {
            guard case .invalidArguments(let message) = error else {
                throw TestFailure.expected("Unexpected error: \(error)")
            }
            #expect(message.contains("Unsupported font"))
        }
    }

    @Test func unsupportedExpressionsBubbleUp() throws {
        let source = """
        Text(123)
        """

        do {
            _ = try evalSwiftUI(source)
            throw TestFailure.expected("Expected invalid arguments error")
        } catch let error as SwiftUIEvaluatorError {
            guard case .invalidArguments(let message) = error else {
                throw TestFailure.expected("Unexpected error: \(error)")
            }
            #expect(message.contains("Text expects"))
        }
    }

    @Test func ifRequiresBooleanCondition() throws {
        let source = """
        VStack {
            if "invalid" {
                Text("Nope")
            }
        }
        """

        do {
            _ = try evalSwiftUI(source)
            throw TestFailure.expected("Expected invalid arguments error")
        } catch let error as SwiftUIEvaluatorError {
            guard case .invalidArguments(let message) = error else {
                throw TestFailure.expected("Unexpected error: \(error)")
            }
            #expect(message.contains("boolean value"))
        }
    }

    @Test func ifLetRequiresOptionalValue() throws {
        let source = """
        VStack {
            if let greeting = "Hi" {
                Text(greeting)
            }
        }
        """

        do {
            _ = try evalSwiftUI(source)
            throw TestFailure.expected("Expected invalid arguments error")
        } catch let error as SwiftUIEvaluatorError {
            guard case .invalidArguments(let message) = error else {
                throw TestFailure.expected("Unexpected error: \(error)")
            }
            #expect(message.contains("optional value"))
        }
    }

    @Test func forEachRequiresCollectionData() throws {
        let source = """
        VStack {
            ForEach(Text("nope")) { value in
                Text("Value: \\(value)")
            }
        }
        """

        do {
            _ = try evalSwiftUI(source)
            throw TestFailure.expected("Expected invalid arguments error")
        } catch let error as SwiftUIEvaluatorError {
            guard case .invalidArguments(let message) = error else {
                throw TestFailure.expected("Unexpected error: \(error)")
            }
            #expect(message.contains("array or range"))
        }
    }

    @Test func forEachRequiresParameter() throws {
        let source = """
        VStack {
            ForEach(["A", "B"]) {
                Text("No parameter")
            }
        }
        """

        do {
            _ = try evalSwiftUI(source)
            throw TestFailure.expected("Expected invalid arguments error")
        } catch let error as SwiftUIEvaluatorError {
            guard case .invalidArguments(let message) = error else {
                throw TestFailure.expected("Unexpected error: \(error)")
            }
            #expect(message.contains("exactly one parameter"))
        }
    }
}
