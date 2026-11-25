import Cocoa
import Combine

public final class DesktopWindowManager {
    public static let shared = DesktopWindowManager()
    
    private var windows: [NSScreen: NSWindow] = [:]
    private var playerViews: [NSScreen: VideoPlayerView] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupObservers()
    }
    
    private func setupObservers() {
        // Handle screen resolution or display configuration changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        
        // Handle wallpaper change
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWallpaperChange(_:)),
            name: .macWallspaceDidChangeWallpaper,
            object: nil
        )
        
        // Observe settings changes
        AppSettings.shared.$scaleMode
            .sink { [weak self] _ in
                self?.reloadCurrentWallpaper()
            }
            .store(in: &cancellables)
            
        AppSettings.shared.$isMuted
            .sink { [weak self] _ in
                self?.playerViews.values.forEach { $0.applyAudioSettings() }
            }
            .store(in: &cancellables)
            
        AppSettings.shared.$volume
            .sink { [weak self] _ in
                self?.playerViews.values.forEach { $0.applyAudioSettings() }
            }
            .store(in: &cancellables)
    }
    
    public func start() {
        rebuildWindows()
        reloadCurrentWallpaper()
    }
    
    public func rebuildWindows() {
        // Clean up old windows
        for (screen, window) in windows {
            if !NSScreen.screens.contains(screen) {
                if let player = playerViews[screen] {
                    player.cleanup()
                    playerViews.removeValue(forKey: screen)
                }
                window.orderOut(nil)
                windows.removeValue(forKey: screen)
            }
        }
        
        // Build or adjust windows for all currently connected screens
        for screen in NSScreen.screens {
            if let existingWindow = windows[screen] {
                existingWindow.setFrame(screen.frame, display: true)
                playerViews[screen]?.frame = existingWindow.contentView?.bounds ?? .zero
            } else {
                createWindow(for: screen)
            }
        }
    }
    
    private func createWindow(for screen: NSScreen) {
        let frame = screen.frame
        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        
        // Set window level directly behind Finder icons
        let desktopLevel = Int(CGWindowLevelForKey(.desktopWindow))
        window.level = NSWindow.Level(rawValue: desktopLevel)
        
        // WindowServer performance optimizations:
        // .none sharing prevents inter-process memory buffer replication
        window.sharingType = .none
        window.animationBehavior = .none
        window.hasShadow = false
        window.isOpaque = true
        window.backgroundColor = .black
        
        // Ensure window stays across spaces, is stationary during Mission Control, doesn't cycle
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.canHide = false
        
        // CRITICAL: Mouse events must pass directly through to macOS Finder icons!
        window.ignoresMouseEvents = true
        
        let playerView = VideoPlayerView(frame: NSRect(origin: .zero, size: frame.size))
        playerView.autoresizingMask = [.width, .height]
        
        window.contentView = playerView
        window.orderFront(nil)
        
        windows[screen] = window
        playerViews[screen] = playerView
    }
    
    @objc private func screenParametersDidChange() {
        DispatchQueue.main.async { [weak self] in
            self?.rebuildWindows()
            self?.reloadCurrentWallpaper()
        }
    }
    
    @objc private func handleWallpaperChange(_ notification: Notification) {
        guard let item = notification.object as? WallpaperItem,
              let url = item.localFileURL else { return }
        playVideoOnAllScreens(url: url)
    }
    
    public func reloadCurrentWallpaper() {
        if let active = WallpaperStore.shared.activeWallpaper,
           let url = active.localFileURL {
            playVideoOnAllScreens(url: url)
        }
    }
    
    public func playVideoOnAllScreens(url: URL) {
        for (_, playerView) in playerViews {
            playerView.loadVideo(url: url)
        }
    }
    
    public func pauseAll() {
        for (_, playerView) in playerViews {
            playerView.pause()
        }
    }
    
    public func resumeAll() {
        for (_, playerView) in playerViews {
            playerView.resume()
        }
    }
    
    public func togglePlayback() {
        AppSettings.shared.isPausedByUser.toggle()
        if AppSettings.shared.isPausedByUser {
            pauseAll()
        } else {
            resumeAll()
        }
    }
    
    public func cycleNextWallpaper() {
        let downloaded = WallpaperStore.shared.wallpapers.filter { $0.isDownloaded }
        guard downloaded.count > 1 else { return }
        
        if let current = WallpaperStore.shared.activeWallpaper,
           let currentIndex = downloaded.firstIndex(where: { $0.id == current.id }) {
            let nextIndex = (currentIndex + 1) % downloaded.count
            WallpaperStore.shared.setActiveWallpaper(downloaded[nextIndex])
        } else if let first = downloaded.first {
            WallpaperStore.shared.setActiveWallpaper(first)
        }
    }
}
