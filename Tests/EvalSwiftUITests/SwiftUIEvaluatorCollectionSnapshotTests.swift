import SwiftUI
import Testing
@testable import EvalSwiftUI

@MainActor
struct SwiftUIEvaluatorCollectionSnapshotTests {
    @Test func supportsArrayBindings() throws {
        let source = """
        VStack {
            let labels = ["One", "Two"]
            Text("Done")
        }
        """

        try assertSnapshotsMatch(source: source) {
            VStack {
                Text("Done")
            }
        }
    }

    @Test func supportsRangeBindings() throws {
        let source = """
        VStack {
            let exclusives = 0..<3
            let inclusives = 1...3
            Text("Done")
        }
        """

        try assertSnapshotsMatch(source: source) {
            VStack {
                Text("Done")
            }
        }
    }

    @Test func rendersForEachFromArray() throws {
        let source = """
        VStack {
            let users = ["Ava", "Ben"]
            ForEach(users) { user in
                Text(user)
            }
        }
        """

        try assertSnapshotsMatch(source: source) {
            VStack {
                Text("Ava")
                Text("Ben")
            }
        }
    }

    @Test func rendersForEachFromRange() throws {
        let source = """
        VStack {
            ForEach(0..<3) { index in
                Text("Row \\(index)")
            }
        }
        """

        try assertSnapshotsMatch(source: source) {
            VStack {
                Text("Row 0")
                Text("Row 1")
                Text("Row 2")
            }
        }
    }

    @Test func rendersForEachWithExplicitId() throws {
        let source = """
        VStack {
            let users = ["Ava", "Ben"]
            ForEach(users, id: \\.self) { user in
                Text(user)
            }
        }
        """

        try assertSnapshotsMatch(source: source) {
            VStack {
                Text("Ava")
                Text("Ben")
            }
        }
    }

    @Test func rendersForEachUsingShorthandParameter() throws {
        let source = """
        VStack {
            let users = ["Ava", "Ben"]
            ForEach(users) {
                Text($0)
            }
        }
        """

        try assertSnapshotsMatch(source: source) {
            VStack {
                Text("Ava")
                Text("Ben")
            }
        }
    }

    @Test func rendersForEachUsingDictionaryKeyPath() throws {
        let source = """
        VStack {
            let users = [["id": 1, "name": "Ava"], ["id": 2, "name": "Ben"]]
            ForEach(users, id: \\.id) { _ in
                Text("Row")
            }
        }
        """

        try assertSnapshotsMatch(source: source) {
            VStack {
                Text("Row")
                Text("Row")
            }
        }
    }

    @Test func rendersVerticalScrollView() throws {
        let source = """
        ScrollView {
            ForEach(0..<3) { index in
                Text("Row \\(index)")
            }
        }
        """

        try assertSnapshotsMatch(source: source) {
            ScrollView {
                VStack(spacing: 0) {
                    Text("Row 0")
                    Text("Row 1")
                    Text("Row 2")
                }
            }
        }
    }

    @Test func rendersHorizontalScrollView() throws {
        let source = """
        ScrollView(.horizontal, showsIndicators: false) {
            ForEach(0..<3) { index in
                Text("Item \\(index)")
            }
        }
        """

        try assertSnapshotsMatch(source: source) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    Text("Item 0")
                    Text("Item 1")
                    Text("Item 2")
                }
            }
        }
    }

    @Test func rendersCustomViewUsingBuilder() throws {
        try assertSnapshotsMatch(
            source: """
            Badge("Beta")
            """,
            viewBuilders: [BadgeViewBuilder()]
        ) {
            Badge(label: "Beta")
        }
    }
}
