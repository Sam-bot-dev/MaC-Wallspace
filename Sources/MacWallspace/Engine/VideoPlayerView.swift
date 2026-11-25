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
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
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
        
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        queuePlayer.actionAtItemEnd = .none
        
        // Looper
        if #available(macOS 10.12, *) {
            self.playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        } else {
            // Fallback end notification loop
            self.endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: playerItem,
                queue: .main
            ) { [weak queuePlayer] _ in
                queuePlayer?.seek(to: .zero)
                queuePlayer?.play()
            }
        }
        
        let layer = AVPlayerLayer(player: queuePlayer)
        layer.frame = bounds
        layer.videoGravity = (AppSettings.shared.scaleMode == "aspectFit") ? .resizeAspect : .resizeAspectFill
        layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        
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
