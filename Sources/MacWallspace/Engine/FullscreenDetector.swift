import Cocoa

public final class FullscreenDetector {
    public static let shared = FullscreenDetector()
    
    private var timer: Timer?
    private var isFullscreenActive: Bool = false
    
    private init() {
        startMonitoring()
    }
    
    public func startMonitoring() {
        // Check every 3 seconds to keep CPU negligible (<0.01%)
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.checkFullscreenState()
        }
    }
    
    private func checkFullscreenState() {
        guard AppSettings.shared.pauseOnFullscreen else { return }
        
        let isFrontmostFullscreen = detectIfFrontmostAppIsFullscreen()
        
        if isFrontmostFullscreen && !isFullscreenActive {
            isFullscreenActive = true
            DesktopWindowManager.shared.pauseAll()
        } else if !isFrontmostFullscreen && isFullscreenActive {
            isFullscreenActive = false
            if !AppSettings.shared.isPausedByUser {
                PowerGovernor.shared.evaluatePowerState()
            }
        }
    }
    
    private func detectIfFrontmostAppIsFullscreen() -> Bool {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return false }
        
        // If Finder is frontmost, user is on desktop!
        if frontApp.bundleIdentifier == "com.apple.finder" {
            return false
        }
        
        // Check window list for frontmost app covering main screen
        guard let screen = NSScreen.main else { return false }
        let screenBounds = screen.frame
        
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return false
        }
        
        for info in windowList {
            guard let pid = info[kCGWindowOwnerPID as String] as? pid_t, pid == frontApp.processIdentifier,
                  let boundsDict = info[kCGWindowBounds as String] as? [String: CGFloat],
                  let width = boundsDict["Width"],
                  let height = boundsDict["Height"] else {
                continue
            }
            
            // Check if frontmost window dimensions match or exceed screen size
            if width >= screenBounds.width && height >= screenBounds.height - 25 { // Allow slight menu bar offset
                return true
            }
        }
        
        return false
    }
}
