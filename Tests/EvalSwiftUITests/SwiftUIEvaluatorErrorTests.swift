import Testing
@testable import EvalSwiftUI

enum TestFailure: Error {
    case expected(String)
}

struct SwiftUIEvaluatorErrorTests {
    @Test func textRejectsStringInterpolation() throws {
        let source = """
        Text("Hello \\(42)")
        """

        do {
            _ = try evalSwiftUI(source)
            throw TestFailure.expected("Expected invalid arguments error")
        } catch let error as SwiftUIEvaluatorError {
            guard case .invalidArguments(let message) = error else {
                throw TestFailure.expected("Unexpected error: \(error)")
            }
            #expect(message.contains("String interpolation"))
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
            throw TestFailure.expected("Expected unsupported expression error")
        } catch let error as SwiftUIEvaluatorError {
            guard case .unsupportedExpression(let description) = error else {
                throw TestFailure.expected("Unexpected error: \(error)")
            }
            #expect(description.contains("123"))
        }
    }
}
