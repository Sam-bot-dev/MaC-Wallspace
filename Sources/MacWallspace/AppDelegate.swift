import Cocoa

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as accessory app (menu bar icon without occupying Dock space)
        NSApp.setActivationPolicy(.accessory)
        
        // Ensure default offline sample live wallpapers exist
        SampleVideoGenerator.ensureDefaultOfflineWallpapersExist()
        
        // Setup menu bar item
        MenuBarController.shared.setup()
        
        // Bootstrap desktop window manager
        DesktopWindowManager.shared.start()
        
        // Activate power & fullscreen background governors
        _ = PowerGovernor.shared
        _ = FullscreenDetector.shared
        
        // Show gallery window on first launch
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "mac_wallspace_has_launched")
        if !hasLaunchedBefore {
            UserDefaults.standard.set(true, forKey: "mac_wallspace_has_launched")
            GalleryWindowController.shared.show()
        }
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        DesktopWindowManager.shared.pauseAll()
    }
}
