import SwiftUI
import Testing
@testable import EvalSwiftUI

@MainActor
struct SwiftUIEvaluatorBasicSnapshotTests {
    @Test func rendersTextLiteral() throws {
        #expectSnapshot(
            Text("Hello, SwiftUI!")
        )
    }

    @Test func rendersTextWithModifiers() throws {
        #expectSnapshot(
            Text("Hello, SwiftUI!")
                .font(.title)
                .padding()
        )
    }

    @Test func rendersVStackWithChildText() throws {
        #expectSnapshot(
            VStack {
                Text("Hello, SwiftUI!")
                    .font(.title)
                    .padding()
            }
        )
    }

    @Test func rendersImageWithModifiers() throws {
        #expectSnapshot(
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
        )
    }

    @Test func rendersSpacerInsideHStack() throws {
        #expectSnapshot(
            HStack(spacing: 0) {
                Text("Leading")
                    .foregroundStyle(.blue)
                Spacer(minLength: 8)
                Text("Trailing")
                    .foregroundStyle(.green)
            }
            .frame(width: 160)
        )
    }

    @Test func rendersNestedStacks() throws {
        #expectSnapshot(
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 4) {
                    Text("Left")
                    Text("Right")
                }
                Text("Bottom")
            }
        )
    }

    @Test func rendersAdvancedModifiers() throws {
        #expectSnapshot(
            Text("Styled")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .padding(.horizontal, 8)
                .padding(4)
                .foregroundStyle(.red)
                .frame(width: 120, height: 60, alignment: .leading)
                .frame(minWidth: 60, maxWidth: .infinity, alignment: .center)
        )
    }

    @Test func rendersZStack() throws {
        #expectSnapshot(
            ZStack(alignment: .topLeading) {
                Text("Background")
                    .padding(12)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Foreground")
                        .font(.headline)
                    Text("Detail")
                        .font(.caption)
                }
            }
        )
    }

    @Test func rendersBackgroundAndOverlayModifiers() throws {
        #expectSnapshot(
            Text("Decorated")
                .padding(12)
                .background(alignment: .bottomTrailing) {
                    VStack(spacing: 2) {
                        Text("BG Title")
                            .font(.caption)
                        Text("BG Detail")
                            .font(.caption2)
                    }
                    .padding(4)
                }
                .overlay {
                    VStack(spacing: 2) {
                        Text("Overlay Top")
                        Text("Overlay Bottom")
                    }
                }
        )
    }
}
