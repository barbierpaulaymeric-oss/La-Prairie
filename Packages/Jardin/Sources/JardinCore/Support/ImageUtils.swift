import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage
#endif

public enum ImageUtils {
    public static let storedMaxDimension: CGFloat = 1600
    public static let thumbnailMaxDimension: CGFloat = 320

    public static func cgImage(from image: PlatformImage) -> CGImage? {
        #if canImport(UIKit)
        return image.cgImage
        #else
        var rect = CGRect(origin: .zero, size: image.size)
        return image.cgImage(forProposedRect: &rect, context: nil, hints: nil)
        #endif
    }

    public static func cgImage(fromJPEGData data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    public static func platformImage(from data: Data) -> PlatformImage? {
        PlatformImage(data: data)
    }

    public static func jpegData(from cgImage: CGImage, quality: CGFloat = 0.72) -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data as CFMutableData, UTType.jpeg.identifier as CFString, 1, nil
        ) else { return nil }
        CGImageDestinationAddImage(destination, cgImage, [
            kCGImageDestinationLossyCompressionQuality: quality,
        ] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }

    public static func resized(_ cgImage: CGImage, maxDimension: CGFloat) -> CGImage? {
        let width = CGFloat(cgImage.width), height = CGFloat(cgImage.height)
        let scale = min(1, maxDimension / max(width, height))
        guard scale < 1 else { return cgImage }
        let newWidth = Int(width * scale), newHeight = Int(height * scale)
        guard let context = CGContext(
            data: nil, width: newWidth, height: newHeight,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        return context.makeImage()
    }

    /// Prépare (photo stockée, miniature) à partir d'une image source,
    /// redimensionnées et compressées pour limiter la taille du store et de CloudKit.
    public static func makeStoredPhoto(from image: PlatformImage) -> (photo: Data, thumbnail: Data)? {
        guard let cg = cgImage(from: image) else { return nil }
        return makeStoredPhoto(fromCGImage: cg)
    }

    public static func makeStoredPhoto(fromCGImage cg: CGImage) -> (photo: Data, thumbnail: Data)? {
        guard let mainImage = resized(cg, maxDimension: storedMaxDimension),
              let thumbImage = resized(cg, maxDimension: thumbnailMaxDimension),
              let mainData = jpegData(from: mainImage),
              let thumbData = jpegData(from: thumbImage, quality: 0.6) else { return nil }
        return (mainData, thumbData)
    }

    /// Extrait un tampon RGBA 8 bits (utilisé par l'analyse de santé des feuilles).
    public static func rgbaBuffer(from cgImage: CGImage, maxDimension: CGFloat = 512) -> (pixels: [UInt8], width: Int, height: Int)? {
        guard let scaled = resized(cgImage, maxDimension: maxDimension) else { return nil }
        let width = scaled.width, height = scaled.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(
            data: &pixels, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.draw(scaled, in: CGRect(x: 0, y: 0, width: width, height: height))
        return (pixels, width, height)
    }
}
