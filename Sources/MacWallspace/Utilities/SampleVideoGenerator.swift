import Foundation
import AVFoundation
import CoreGraphics
import Cocoa

public final class SampleVideoGenerator {
    public static func ensureDefaultOfflineWallpapersExist() {
        let store = WallpaperStore.shared
        
        // 1. Anime Twilight & Drifting Sakura (60 FPS)
        let animeName = "builtin_anime_sakura_60fps.mp4"
        let animeURL = WallpaperStore.wallpapersDirectory.appendingPathComponent(animeName)
        let animeId = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        
        if !FileManager.default.fileExists(atPath: animeURL.path) {
            generateAnimeSakuraLoop(to: animeURL) { success in
                if success {
                    registerSample(id: animeId, title: "Anime Twilight & Drifting Sakura", category: "Anime & Cozy", fileName: animeName, fileURL: animeURL, author: "MaC Wallspace Studio")
                }
            }
        } else {
            registerSample(id: animeId, title: "Anime Twilight & Drifting Sakura", category: "Anime & Cozy", fileName: animeName, fileURL: animeURL, author: "MaC Wallspace Studio")
        }
        
        // 2. Shifting Aurora Loop (60 FPS Smooth)
        let auroraName = "builtin_aurora_wave_60fps.mp4"
        let auroraURL = WallpaperStore.wallpapersDirectory.appendingPathComponent(auroraName)
        let auroraId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        
        if !FileManager.default.fileExists(atPath: auroraURL.path) {
            generateAuroraLoop(to: auroraURL) { success in
                if success {
                    registerSample(id: auroraId, title: "Aurora Shifting Waves (60 FPS)", category: "Minimalist", fileName: auroraName, fileURL: auroraURL, author: "MaC Wallspace Studio")
                }
            }
        } else {
            registerSample(id: auroraId, title: "Aurora Shifting Waves (60 FPS)", category: "Minimalist", fileName: auroraName, fileURL: auroraURL, author: "MaC Wallspace Studio")
        }
        
        // 3. Cosmic Starfield Warp (60 FPS Smooth)
        let spaceName = "builtin_cosmic_warp_60fps.mp4"
        let spaceURL = WallpaperStore.wallpapersDirectory.appendingPathComponent(spaceName)
        let spaceId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        
        if !FileManager.default.fileExists(atPath: spaceURL.path) {
            generateSpaceWarpLoop(to: spaceURL) { success in
                if success {
                    registerSample(id: spaceId, title: "Cosmic Deep Space Warp (60 FPS)", category: "Sci-Fi", fileName: spaceName, fileURL: spaceURL, author: "MaC Wallspace Studio")
                }
            }
        } else {
            registerSample(id: spaceId, title: "Cosmic Deep Space Warp (60 FPS)", category: "Sci-Fi", fileName: spaceName, fileURL: spaceURL, author: "MaC Wallspace Studio")
        }
    }
    
    private static func registerSample(id: UUID, title: String, category: String, fileName: String, fileURL: URL, author: String) {
        let store = WallpaperStore.shared
        
        let thumbURL = WallpaperStore.thumbnailsDirectory.appendingPathComponent("\(id.uuidString).jpg")
        if !FileManager.default.fileExists(atPath: thumbURL.path) {
            WallpaperStore.generateThumbnail(for: fileURL, destination: thumbURL)
        }
        
        if !store.wallpapers.contains(where: { $0.id == id }) {
            let item = WallpaperItem(
                id: id,
                title: title,
                category: category,
                resolution: "1080p (60 FPS)",
                fileSizeMB: 2.4,
                thumbnailUrl: thumbURL.path,
                videoUrl: fileURL.absoluteString,
                localFileName: fileName,
                isCustom: false,
                dateAdded: Date(),
                author: author
            )
            store.wallpapers.insert(item, at: 0)
            store.saveCatalog()
            
            // Prefer setting the anime live wallpaper as default
            if id.uuidString.hasSuffix("0003") || store.activeWallpaper == nil {
                store.setActiveWallpaper(item)
            }
        }
    }
    
    // MARK: - Loop 1: Anime Twilight & Drifting Sakura (60 FPS)
    public static func generateAnimeSakuraLoop(to outputURL: URL, completion: @escaping (Bool) -> Void) {
        let width = 1920
        let height = 1080
        let fps: Int32 = 60
        let durationSeconds = 5
        let totalFrames = Int(fps) * durationSeconds
        
        // Find bundled anime background image
        var baseCGImage: CGImage?
        let possiblePaths = [
            Bundle.main.resourcePath.map { "\($0)/icon_assets/anime_wallpaper.jpg" },
            Bundle.main.resourcePath.map { "\($0)/anime_wallpaper.jpg" },
            "/Users/sammy/Desktop/Code/MaC-Wallspace/Resources/icon_assets/anime_wallpaper.jpg"
        ].compactMap { $0 }
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path),
               let img = NSImage(contentsOfFile: path),
               let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                baseCGImage = cg
                break
            }
        }
        
        // Sakura petal particles
        struct Petal { var x: Double; var y: Double; var speedX: Double; var speedY: Double; var size: Double; var phase: Double }
        var petals: [Petal] = []
        for i in 0..<80 {
            let px = Double((i * 137) % width)
            let py = Double((i * 193) % height)
            let speedX = 1.2 + Double(i % 4) * 0.5
            let speedY = 1.6 + Double(i % 5) * 0.6
            let size = 6.0 + Double(i % 4) * 3.0
            petals.append(Petal(x: px, y: py, speedX: speedX, speedY: speedY, size: size, phase: Double(i)))
        }
        
        renderFrames(to: outputURL, width: width, height: height, fps: fps, totalFrames: totalFrames, frameRenderer: { frameIndex, context, rgbSpace in
            let progress = Double(frameIndex) / Double(totalFrames)
            
            // Draw background image or twilight gradient
            if let bg = baseCGImage {
                context.draw(bg, in: CGRect(x: 0, y: 0, width: width, height: height))
            } else {
                let startColor = CGColor(red: 0.12, green: 0.14, blue: 0.32, alpha: 1.0)
                let endColor = CGColor(red: 0.38, green: 0.22, blue: 0.44, alpha: 1.0)
                if let gradient = CGGradient(colorsSpace: rgbSpace, colors: [startColor, endColor] as CFArray, locations: [0.0, 1.0]) {
                    context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: height), options: [])
                }
            }
            
            // Draw 60fps drifting Sakura petals
            for petal in petals {
                let driftX = (Double(frameIndex) * petal.speedX).truncatingRemainder(dividingBy: Double(width))
                let driftY = (Double(frameIndex) * petal.speedY).truncatingRemainder(dividingBy: Double(height))
                
                let curX = (petal.x + driftX).truncatingRemainder(dividingBy: Double(width))
                let curY = (petal.y + driftY).truncatingRemainder(dividingBy: Double(height))
                
                let sway = sin(progress * 2.0 * Double.pi + petal.phase) * 12.0
                let rect = CGRect(x: curX + sway, y: curY, width: petal.size, height: petal.size * 1.5)
                
                context.saveGState()
                context.setFillColor(CGColor(red: 1.0, green: 0.78, blue: 0.86, alpha: 0.88))
                context.fillEllipse(in: rect)
                context.restoreGState()
            }
        }, completion: completion)
    }
    
    // MARK: - Loop 2: Aurora Shifting Waves (60 FPS)
    public static func generateAuroraLoop(to outputURL: URL, completion: @escaping (Bool) -> Void) {
        let width = 1920
        let height = 1080
        let fps: Int32 = 60
        let durationSeconds = 5
        let totalFrames = Int(fps) * durationSeconds
        
        renderFrames(to: outputURL, width: width, height: height, fps: fps, totalFrames: totalFrames, frameRenderer: { frameIndex, context, rgbSpace in
            let progress = Double(frameIndex) / Double(totalFrames)
            let phase = progress * 2.0 * Double.pi
            
            let r1 = CGFloat(0.06 + 0.10 * sin(phase))
            let g1 = CGFloat(0.14 + 0.16 * cos(phase))
            let b1 = CGFloat(0.35 + 0.20 * sin(phase + Double.pi / 2))
            
            let r2 = CGFloat(0.22 + 0.16 * cos(phase))
            let g2 = CGFloat(0.08 + 0.08 * sin(phase))
            let b2 = CGFloat(0.40 + 0.16 * cos(phase + Double.pi / 3))
            
            let startColor = CGColor(red: r1, green: g1, blue: b1, alpha: 1.0)
            let endColor = CGColor(red: r2, green: g2, blue: b2, alpha: 1.0)
            
            if let gradient = CGGradient(colorsSpace: rgbSpace, colors: [startColor, endColor] as CFArray, locations: [0.0, 1.0]) {
                context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: CGFloat(width), y: CGFloat(height)), options: [])
            }
        }, completion: completion)
    }
    
    // MARK: - Loop 3: Cosmic Space Warp (60 FPS)
    public static func generateSpaceWarpLoop(to outputURL: URL, completion: @escaping (Bool) -> Void) {
        let width = 1920
        let height = 1080
        let fps: Int32 = 60
        let durationSeconds = 5
        let totalFrames = Int(fps) * durationSeconds
        
        struct Star { var x: Double; var y: Double; var speed: Double; var size: Double }
        var stars: [Star] = []
        for i in 0..<180 {
            let x = Double((i * 127) % width)
            let y = Double((i * 181) % height)
            let speed = 0.8 + Double(i % 5) * 0.6
            let size = 1.4 + Double(i % 3) * 0.8
            stars.append(Star(x: x, y: y, speed: speed, size: size))
        }
        
        renderFrames(to: outputURL, width: width, height: height, fps: fps, totalFrames: totalFrames, frameRenderer: { frameIndex, context, rgbSpace in
            let bgStart = CGColor(red: 0.02, green: 0.03, blue: 0.07, alpha: 1.0)
            let bgEnd = CGColor(red: 0.06, green: 0.04, blue: 0.12, alpha: 1.0)
            if let gradient = CGGradient(colorsSpace: rgbSpace, colors: [bgStart, bgEnd] as CFArray, locations: [0.0, 1.0]) {
                context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: CGFloat(height)), options: [])
            }
            
            for star in stars {
                let offset = (Double(frameIndex) * star.speed * 3.5).truncatingRemainder(dividingBy: Double(height))
                let currentY = (star.y + offset).truncatingRemainder(dividingBy: Double(height))
                let rect = CGRect(x: star.x, y: currentY, width: star.size, height: star.size)
                context.setFillColor(CGColor(red: 0.9, green: 0.94, blue: 1.0, alpha: 0.9))
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
            AVVideoAverageBitRateKey: 4_500_000,
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
