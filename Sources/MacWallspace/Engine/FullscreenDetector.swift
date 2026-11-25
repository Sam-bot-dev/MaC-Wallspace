import Cocoa

public final class FullscreenDetector {
    public static let shared = FullscreenDetector()
    
    private var timer: Timer?
    private var isFullscreenActive: Bool = false
    
    private init() {
        setupObservers()
        startMonitoring()
    }
    
    private func setupObservers() {
        let ws = NSWorkspace.shared.notificationCenter
        ws.addObserver(self, selector: #selector(handleAppOrSpaceChange), name: NSWorkspace.didActivateApplicationNotification, object: nil)
        ws.addObserver(self, selector: #selector(handleAppOrSpaceChange), name: NSWorkspace.activeSpaceDidChangeNotification, object: nil)
    }
    
    @objc private func handleAppOrSpaceChange() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.checkFullscreenState()
        }
    }
    
    public func startMonitoring() {
        // Run check every 4 seconds on background thread to keep main runloop completely unblocked
        timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            DispatchQueue.global(qos: .utility).async {
                self?.checkFullscreenState()
            }
        }
    }
    
    private func checkFullscreenState() {
        guard AppSettings.shared.pauseOnFullscreen else { return }
        
        let isFrontmostFullscreen = detectIfFrontmostAppIsFullscreen()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if isFrontmostFullscreen && !self.isFullscreenActive {
                self.isFullscreenActive = true
                DesktopWindowManager.shared.pauseAll()
            } else if !isFrontmostFullscreen && self.isFullscreenActive {
                self.isFullscreenActive = false
                if !AppSettings.shared.isPausedByUser {
                    PowerGovernor.shared.evaluatePowerState()
                }
            }
        }
    }
    
    private func detectIfFrontmostAppIsFullscreen() -> Bool {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return false }
        
        // If Finder is frontmost, user is on desktop
        if frontApp.bundleIdentifier == "com.apple.finder" {
            return false
        }
        
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
            if width >= screenBounds.width && height >= screenBounds.height - 25 {
                return true
            }
        }
        
        return false
    }
}
