import CoreGraphics
import Foundation
import ImageIO
import SwiftUI
import UniformTypeIdentifiers
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

    @MainActor
    static func writeSnapshot<V: View>(from view: V, to url: URL) {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        renderer.isOpaque = false
        guard let image = renderer.cgImage,
              let destination = CGImageDestinationCreateWithURL(
                  url as CFURL,
                  UTType.png.identifier as CFString,
                  1,
                  nil
              ) else {
            return
        }
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
    }
}

@MainActor
func assertSnapshotsMatch<V: View>(
    source: String,
    valueBuilders: [any RuntimeValueBuilder] = [],
    modifierBuilders: [any RuntimeModifierBuilder] = [],
    @ViewBuilder expected expectedView: () -> V
) throws {
    let parser = SwiftIRParser()
    let moduleIR = parser.parseModule(source: source)
    let module = try RuntimeModule(
        ir: moduleIR,
        valueBuilders: valueBuilders,
        modifierBuilders: modifierBuilders
    )
    let evaluatedView = try module.makeTopLevelSwiftUIViews()
    try assertViewMatch(evaluatedView, expectedView())
}

@MainActor
func assertViewMatch(_ view1: some View, _ view2: some View) throws {
    let isDebugLoggingEnabled = ProcessInfo.processInfo.environment["RUNTIME_DEBUG"] != nil
    let snapshot1: RuntimeViewSnapshot
    do {
        snapshot1 = try RuntimeViewSnapshotRenderer.snapshot(from: view1)
    } catch {
        if isDebugLoggingEnabled {
            print("Failed to snapshot evaluated view: \(error)")
        }
        throw error
    }
    let snapshot2: RuntimeViewSnapshot
    do {
        snapshot2 = try RuntimeViewSnapshotRenderer.snapshot(from: view2)
    } catch {
        if isDebugLoggingEnabled {
            print("Failed to snapshot reference view: \(error)")
        }
        throw error
    }
    if snapshot1 != snapshot2, isDebugLoggingEnabled {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let evaluatedURL = directory.appendingPathComponent("runtime-actual.png")
        let expectedURL = directory.appendingPathComponent("runtime-expected.png")
        RuntimeViewSnapshotRenderer.writeSnapshot(from: view1, to: evaluatedURL)
        RuntimeViewSnapshotRenderer.writeSnapshot(from: view2, to: expectedURL)
        print("Snapshot mismatch saved to \(evaluatedURL.path) and \(expectedURL.path)")
    }
    #expect(snapshot1 == snapshot2)
}
