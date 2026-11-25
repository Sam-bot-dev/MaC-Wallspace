import Cocoa
import IOKit.ps

public final class PowerGovernor {
    public static let shared = PowerGovernor()
    
    private var timer: Timer?
    private var isSystemSleeping: Bool = false
    private var isDisplaySleeping: Bool = false
    private var powerRunLoopSource: CFRunLoopSource?
    
    public private(set) var isOnBattery: Bool = false
    public private(set) var batteryPercentage: Int = 100
    
    private init() {
        setupSleepObservers()
        setupIOPSNotification()
        updatePowerState()
        startPeriodicCheck()
    }
    
    private func setupIOPSNotification() {
        // Register for immediate hardware power source change notifications (charger plugged/unplugged)
        let source = IOPSNotificationCreateRunLoopSource({ _ in
            DispatchQueue.main.async {
                PowerGovernor.shared.evaluatePowerState()
            }
        }, nil)?.takeRetainedValue()
        
        if let source = source {
            self.powerRunLoopSource = source
            CFRunLoopAddSource(CFRunLoopGetMain(), source, CFRunLoopMode.defaultMode)
        }
    }
    
    private func setupSleepObservers() {
        let ws = NSWorkspace.shared.notificationCenter
        
        ws.addObserver(self, selector: #selector(displayDidSleep), name: NSWorkspace.screensDidSleepNotification, object: nil)
        ws.addObserver(self, selector: #selector(displayDidWake), name: NSWorkspace.screensDidWakeNotification, object: nil)
        ws.addObserver(self, selector: #selector(systemWillSleep), name: NSWorkspace.willSleepNotification, object: nil)
        ws.addObserver(self, selector: #selector(systemDidWake), name: NSWorkspace.didWakeNotification, object: nil)
        ws.addObserver(self, selector: #selector(sessionDidResignActive), name: NSWorkspace.sessionDidResignActiveNotification, object: nil)
        ws.addObserver(self, selector: #selector(sessionDidBecomeActive), name: NSWorkspace.sessionDidBecomeActiveNotification, object: nil)
    }
    
    private func startPeriodicCheck() {
        // Check power status every 15 seconds (minimal CPU overhead)
        timer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            self?.evaluatePowerState()
        }
    }
    
    public func updatePowerState() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            isOnBattery = false
            batteryPercentage = 100
            return
        }
        
        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }
            
            if let powerSourceState = description[kIOPSPowerSourceStateKey as String] as? String {
                isOnBattery = (powerSourceState == kIOPSBatteryPowerValue as String)
            }
            
            if let current = description[kIOPSCurrentCapacityKey as String] as? Int,
               let max = description[kIOPSMaxCapacityKey as String] as? Int, max > 0 {
                batteryPercentage = Int((Double(current) / Double(max)) * 100)
            }
        }
    }
    
    public func evaluatePowerState() {
        updatePowerState()
        
        if isSystemSleeping || isDisplaySleeping {
            DesktopWindowManager.shared.pauseAll()
            return
        }
        
        // Auto pause on battery
        if isOnBattery && AppSettings.shared.pauseOnBattery {
            DesktopWindowManager.shared.pauseAll()
            return
        }
        
        // Low battery auto-pause
        if isOnBattery && AppSettings.shared.pauseOnLowBattery && batteryPercentage <= AppSettings.shared.lowBatteryThreshold {
            DesktopWindowManager.shared.pauseAll()
            return
        }
        
        // If not paused by user, resume
        if !AppSettings.shared.isPausedByUser {
            DesktopWindowManager.shared.resumeAll()
        }
    }
    
    @objc private func displayDidSleep() {
        isDisplaySleeping = true
        DesktopWindowManager.shared.pauseAll()
    }
    
    @objc private func displayDidWake() {
        isDisplaySleeping = false
        evaluatePowerState()
    }
    
    @objc private func systemWillSleep() {
        isSystemSleeping = true
        DesktopWindowManager.shared.pauseAll()
    }
    
    @objc private func systemDidWake() {
        isSystemSleeping = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.evaluatePowerState()
        }
    }
    
    @objc private func sessionDidResignActive() {
        DesktopWindowManager.shared.pauseAll()
    }
    
    @objc private func sessionDidBecomeActive() {
        evaluatePowerState()
    }
}
