import CoreGraphics
import Foundation
import SwiftUI
import Testing
import EvalSwiftIR
@testable import EvalSwiftRuntime

enum RuntimeSnapshotError: Error {
    case failedToRenderImage
    case missingPixelData
}

struct RuntimeViewSnapshot: Equatable {
    let width: Int
    let height: Int
    private let pixelData: Data

    init(cgImage: CGImage) throws {
        width = cgImage.width
        height = cgImage.height
        pixelData = try RuntimeViewSnapshot.pixelData(from: cgImage)
    }

    private static func pixelData(from image: CGImage) throws -> Data {
        if let provider = image.dataProvider, let cfData = provider.data {
            return Data(referencing: cfData as NSData)
        }

        let bytesPerPixel = 4
        let bytesPerRow = image.width * bytesPerPixel
        let length = bytesPerRow * image.height
        var data = Data(count: length)
        let succeeded = data.withUnsafeMutableBytes { buffer -> Bool in
            guard let baseAddress = buffer.baseAddress else { return false }
            guard let context = CGContext(
                data: baseAddress,
                width: image.width,
                height: image.height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                return false
            }
            let rect = CGRect(x: 0, y: 0, width: image.width, height: image.height)
            context.draw(image, in: rect)
            return true
        }

        guard succeeded else {
            throw RuntimeSnapshotError.missingPixelData
        }

        return data
    }
}

enum RuntimeViewSnapshotRenderer {
    @MainActor
    static func snapshot<V: View>(from view: V) throws -> RuntimeViewSnapshot {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        renderer.isOpaque = false
        guard let image = renderer.cgImage else {
            throw RuntimeSnapshotError.failedToRenderImage
        }
        return try RuntimeViewSnapshot(cgImage: image)
    }
}

@MainActor
func assertSnapshotsMatch<V: View>(
    source: String,
    viewName: String = "SnapshotView",
    viewBuilders: [any RuntimeViewBuilder] = [],
    @ViewBuilder expected expectedView: () -> V
) throws {
    let moduleSource = runtimeModuleSource(for: source, viewName: viewName)
    let parser = SwiftIRParser()
    let moduleIR = parser.parseModule(source: moduleSource)
    let module = RuntimeModule(ir: moduleIR, viewBuilders: viewBuilders)
    let evaluatedView = try RuntimeView(typeName: viewName, arguments: []).makeSwiftUIView(scope: module)
    try assertViewMatch(evaluatedView, expectedView())
}

@MainActor
func assertTopLevelSnapshotsMatch<V: View>(
    source: String,
    viewBuilders: [any RuntimeViewBuilder] = [],
    @ViewBuilder expected expectedView: () -> V
) throws {
    let parser = SwiftIRParser()
    let moduleIR = parser.parseModule(source: source)
    let module = RuntimeModule(ir: moduleIR, viewBuilders: viewBuilders)
    let evaluatedView = try module.makeTopLevelSwiftUIViews()
    try assertViewMatch(evaluatedView, expectedView())
}

@MainActor
func assertViewMatch(_ view1: some View, _ view2: some View) throws {
    let snapshot1 = try RuntimeViewSnapshotRenderer.snapshot(from: view1)
    let snapshot2 = try RuntimeViewSnapshotRenderer.snapshot(from: view2)
    #expect(snapshot1 == snapshot2)
}

private func runtimeModuleSource(for source: String, viewName: String) -> String {
    if source.contains("struct \(viewName)") {
        return source
    }

    return """
struct \(viewName): View {
    var body: some View {
\(indent(source))
    }
}
"""
}

private func indent(_ source: String) -> String {
    source
        .split(separator: "\n", omittingEmptySubsequences: false)
        .map { line in
            if line.isEmpty {
                return "            "
            } else {
                return "            \(line)"
            }
        }
        .joined(separator: "\n")
}
