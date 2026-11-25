import Foundation
import ServiceManagement

public final class LaunchAtLogin {
    private static let bundleId = "com.sammy.macwallspace"
    
    private static var launchAgentPlistURL: URL {
        let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        let launchAgents = library.appendingPathComponent("LaunchAgents", isDirectory: true)
        if !FileManager.default.fileExists(atPath: launchAgents.path) {
            try? FileManager.default.createDirectory(at: launchAgents, withIntermediateDirectories: true)
        }
        return launchAgents.appendingPathComponent("\(bundleId).plist")
    }
    
    public static var isEnabled: Bool {
        return FileManager.default.fileExists(atPath: launchAgentPlistURL.path)
    }
    
    public static func setEnabled(_ enabled: Bool) {
        if enabled {
            installLaunchAgent()
        } else {
            removeLaunchAgent()
        }
    }
    
    private static func installLaunchAgent() {
        guard let appURL = Bundle.main.bundleURL as URL? else { return }
        let executablePath = appURL.appendingPathComponent("Contents/MacOS/MacWallspace").path
        
        let plistDict: [String: Any] = [
            "Label": bundleId,
            "ProgramArguments": [executablePath],
            "RunAtLoad": true,
            "ProcessType": "Interactive"
        ]
        
        if let data = try? PropertyListSerialization.data(fromPropertyList: plistDict, format: .xml, options: 0) {
            try? data.write(to: launchAgentPlistURL)
        }
    }
    
    private static func removeLaunchAgent() {
        try? FileManager.default.removeItem(at: launchAgentPlistURL)
    }
}
