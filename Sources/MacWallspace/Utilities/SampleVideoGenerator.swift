import Foundation
import AVFoundation
import CoreGraphics
import Cocoa

public final class SampleVideoGenerator {
    public static func ensureDefaultOfflineWallpapersExist() {
        let store = WallpaperStore.shared
        
        // 1. Shifting Aurora Loop
        let auroraName = "builtin_aurora_wave.mp4"
        let auroraURL = WallpaperStore.wallpapersDirectory.appendingPathComponent(auroraName)
        let auroraId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        
        if !FileManager.default.fileExists(atPath: auroraURL.path) {
            generateAuroraLoop(to: auroraURL) { success in
                if success {
                    registerSample(id: auroraId, title: "Aurora Shifting Waves", category: "Minimalist", fileName: auroraName, fileURL: auroraURL, author: "MaC Wallspace Studio")
                }
            }
        } else {
            registerSample(id: auroraId, title: "Aurora Shifting Waves", category: "Minimalist", fileName: auroraName, fileURL: auroraURL, author: "MaC Wallspace Studio")
        }
        
        // 2. Cosmic Starfield Warp
        let spaceName = "builtin_cosmic_warp.mp4"
        let spaceURL = WallpaperStore.wallpapersDirectory.appendingPathComponent(spaceName)
        let spaceId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        
        if !FileManager.default.fileExists(atPath: spaceURL.path) {
            generateSpaceWarpLoop(to: spaceURL) { success in
                if success {
                    registerSample(id: spaceId, title: "Cosmic Deep Space Warp", category: "Sci-Fi", fileName: spaceName, fileURL: spaceURL, author: "MaC Wallspace Studio")
                }
            }
        } else {
            registerSample(id: spaceId, title: "Cosmic Deep Space Warp", category: "Sci-Fi", fileName: spaceName, fileURL: spaceURL, author: "MaC Wallspace Studio")
        }
    }
    
    private static func registerSample(id: UUID, title: String, category: String, fileName: String, fileURL: URL, author: String) {
        let store = WallpaperStore.shared
        
        // Generate thumbnail
        let thumbURL = WallpaperStore.thumbnailsDirectory.appendingPathComponent("\(id.uuidString).jpg")
        if !FileManager.default.fileExists(atPath: thumbURL.path) {
            WallpaperStore.generateThumbnail(for: fileURL, destination: thumbURL)
        }
        
        if !store.wallpapers.contains(where: { $0.id == id }) {
            let item = WallpaperItem(
                id: id,
                title: title,
                category: category,
                resolution: "1080p (Native)",
                fileSizeMB: 1.8,
                thumbnailUrl: thumbURL.path,
                videoUrl: fileURL.absoluteString,
                localFileName: fileName,
                isCustom: false,
                dateAdded: Date(),
                author: author
            )
            store.wallpapers.insert(item, at: 0)
            store.saveCatalog()
            
            if store.activeWallpaper == nil {
                store.setActiveWallpaper(item)
            }
        }
    }
    
    // MARK: - Loop 1: Aurora Shifting Wave
    public static func generateAuroraLoop(to outputURL: URL, completion: @escaping (Bool) -> Void) {
        let width = 1280
        let height = 720
        let fps: Int32 = 30
        let durationSeconds = 4
        let totalFrames = Int(fps) * durationSeconds
        
        renderFrames(to: outputURL, width: width, height: height, fps: fps, totalFrames: totalFrames, frameRenderer: { frameIndex, context, rgbSpace in
            let progress = Double(frameIndex) / Double(totalFrames)
            let phase = progress * 2.0 * Double.pi
            
            let r1 = CGFloat(0.08 + 0.12 * sin(phase))
            let g1 = CGFloat(0.12 + 0.18 * cos(phase))
            let b1 = CGFloat(0.32 + 0.22 * sin(phase + Double.pi / 2))
            
            let r2 = CGFloat(0.25 + 0.18 * cos(phase))
            let g2 = CGFloat(0.08 + 0.08 * sin(phase))
            let b2 = CGFloat(0.42 + 0.18 * cos(phase + Double.pi / 3))
            
            let startColor = CGColor(red: r1, green: g1, blue: b1, alpha: 1.0)
            let endColor = CGColor(red: r2, green: g2, blue: b2, alpha: 1.0)
            
            if let gradient = CGGradient(colorsSpace: rgbSpace, colors: [startColor, endColor] as CFArray, locations: [0.0, 1.0]) {
                context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: CGFloat(width), y: CGFloat(height)), options: [])
            }
        }, completion: completion)
    }
    
    // MARK: - Loop 2: Cosmic Space Warp
    public static func generateSpaceWarpLoop(to outputURL: URL, completion: @escaping (Bool) -> Void) {
        let width = 1280
        let height = 720
        let fps: Int32 = 30
        let durationSeconds = 4
        let totalFrames = Int(fps) * durationSeconds
        
        // Deterministic star points
        struct Star { var x: Double; var y: Double; var speed: Double; var size: Double }
        var stars: [Star] = []
        for i in 0..<120 {
            let x = Double((i * 97) % width)
            let y = Double((i * 131) % height)
            let speed = 1.0 + Double(i % 5) * 0.8
            let size = 1.2 + Double(i % 3) * 0.8
            stars.append(Star(x: x, y: y, speed: speed, size: size))
        }
        
        renderFrames(to: outputURL, width: width, height: height, fps: fps, totalFrames: totalFrames, frameRenderer: { frameIndex, context, rgbSpace in
            // Dark space gradient background
            let bgStart = CGColor(red: 0.03, green: 0.04, blue: 0.08, alpha: 1.0)
            let bgEnd = CGColor(red: 0.08, green: 0.05, blue: 0.15, alpha: 1.0)
            if let gradient = CGGradient(colorsSpace: rgbSpace, colors: [bgStart, bgEnd] as CFArray, locations: [0.0, 1.0]) {
                context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: CGFloat(height)), options: [])
            }
            
            // Draw moving stars
            for star in stars {
                let offset = (Double(frameIndex) * star.speed * 4.0).truncatingRemainder(dividingBy: Double(height))
                let currentY = (star.y + offset).truncatingRemainder(dividingBy: Double(height))
                let rect = CGRect(x: star.x, y: currentY, width: star.size, height: star.size)
                context.setFillColor(CGColor(red: 0.85, green: 0.9, blue: 1.0, alpha: 0.85))
                context.fillEllipse(in: rect)
            }
        }, completion: completion)
    }
    
    private static func renderFrames(
        to outputURL: URL,
        width: Int,
        height: Int,
        fps: Int32,
        totalFrames: Int,
        frameRenderer: @escaping (Int, CGContext, CGColorSpace) -> Void,
        completion: @escaping (Bool) -> Void
    ) {
        try? FileManager.default.removeItem(at: outputURL)
        
        guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
            completion(false)
            return
        }
        
        let compressionProps: [String: Any] = [
            AVVideoAverageBitRateKey: 1_800_000,
            AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
        ]
        
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: compressionProps
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
                        
                        if let ctx = context {
                            frameRenderer(frameCount, ctx, rgbColorSpace)
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
