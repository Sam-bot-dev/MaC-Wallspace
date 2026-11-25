import Cocoa
import Combine

public final class DesktopWindowManager: ObservableObject {
    public static let shared = DesktopWindowManager()
    
    private var windows: [NSScreen: NSWindow] = [:]
    private var playerViews: [NSScreen: VideoPlayerView] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    @Published public var isMacDesktopExposed: Bool = false
    
    private init() {
        setupObservers()
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWallpaperChange(_:)),
            name: .macWallspaceDidChangeWallpaper,
            object: nil
        )
        
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
        
        let desktopLevel = Int(CGWindowLevelForKey(.desktopWindow))
        window.level = NSWindow.Level(rawValue: desktopLevel)
        
        window.sharingType = .none
        window.animationBehavior = .none
        window.hasShadow = false
        window.isOpaque = true
        window.backgroundColor = .black
        
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.canHide = false
        window.ignoresMouseEvents = true
        
        let playerView = VideoPlayerView(frame: NSRect(origin: .zero, size: frame.size))
        playerView.autoresizingMask = [.width, .height]
        
        window.contentView = playerView
        if !isMacDesktopExposed {
            window.orderFront(nil)
        }
        
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
        showAllWindows()
        playMediaOnAllScreens(url: url)
    }
    
    public func reloadCurrentWallpaper() {
        if let active = WallpaperStore.shared.activeWallpaper,
           let url = active.localFileURL {
            playMediaOnAllScreens(url: url)
        }
    }
    
    public func playMediaOnAllScreens(url: URL) {
        for (_, playerView) in playerViews {
            playerView.loadMedia(url: url)
        }
    }
    
    public func pauseAll() {
        for (_, playerView) in playerViews {
            playerView.pause()
        }
    }
    
    public func resumeAll() {
        guard !isMacDesktopExposed else { return }
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
        PlaylistManager.shared.cycleNext()
    }
    
    public func cyclePreviousWallpaper() {
        PlaylistManager.shared.cyclePrevious()
    }
    
    // MARK: - Revert / Show Native macOS Desktop
    
    public func hideAllWindows() {
        isMacDesktopExposed = true
        pauseAll()
        for (_, window) in windows {
            window.orderOut(nil)
        }
    }
    
    public func showAllWindows() {
        isMacDesktopExposed = false
        for (_, window) in windows {
            window.orderFront(nil)
        }
        resumeAll()
    }
    
    public func toggleMacDesktop() {
        if isMacDesktopExposed {
            showAllWindows()
        } else {
            hideAllWindows()
        }
    }
    
    public func resetToDefaultWallpaper() {
        showAllWindows()
        WallpaperStore.shared.resetToDefault()
    }
}
