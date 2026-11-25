import Foundation

public struct SystemInfo {
    public static var modelIdentifier: String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &machine, &size, nil, 0)
        return String(cString: machine)
    }
    
    public static var isIntelMac: Bool {
        #if arch(x86_64)
        return true
        #else
        return false
        #endif
    }
    
    public static var macOSVersionString: String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
    }
    
    public static var humanReadableProfile: String {
        let arch = isIntelMac ? "Intel x86_64" : "Apple Silicon"
        return "\(modelIdentifier) (\(arch)) — macOS \(macOSVersionString)"
    }
    
    public static var performanceRecommendation: String {
        if isIntelMac {
            return "Intel Architecture detected: Hardware-accelerated H.264 decode is active. 'Pause on Battery' & 30 FPS cap are enabled to keep fans silent."
        } else {
            return "Apple Silicon detected: Ultra-efficient unified memory decode active. Low power impact across all resolutions."
        }
    }
}
