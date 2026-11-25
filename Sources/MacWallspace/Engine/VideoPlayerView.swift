import Cocoa
import AVFoundation
import ImageIO
import QuartzCore

public final class VideoPlayerView: NSView {
    private let contentLayer = CALayer()
    private var playerLayer: AVPlayerLayer?
    private var player: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?
    private var endObserver: NSObjectProtocol?
    
    private var currentURL: URL?
    private var isPlaying: Bool = false
    private var isStaticImage: Bool = false
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayer()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }
    
    private func setupLayer() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        layer?.drawsAsynchronously = true
        
        contentLayer.frame = bounds
        contentLayer.contentsGravity = (AppSettings.shared.scaleMode == "aspectFit") ? .resizeAspect : .resizeAspectFill
        contentLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        contentLayer.actions = [
            "bounds": NSNull(),
            "position": NSNull(),
            "sublayers": NSNull()
        ]
        
        layer?.addSublayer(contentLayer)
    }
    
    public override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        contentLayer.frame = bounds
        playerLayer?.frame = bounds
        CATransaction.commit()
    }
    
    public func loadMedia(url: URL) {
        // If already playing this URL and content is valid, just resume
        if currentURL == url && (contentLayer.contents != nil || player != nil) {
            resume()
            return
        }
        
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), !isDir.boolValue else {
            print("⚠️ VideoPlayerView: Invalid media path or is directory: \(url.path)")
            return
        }
        
        cleanup()
        self.currentURL = url
        
        let ext = url.pathExtension.lowercased()
        let imageExtensions = ["jpg", "jpeg", "png", "heic", "webp", "bmp", "tiff"]
        
        if ext == "gif" {
            // Animated GIF Mode (CoreAnimation Hardware Looping, 0% CPU)
            loadGIF(url: url)
        } else if imageExtensions.contains(ext) {
            // Static Photo Wallpaper Mode (0.0% CPU)
            loadPhoto(url: url)
        } else {
            // Live Video Wallpaper Mode (Hardware-Accelerated 60 FPS)
            loadVideo(url: url)
        }
    }
    
    private func loadGIF(url: URL) {
        self.isStaticImage = true
        contentLayer.removeAnimation(forKey: "gifAnimation")
        
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            loadPhoto(url: url)
            return
        }
        
        let count = CGImageSourceGetCount(source)
        if count <= 1 {
            loadPhoto(url: url)
            return
        }
        
        var images: [CGImage] = []
        var totalDuration: Double = 0.0
        
        for i in 0..<count {
            if let cg = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(cg)
                
                var frameDuration = 0.1
                if let props = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
                   let gifProps = props[kCGImagePropertyGIFDictionary as String] as? [String: Any] {
                    if let delay = gifProps[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double, delay > 0.01 {
                        frameDuration = delay
                    } else if let delay = gifProps[kCGImagePropertyGIFDelayTime as String] as? Double, delay > 0.01 {
                        frameDuration = delay
                    }
                }
                totalDuration += frameDuration
            }
        }
        
        guard !images.isEmpty, let firstFrame = images.first else {
            loadPhoto(url: url)
            return
        }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        contentLayer.contents = firstFrame
        contentLayer.contentsGravity = (AppSettings.shared.scaleMode == "aspectFit") ? .resizeAspect : .resizeAspectFill
        
        let animation = CAKeyframeAnimation(keyPath: "contents")
        animation.values = images
        animation.duration = max(0.4, totalDuration)
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false
        contentLayer.add(animation, forKey: "gifAnimation")
        CATransaction.commit()
    }
    
    private func loadPhoto(url: URL) {
        self.isStaticImage = true
        contentLayer.removeAnimation(forKey: "gifAnimation")
        
        var cgImage: CGImage?
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: true,
            kCGImageSourceShouldCacheImmediately: true
        ]
        if let source = CGImageSourceCreateWithURL(url as CFURL, options as CFDictionary) {
            cgImage = CGImageSourceCreateImageAtIndex(source, 0, options as CFDictionary)
        }
        if cgImage == nil, let image = NSImage(contentsOf: url) {
            var rect = NSRect(origin: .zero, size: image.size)
            cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil)
        }
        
        guard let finalCG = cgImage else {
            print("⚠️ VideoPlayerView: Failed to decode image at \(url.path)")
            return
        }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        contentLayer.contents = finalCG
        contentLayer.contentsGravity = (AppSettings.shared.scaleMode == "aspectFit") ? .resizeAspect : .resizeAspectFill
        CATransaction.commit()
    }
    
    private func loadVideo(url: URL) {
        self.isStaticImage = false
        contentLayer.removeAnimation(forKey: "gifAnimation")
        
        let asset = AVURLAsset(url: url, options: [
            AVURLAssetPreferPreciseDurationAndTimingKey: false
        ])
        
        // Immediate poster frame: ensures the user never sees a black flash while the video buffers
        let gen = AVAssetImageGenerator(asset: asset)
        gen.appliesPreferredTrackTransform = true
        gen.maximumSize = CGSize(width: 1920, height: 1080)
        let time = CMTime(seconds: 0.1, preferredTimescale: 600)
        if let poster = try? gen.copyCGImage(at: time, actualTime: nil) {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            contentLayer.contents = poster
            contentLayer.contentsGravity = (AppSettings.shared.scaleMode == "aspectFit") ? .resizeAspect : .resizeAspectFill
            CATransaction.commit()
        }
        
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.preferredForwardBufferDuration = 2.0
        
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        queuePlayer.actionAtItemEnd = .none
        queuePlayer.automaticallyWaitsToMinimizeStalling = false
        queuePlayer.preventsDisplaySleepDuringVideoPlayback = false
        if AppSettings.shared.isMuted {
            queuePlayer.volume = 0.0
            queuePlayer.isMuted = true
        }
        
        self.playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        
        let vLayer = AVPlayerLayer(player: queuePlayer)
        vLayer.frame = bounds
        vLayer.videoGravity = (AppSettings.shared.scaleMode == "aspectFit") ? .resizeAspect : .resizeAspectFill
        vLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        vLayer.drawsAsynchronously = true
        vLayer.actions = [
            "contents": NSNull(),
            "bounds": NSNull(),
            "position": NSNull()
        ]
        
        self.contentLayer.addSublayer(vLayer)
        self.playerLayer = vLayer
        self.player = queuePlayer
        
        applyAudioSettings()
        
        if !AppSettings.shared.isPausedByUser {
            queuePlayer.play()
            isPlaying = true
        }
    }
    
    public func pause() {
        if !isStaticImage {
            player?.pause()
            isPlaying = false
        }
    }
    
    public func resume() {
        guard !AppSettings.shared.isPausedByUser else { return }
        if !isStaticImage {
            player?.play()
            isPlaying = true
        }
    }
    
    public func applyAudioSettings() {
        guard !isStaticImage else { return }
        if AppSettings.shared.isMuted {
            player?.volume = 0.0
            player?.isMuted = true
        } else {
            player?.volume = AppSettings.shared.volume
            player?.isMuted = false
        }
    }
    
    public func cleanup() {
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
            endObserver = nil
        }
        playerLooper?.disableLooping()
        playerLooper = nil
        player?.pause()
        player?.removeAllItems()
        player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        contentLayer.removeAnimation(forKey: "gifAnimation")
        currentURL = nil
        isPlaying = false
        isStaticImage = false
    }
    
    deinit {
        cleanup()
    }
}
