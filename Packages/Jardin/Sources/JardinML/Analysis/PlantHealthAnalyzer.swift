import CoreGraphics
import CoreVideo
import Foundation
import JardinCore
import Vision

/// Analyse de santé d'une photo : isole la plante du fond avec
/// `VNGenerateForegroundInstanceMaskRequest` (iOS 17/macOS 14) puis applique
/// l'analyse colorimétrique `HealthMath`. Sans masque exploitable, l'image
/// entière est analysée.
public enum PlantHealthAnalyzer {
    public struct Result: Sendable {
        public let report: HealthMath.Report
        /// Part de l'image occupée par le sujet (pour le suivi de croissance) ;
        /// 0 si aucun masque n'a pu être calculé.
        public let foregroundAreaRatio: Double
    }

    public static func analyze(cgImage: CGImage) -> Result {
        guard let buffer = ImageUtils.rgbaBuffer(from: cgImage) else {
            return Result(report: HealthMath.analyze(pixels: [], width: 0, height: 0),
                          foregroundAreaRatio: 0)
        }

        let maskInfo = foregroundMask(cgImage: cgImage,
                                      targetWidth: buffer.width,
                                      targetHeight: buffer.height)
        let report = HealthMath.analyze(pixels: buffer.pixels,
                                        width: buffer.width,
                                        height: buffer.height,
                                        mask: maskInfo?.mask)
        return Result(report: report, foregroundAreaRatio: maskInfo?.areaRatio ?? 0)
    }

    /// Masque de premier plan rééchantillonné aux dimensions du tampon d'analyse.
    static func foregroundMask(cgImage: CGImage,
                               targetWidth: Int,
                               targetHeight: Int) -> (mask: [Bool], areaRatio: Double)? {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        guard (try? handler.perform([request])) != nil,
              let observation = request.results?.first,
              !observation.allInstances.isEmpty,
              let maskBuffer = try? observation.generateScaledMaskForImage(
                  forInstances: observation.allInstances, from: handler
              ) else { return nil }

        return resample(maskBuffer, targetWidth: targetWidth, targetHeight: targetHeight)
    }

    static func resample(_ pixelBuffer: CVPixelBuffer,
                         targetWidth: Int,
                         targetHeight: Int) -> (mask: [Bool], areaRatio: Double)? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }
        let sourceWidth = CVPixelBufferGetWidth(pixelBuffer)
        let sourceHeight = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let format = CVPixelBufferGetPixelFormatType(pixelBuffer)
        guard sourceWidth > 0, sourceHeight > 0, targetWidth > 0, targetHeight > 0 else { return nil }

        func maskValue(x: Int, y: Int) -> Bool {
            let row = base.advanced(by: y * bytesPerRow)
            switch format {
            case kCVPixelFormatType_OneComponent32Float:
                return row.assumingMemoryBound(to: Float32.self)[x] > 0.5
            case kCVPixelFormatType_OneComponent8:
                return row.assumingMemoryBound(to: UInt8.self)[x] > 127
            default:
                return false
            }
        }
        guard format == kCVPixelFormatType_OneComponent32Float
                || format == kCVPixelFormatType_OneComponent8 else { return nil }

        var mask = [Bool](repeating: false, count: targetWidth * targetHeight)
        var foreground = 0
        for ty in 0..<targetHeight {
            let sy = min(sourceHeight - 1, ty * sourceHeight / targetHeight)
            for tx in 0..<targetWidth {
                let sx = min(sourceWidth - 1, tx * sourceWidth / targetWidth)
                let value = maskValue(x: sx, y: sy)
                mask[ty * targetWidth + tx] = value
                if value { foreground += 1 }
            }
        }
        let areaRatio = Double(foreground) / Double(targetWidth * targetHeight)
        // Un masque quasi vide ou couvrant tout n'apporte rien : on le rejette.
        guard areaRatio > 0.01, areaRatio < 0.98 else { return nil }
        return (mask, areaRatio)
    }
}
