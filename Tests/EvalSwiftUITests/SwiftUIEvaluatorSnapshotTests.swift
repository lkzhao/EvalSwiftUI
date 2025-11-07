import SwiftUI
import Testing
@testable import EvalSwiftUI

@MainActor
struct SwiftUIEvaluatorSnapshotTests {
    @Test func textMatchesSnapshot() throws {
        let source = """
        Text("Snapshot")
            .font(.title)
            .padding(8)
        """

        try assertSnapshotsMatch(source: source) {
            Text("Snapshot")
                .font(.title)
                .padding(8)
        }
    }

    @Test func nestedStacksMatchSnapshot() throws {
        let source = """
        VStack(alignment: .leading, spacing: 12) {
            Text("Primary")
                .font(.headline)
            HStack(spacing: 4) {
                Text("L")
                Text("R")
            }
        }
        .padding()
        """

        try assertSnapshotsMatch(source: source) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Primary")
                    .font(.headline)
                HStack(spacing: 4) {
                    Text("L")
                    Text("R")
                }
            }
            .padding()
        }
    }
}
