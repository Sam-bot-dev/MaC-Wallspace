import Cocoa

public struct DisplayInfo: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let resolution: String
    public let isMain: Bool
    public let frame: NSRect
}

public final class DisplayMonitor: ObservableObject {
    public static let shared = DisplayMonitor()
    
    @Published public var displays: [DisplayInfo] = []
    
    private init() {
        refreshDisplays()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    @objc private func handleScreenChange() {
        refreshDisplays()
    }
    
    public func refreshDisplays() {
        var list: [DisplayInfo] = []
        for (index, screen) in NSScreen.screens.enumerated() {
            let isMain = (screen == NSScreen.main)
            let width = Int(screen.frame.width)
            let height = Int(screen.frame.height)
            let name = screen.localizedName
            let displayId = "\(screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] ?? index)"
            
            list.append(
                DisplayInfo(
                    id: displayId,
                    name: name,
                    resolution: "\(width) × \(height)",
                    isMain: isMain,
                    frame: screen.frame
                )
            )
        }
        self.displays = list
    }
}
