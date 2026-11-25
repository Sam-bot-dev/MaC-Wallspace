import SwiftUI

public struct PerformanceSettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @State private var powerInfo = PowerGovernor.shared
    @State private var showOptimizedToast: Bool = false
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // System profile banner
                HStack(spacing: 12) {
                    Image(systemName: "cpu")
                        .font(.system(size: 28))
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(SystemInfo.humanReadableProfile)
                            .font(.headline)
                        Text(SystemInfo.performanceRecommendation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        settings.applyOlderMacOptimizedProfile()
                        showOptimizedToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showOptimizedToast = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "bolt.badge.checkmark.fill")
                            Text("1-Click Intel / Older Mac Tune")
                        }
                    }
                    .buttonStyle(ProminentButtonStyle())
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                if showOptimizedToast {
                    Text("✓ Applied optimal low-power settings for your Mac!")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal)
                }
                
                // Battery & Power Governor
                VStack(alignment: .leading, spacing: 14) {
                    Text("Battery & Power Management")
                        .font(.headline)
                    
                    Toggle("Pause playback when running on Battery", isOn: $settings.pauseOnBattery)
                        .help("Completely halts video decoding when unplugged from AC adapter.")
                    
                    Toggle("Emergency pause on Low Battery (≤ 20%)", isOn: $settings.pauseOnLowBattery)
                        .help("Pauses live wallpaper if battery level is critically low.")
                    
                    Toggle("Pause when Fullscreen App or Game is active", isOn: $settings.pauseOnFullscreen)
                        .help("Gives 100% GPU/CPU power to your active games, IDEs, or videos.")
                    
                    Toggle("Pause when Displays Sleep / Screen Locks", isOn: $settings.pauseOnDisplaySleep)
                        .help("Zero energy consumption while display is sleeping.")
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                // Frame Rate & Decoding Controls
                VStack(alignment: .leading, spacing: 14) {
                    Text("Frame Rate & Thermal Control")
                        .font(.headline)
                    
                    HStack {
                        Text("Target Frame Rate:")
                            .font(.subheadline)
                        
                        Picker("", selection: $settings.targetFramerate) {
                            Text("24 FPS (Ultra-Battery Saver)").tag(24)
                            Text("30 FPS (Recommended for Older Macs)").tag(30)
                            Text("60 FPS (Silky Smooth)").tag(60)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    Text("Selecting 24 or 30 FPS significantly reduces GPU core temperatures on Intel MacBooks.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
        }
    }
}
