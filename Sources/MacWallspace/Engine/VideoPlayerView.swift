import Cocoa
import AVFoundation

public final class VideoPlayerView: NSView {
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
        layer?.actions = [
            "contents": NSNull(),
            "bounds": NSNull(),
            "position": NSNull(),
            "sublayers": NSNull()
        ]
    }
    
    public override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer?.frame = bounds
        CATransaction.commit()
    }
    
    public func loadMedia(url: URL) {
        guard currentURL != url else {
            resume()
            return
        }
        
        cleanup()
        self.currentURL = url
        
        let ext = url.pathExtension.lowercased()
        let imageExtensions = ["jpg", "jpeg", "png", "heic", "webp", "bmp", "tiff"]
        
        if imageExtensions.contains(ext) {
            // Static Photo Wallpaper Mode (0.0% CPU)
            loadPhoto(url: url)
        } else {
            // Live Video Wallpaper Mode (Hardware-Accelerated 60 FPS)
            loadVideo(url: url)
        }
    }
    
    private func loadPhoto(url: URL) {
        self.isStaticImage = true
        guard let image = NSImage(contentsOf: url),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return
        }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer?.contents = cgImage
        layer?.contentsGravity = (AppSettings.shared.scaleMode == "aspectFit") ? .resizeAspect : .resizeAspectFill
        CATransaction.commit()
    }
    
    private func loadVideo(url: URL) {
        self.isStaticImage = false
        layer?.contents = nil
        
        let asset = AVURLAsset(url: url, options: [
            AVURLAssetPreferPreciseDurationAndTimingKey: true
        ])
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.preferredForwardBufferDuration = 3.0
        
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        queuePlayer.actionAtItemEnd = .none
        queuePlayer.automaticallyWaitsToMinimizeStalling = false
        queuePlayer.preventsDisplaySleepDuringVideoPlayback = false
        
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
        
        self.layer?.addSublayer(vLayer)
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
        playerLooper = nil
        player?.pause()
        player?.removeAllItems()
        player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        layer?.contents = nil
        currentURL = nil
        isPlaying = false
        isStaticImage = false
    }
    
    deinit {
        cleanup()
    }
}
