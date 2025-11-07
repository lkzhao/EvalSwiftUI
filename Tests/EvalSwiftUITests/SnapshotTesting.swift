import CoreGraphics
import Foundation
import SwiftUI
import Testing
@testable import EvalSwiftUI

enum SnapshotError: Error {
    case failedToRenderImage
    case missingPixelData
}

struct SnapshotConfiguration {
    let proposedWidth: CGFloat?
    let proposedHeight: CGFloat?
    let scale: CGFloat

    static var automatic: SnapshotConfiguration {
        SnapshotConfiguration(proposedWidth: nil, proposedHeight: nil, scale: 1)
    }
}

struct ViewSnapshot: Equatable {
    let width: Int
    let height: Int
    private let pixelData: Data

    init(cgImage: CGImage) throws {
        width = cgImage.width
        height = cgImage.height
        pixelData = try ViewSnapshot.pixelData(from: cgImage)
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
            throw SnapshotError.missingPixelData
        }

        return data
    }
}

enum ViewSnapshotRenderer {
    @MainActor
    static func snapshot<V: View>(
        from view: V,
        configuration: SnapshotConfiguration = .automatic
    ) throws -> ViewSnapshot {
        let renderer = ImageRenderer(content: view)
        renderer.scale = configuration.scale
        renderer.isOpaque = false
        if configuration.proposedWidth != nil || configuration.proposedHeight != nil {
            renderer.proposedSize = ProposedViewSize(
                width: configuration.proposedWidth,
                height: configuration.proposedHeight
            )
        }
        guard let image = renderer.cgImage else {
            throw SnapshotError.failedToRenderImage
        }
        return try ViewSnapshot(cgImage: image)
    }
}

@MainActor
func assertSnapshotsMatch<V: View>(
    source: String,
    configuration: SnapshotConfiguration = .automatic,
    @ViewBuilder expected expectedView: () -> V
) throws {
    let evaluated = try evalSwiftUI(source)
    let evaluatedSnapshot = try ViewSnapshotRenderer.snapshot(from: evaluated, configuration: configuration)
    let expectedSnapshot = try ViewSnapshotRenderer.snapshot(from: expectedView(), configuration: configuration)
    #expect(evaluatedSnapshot == expectedSnapshot)
}
