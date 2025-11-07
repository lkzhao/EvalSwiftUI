import SwiftUI
import Testing
@testable import EvalSwiftUI

@MainActor
struct SwiftUIEvaluatorSnapshotTests {
    @Test func textMatchesSnapshot() throws {
        #expectSnapshot(
            Text("Snapshot")
                .font(.title)
                .padding(8)
        )
    }

    @Test func nestedStacksMatchSnapshot() throws {
        #expectSnapshot(
            VStack(alignment: .leading, spacing: 12) {
                Text("Primary")
                    .font(.headline)
                HStack(spacing: 4) {
                    Text("L")
                    Text("R")
                }
            }
            .padding()
        )
    }
}
