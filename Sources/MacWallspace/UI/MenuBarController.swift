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
        let isMacDesktop = DesktopWindowManager.shared.isMacDesktopExposed
        let isPaused = AppSettings.shared.isPausedByUser
        
        let statusTitle: String
        if isMacDesktop {
            statusTitle = "MaC Wallspace: macOS Desktop Showing"
        } else if isPaused {
            statusTitle = "MaC Wallspace: Paused"
        } else {
            statusTitle = "MaC Wallspace: Running (60 FPS)"
        }
        
        let headerItem = NSMenuItem(title: statusTitle, action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        
        // Active wallpaper
        if !isMacDesktop, let active = WallpaperStore.shared.activeWallpaper {
            let activeItem = NSMenuItem(title: "Current: \(active.title)", action: nil, keyEquivalent: "")
            activeItem.isEnabled = false
            menu.addItem(activeItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Playback Controls
        let playPauseItem = NSMenuItem(
            title: isPaused ? "Resume Wallpaper" : "Pause Wallpaper",
            action: #selector(togglePlayback),
            keyEquivalent: "p"
        )
        playPauseItem.target = self
        menu.addItem(playPauseItem)
        
        let nextItem = NSMenuItem(
            title: "Next Wallpaper in Playlist",
            action: #selector(nextWallpaper),
            keyEquivalent: "n"
        )
        nextItem.target = self
        menu.addItem(nextItem)
        
        let prevItem = NSMenuItem(
            title: "Previous Wallpaper in Playlist",
            action: #selector(previousWallpaper),
            keyEquivalent: "N"
        )
        prevItem.target = self
        menu.addItem(prevItem)
        
        // Playlist Submenu
        let playlistMenu = NSMenu()
        let activePlaylist = PlaylistManager.shared.activePlaylist
        let activeName = activePlaylist?.name ?? "My Live Wallpapers"
        let playlistMenuItem = NSMenuItem(title: "Playlist: \(activeName)", action: nil, keyEquivalent: "")
        
        for playlist in PlaylistManager.shared.playlists {
            let item = NSMenuItem(
                title: "\(playlist.name) (\(playlist.itemIds.count))",
                action: #selector(switchPlaylist(_:)),
                keyEquivalent: ""
            )
            item.representedObject = playlist.id
            item.target = self
            if playlist.id == PlaylistManager.shared.activePlaylistId {
                item.state = .on
            }
            playlistMenu.addItem(item)
        }
        
        playlistMenu.addItem(NSMenuItem.separator())
        if let current = activePlaylist, current.cycleIntervalMinutes > 0 {
            let cycleInfo = NSMenuItem(title: "Auto-Cycle: Every \(current.cycleIntervalMinutes) min", action: nil, keyEquivalent: "")
            cycleInfo.isEnabled = false
            playlistMenu.addItem(cycleInfo)
        }
        
        let manageItem = NSMenuItem(title: "Manage Playlists in Gallery...", action: #selector(openPlaylists), keyEquivalent: "")
        manageItem.target = self
        playlistMenu.addItem(manageItem)
        
        playlistMenuItem.submenu = playlistMenu
        menu.addItem(playlistMenuItem)
        
        // Reset to Default Wallpaper
        let defaultItem = NSMenuItem(
            title: "Reset to Default Wallpaper",
            action: #selector(resetToDefault),
            keyEquivalent: "d"
        )
        defaultItem.target = self
        menu.addItem(defaultItem)
        
        // Show / Hide native macOS desktop
        let desktopTitle = isMacDesktop ? "Restore MaC Wallspace" : "Show macOS Default Wallpaper"
        let desktopItem = NSMenuItem(
            title: desktopTitle,
            action: #selector(toggleMacDesktop),
            keyEquivalent: ""
        )
        desktopItem.target = self
        menu.addItem(desktopItem)
        
        let muteTitle = AppSettings.shared.isMuted ? "Unmute Audio" : "Mute Audio"
        let muteItem = NSMenuItem(title: muteTitle, action: #selector(toggleMute), keyEquivalent: "m")
        muteItem.target = self
        menu.addItem(muteItem)
        
        // 3D Coverflow Switcher
        let switcherItem = NSMenuItem(
            title: "3D Wallpaper Switcher (Coverflow)...",
            action: #selector(openCoverflowSwitcher),
            keyEquivalent: "w"
        )
        switcherItem.keyEquivalentModifierMask = [.command, .shift]
        switcherItem.target = self
        menu.addItem(switcherItem)
        
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
            title: "Import Custom Video or Photo...",
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
        
        // Hardware Profile Info
        let powerItem = NSMenuItem(
            title: "Engine: Hardware H.264 (60 FPS)",
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
    
    @objc private func previousWallpaper() {
        DesktopWindowManager.shared.cyclePreviousWallpaper()
    }
    
    @objc private func switchPlaylist(_ sender: NSMenuItem) {
        if let playlistId = sender.representedObject as? UUID {
            PlaylistManager.shared.activePlaylistId = playlistId
            PlaylistManager.shared.cycleNext()
        }
    }
    
    @objc private func openPlaylists() {
        GalleryWindowController.shared.show()
    }
    
    @objc private func openCoverflowSwitcher() {
        CoverflowWindowController.shared.show()
    }
    
    @objc private func resetToDefault() {
        DesktopWindowManager.shared.resetToDefaultWallpaper()
    }
    
    @objc private func toggleMacDesktop() {
        DesktopWindowManager.shared.toggleMacDesktop()
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
