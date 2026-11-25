import Cocoa
import AVFoundation

public final class VideoPlayerView: NSView {
    private var playerLayer: AVPlayerLayer?
    private var player: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?
    private var endObserver: NSObjectProtocol?
    
    private var currentURL: URL?
    private var isPlaying: Bool = false
    
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
        // Enable hardware-accelerated asynchronous layer compositing for buttery 60fps
        layer?.drawsAsynchronously = true
        // Disable CoreAnimation action lookups for zero frame-drop rendering
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
    
    public func loadVideo(url: URL) {
        guard currentURL != url else {
            resume()
            return
        }
        
        cleanup()
        self.currentURL = url
        
        let asset = AVURLAsset(url: url, options: [
            AVURLAssetPreferPreciseDurationAndTimingKey: true
        ])
        let playerItem = AVPlayerItem(asset: asset)
        
        // Optimize buffering and decode pipeline for 60fps smooth playback
        playerItem.preferredForwardBufferDuration = 3.0
        
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        queuePlayer.actionAtItemEnd = .none
        queuePlayer.automaticallyWaitsToMinimizeStalling = false
        queuePlayer.preventsDisplaySleepDuringVideoPlayback = false
        
        // AVPlayerLooper provides seamless, zero-gap hardware looping
        self.playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        
        let layer = AVPlayerLayer(player: queuePlayer)
        layer.frame = bounds
        layer.videoGravity = (AppSettings.shared.scaleMode == "aspectFit") ? .resizeAspect : .resizeAspectFill
        layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        
        // Enable asynchronous GPU drawing on the player layer
        layer.drawsAsynchronously = true
        layer.actions = [
            "contents": NSNull(),
            "bounds": NSNull(),
            "position": NSNull()
        ]
        
        self.layer?.addSublayer(layer)
        self.playerLayer = layer
        self.player = queuePlayer
        
        applyAudioSettings()
        
        if !AppSettings.shared.isPausedByUser {
            queuePlayer.play()
            isPlaying = true
        }
    }
    
    public func pause() {
        player?.pause()
        isPlaying = false
    }
    
    public func resume() {
        guard !AppSettings.shared.isPausedByUser else { return }
        player?.play()
        isPlaying = true
    }
    
    public func applyAudioSettings() {
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
        currentURL = nil
        isPlaying = false
    }
    
    deinit {
        cleanup()
    }
}
