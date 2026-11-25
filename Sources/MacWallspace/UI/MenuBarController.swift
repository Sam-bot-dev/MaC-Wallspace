import Cocoa

public final class MenuBarController: NSObject, NSMenuDelegate {
    public static let shared = MenuBarController()
    
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    
    private override init() {
        super.init()
    }
    
    public func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            if #available(macOS 11.0, *) {
                let image = NSImage(systemSymbolName: "photo.artframe", accessibilityDescription: "MaC Wallspace")
                image?.isTemplate = true
                button.image = image
            } else {
                button.title = "🖼"
            }
        }
        
        menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        
        rebuildMenu()
    }
    
    public func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
    }
    
    public func rebuildMenu() {
        menu.removeAllItems()
        
        // Status header
        let isPaused = AppSettings.shared.isPausedByUser
        let statusTitle = "MaC Wallspace: \(isPaused ? "Paused" : "Running")"
        let headerItem = NSMenuItem(title: statusTitle, action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        
        // Active wallpaper
        if let active = WallpaperStore.shared.activeWallpaper {
            let activeItem = NSMenuItem(title: "Current: \(active.title)", action: nil, keyEquivalent: "")
            activeItem.isEnabled = false
            menu.addItem(activeItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Controls
        let playPauseItem = NSMenuItem(
            title: isPaused ? "Resume Live Wallpaper" : "Pause Live Wallpaper",
            action: #selector(togglePlayback),
            keyEquivalent: "p"
        )
        playPauseItem.target = self
        menu.addItem(playPauseItem)
        
        let nextItem = NSMenuItem(
            title: "Next Wallpaper",
            action: #selector(nextWallpaper),
            keyEquivalent: "n"
        )
        nextItem.target = self
        menu.addItem(nextItem)
        
        let muteTitle = AppSettings.shared.isMuted ? "Unmute Audio" : "Mute Audio"
        let muteItem = NSMenuItem(title: muteTitle, action: #selector(toggleMute), keyEquivalent: "m")
        muteItem.target = self
        menu.addItem(muteItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Open Gallery / Settings
        let galleryItem = NSMenuItem(
            title: "Open Wallspace Gallery & Settings...",
            action: #selector(openGallery),
            keyEquivalent: ","
        )
        galleryItem.target = self
        menu.addItem(galleryItem)
        
        let importItem = NSMenuItem(
            title: "Import Custom Video...",
            action: #selector(openImport),
            keyEquivalent: "i"
        )
        importItem.target = self
        menu.addItem(importItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Launch at login
        let launchItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchItem.state = LaunchAtLogin.isEnabled ? .on : .off
        launchItem.target = self
        menu.addItem(launchItem)
        
        // Power Profile Info
        let powerItem = NSMenuItem(
            title: "Profile: \(SystemInfo.isIntelMac ? "Intel Low Power" : "Apple Silicon")",
            action: nil,
            keyEquivalent: ""
        )
        powerItem.isEnabled = false
        menu.addItem(powerItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(
            title: "Quit MaC Wallspace",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    @objc private func togglePlayback() {
        DesktopWindowManager.shared.togglePlayback()
    }
    
    @objc private func nextWallpaper() {
        DesktopWindowManager.shared.cycleNextWallpaper()
    }
    
    @objc private func toggleMute() {
        AppSettings.shared.isMuted.toggle()
    }
    
    @objc private func openGallery() {
        GalleryWindowController.shared.show()
    }
    
    @objc private func openImport() {
        GalleryWindowController.shared.show()
    }
    
    @objc private func toggleLaunchAtLogin() {
        let newState = !LaunchAtLogin.isEnabled
        LaunchAtLogin.setEnabled(newState)
        AppSettings.shared.launchAtLogin = newState
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
