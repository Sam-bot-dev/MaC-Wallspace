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
        
        // Always show gallery window on launch
        GalleryWindowController.shared.show()
    }
    
    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        GalleryWindowController.shared.show()
        return true
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        DesktopWindowManager.shared.pauseAll()
    }
}
