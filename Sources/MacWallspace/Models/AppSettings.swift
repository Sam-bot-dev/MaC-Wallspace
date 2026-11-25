import Foundation
import Combine

public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()
    
    private let defaults = UserDefaults.standard
    
    // Keys
    private enum Keys {
        static let currentWallpaperId = "mac_wallspace_current_wallpaper_id"
        static let pauseOnBattery = "mac_wallspace_pause_on_battery"
        static let pauseOnLowBattery = "mac_wallspace_pause_on_low_battery"
        static let lowBatteryThreshold = "mac_wallspace_low_battery_threshold"
        static let pauseOnFullscreen = "mac_wallspace_pause_on_fullscreen"
        static let pauseOnDisplaySleep = "mac_wallspace_pause_on_display_sleep"
        static let targetFramerate = "mac_wallspace_target_framerate"
        static let volume = "mac_wallspace_volume"
        static let isMuted = "mac_wallspace_is_muted"
        static let launchAtLogin = "mac_wallspace_launch_at_login"
        static let isPausedByUser = "mac_wallspace_is_paused_by_user"
        static let scaleMode = "mac_wallspace_scale_mode"
        static let selectedCategory = "mac_wallspace_selected_category"
    }
    
    @Published public var currentWallpaperId: String? {
        didSet { defaults.set(currentWallpaperId, forKey: Keys.currentWallpaperId) }
    }
    
    @Published public var pauseOnBattery: Bool {
        didSet { defaults.set(pauseOnBattery, forKey: Keys.pauseOnBattery) }
    }
    
    @Published public var pauseOnLowBattery: Bool {
        didSet { defaults.set(pauseOnLowBattery, forKey: Keys.pauseOnLowBattery) }
    }
    
    @Published public var lowBatteryThreshold: Int {
        didSet { defaults.set(lowBatteryThreshold, forKey: Keys.lowBatteryThreshold) }
    }
    
    @Published public var pauseOnFullscreen: Bool {
        didSet { defaults.set(pauseOnFullscreen, forKey: Keys.pauseOnFullscreen) }
    }
    
    @Published public var pauseOnDisplaySleep: Bool {
        didSet { defaults.set(pauseOnDisplaySleep, forKey: Keys.pauseOnDisplaySleep) }
    }
    
    @Published public var targetFramerate: Int {
        didSet { defaults.set(targetFramerate, forKey: Keys.targetFramerate) }
    }
    
    @Published public var volume: Float {
        didSet { defaults.set(volume, forKey: Keys.volume) }
    }
    
    @Published public var isMuted: Bool {
        didSet { defaults.set(isMuted, forKey: Keys.isMuted) }
    }
    
    @Published public var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: Keys.launchAtLogin) }
    }
    
    @Published public var isPausedByUser: Bool {
        didSet { defaults.set(isPausedByUser, forKey: Keys.isPausedByUser) }
    }
    
    @Published public var scaleMode: String {
        didSet { defaults.set(scaleMode, forKey: Keys.scaleMode) }
    }
    
    @Published public var selectedCategory: String {
        didSet { defaults.set(selectedCategory, forKey: Keys.selectedCategory) }
    }
    
    private init() {
        self.currentWallpaperId = defaults.string(forKey: Keys.currentWallpaperId)
        self.pauseOnBattery = defaults.object(forKey: Keys.pauseOnBattery) as? Bool ?? true
        self.pauseOnLowBattery = defaults.object(forKey: Keys.pauseOnLowBattery) as? Bool ?? true
        self.lowBatteryThreshold = defaults.object(forKey: Keys.lowBatteryThreshold) as? Int ?? 20
        self.pauseOnFullscreen = defaults.object(forKey: Keys.pauseOnFullscreen) as? Bool ?? true
        self.pauseOnDisplaySleep = defaults.object(forKey: Keys.pauseOnDisplaySleep) as? Bool ?? true
        self.targetFramerate = defaults.object(forKey: Keys.targetFramerate) as? Int ?? 30 // 30fps default for older Macs
        self.volume = defaults.object(forKey: Keys.volume) as? Float ?? 0.0
        self.isMuted = defaults.object(forKey: Keys.isMuted) as? Bool ?? true
        self.launchAtLogin = defaults.object(forKey: Keys.launchAtLogin) as? Bool ?? false
        self.isPausedByUser = defaults.object(forKey: Keys.isPausedByUser) as? Bool ?? false
        self.scaleMode = defaults.string(forKey: Keys.scaleMode) ?? "aspectFill"
        self.selectedCategory = defaults.string(forKey: Keys.selectedCategory) ?? "All"
    }
    
    public func applyOlderMacOptimizedProfile() {
        pauseOnBattery = true
        pauseOnLowBattery = true
        pauseOnFullscreen = true
        pauseOnDisplaySleep = true
        targetFramerate = 24 // Super low CPU draw on older Intel HD graphics
        isMuted = true
        volume = 0.0
    }
}
