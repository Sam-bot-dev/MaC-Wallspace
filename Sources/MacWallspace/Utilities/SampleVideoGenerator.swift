import Foundation
import AVFoundation
import CoreGraphics
import Cocoa

public final class SampleVideoGenerator {
    public static func ensureDefaultOfflineWallpaperExists() {
        let defaultFileName = "default_offline_loop.mp4"
        let fileURL = WallpaperStore.wallpapersDirectory.appendingPathComponent(defaultFileName)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            registerDefaultItemIfNeeded(fileURL: fileURL, fileName: defaultFileName)
            return
        }
        
        generateLoop(to: fileURL) { success in
            if success {
                registerDefaultItemIfNeeded(fileURL: fileURL, fileName: defaultFileName)
            }
        }
    }
    
    private static func registerDefaultItemIfNeeded(fileURL: URL, fileName: String) {
        let store = WallpaperStore.shared
        let defaultId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        
        if !store.wallpapers.contains(where: { $0.id == defaultId }) {
            let item = WallpaperItem(
                id: defaultId,
                title: "Aurora Gradient Loop (Offline)",
                category: "Minimalist",
                resolution: "1080p (Native)",
                fileSizeMB: 1.5,
                videoUrl: fileURL.absoluteString,
                localFileName: fileName,
                isCustom: false,
                dateAdded: Date(),
                author: "Mac Wallspace Engine"
            )
            store.wallpapers.insert(item, at: 0)
            store.saveCatalog()
            
            if store.activeWallpaper == nil {
                store.setActiveWallpaper(item)
            }
        }
    }
    
    public static func generateLoop(to outputURL: URL, completion: @escaping (Bool) -> Void) {
        let width = 1280
        let height = 720
        let fps: Int32 = 30
        let durationSeconds = 4 // 4-second seamless loop
        let totalFrames = Int(fps) * durationSeconds
        
        try? FileManager.default.removeItem(at: outputURL)
        
        guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
            completion(false)
            return
        }
        
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 1_500_000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]
        
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height
            ]
        )
        
        writerInput.expectsMediaDataInRealTime = false
        writer.add(writerInput)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        DispatchQueue.global(qos: .utility).async {
            var frameCount = 0
            while frameCount < totalFrames {
                if writerInput.isReadyForMoreMediaData {
                    let progress = Double(frameCount) / Double(totalFrames)
                    let phase = progress * 2.0 * Double.pi
                    
                    var pixelBuffer: CVPixelBuffer?
                    CVPixelBufferCreate(
                        kCFAllocatorDefault,
                        width,
                        height,
                        kCVPixelFormatType_32ARGB,
                        nil,
                        &pixelBuffer
                    )
                    
                    if let buffer = pixelBuffer {
                        CVPixelBufferLockBaseAddress(buffer, [])
                        let pxData = CVPixelBufferGetBaseAddress(buffer)
                        
                        let context = CGContext(
                            data: pxData,
                            width: width,
                            height: height,
                            bitsPerComponent: 8,
                            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                            space: rgbColorSpace,
                            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
                        )
                        
                        // Draw smooth animated shifting aurora gradient
                        let r1 = CGFloat(0.1 + 0.15 * sin(phase))
                        let g1 = CGFloat(0.15 + 0.2 * cos(phase))
                        let b1 = CGFloat(0.35 + 0.25 * sin(phase + Double.pi / 2))
                        
                        let r2 = CGFloat(0.3 + 0.2 * cos(phase))
                        let g2 = CGFloat(0.1 + 0.1 * sin(phase))
                        let b2 = CGFloat(0.45 + 0.2 * cos(phase + Double.pi / 3))
                        
                        let startColor = CGColor(red: r1, green: g1, blue: b1, alpha: 1.0)
                        let endColor = CGColor(red: r2, green: g2, blue: b2, alpha: 1.0)
                        
                        if let gradient = CGGradient(colorsSpace: rgbColorSpace, colors: [startColor, endColor] as CFArray, locations: [0.0, 1.0]) {
                            context?.drawLinearGradient(
                                gradient,
                                start: CGPoint(x: 0, y: 0),
                                end: CGPoint(x: CGFloat(width), y: CGFloat(height)),
                                options: []
                            )
                        }
                        
                        CVPixelBufferUnlockBaseAddress(buffer, [])
                        
                        let presentationTime = CMTime(value: Int64(frameCount), timescale: fps)
                        adaptor.append(buffer, withPresentationTime: presentationTime)
                    }
                    frameCount += 1
                }
            }
            
            writerInput.markAsFinished()
            writer.finishWriting {
                completion(writer.status == .completed)
            }
        }
    }
}
