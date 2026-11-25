import SwiftUI

public struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @State private var launchAtLoginState: Bool = LaunchAtLogin.isEnabled
    @State private var cacheClearedMessage: String?
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Startup
                VStack(alignment: .leading, spacing: 14) {
                    Text("Startup & Behavior")
                        .font(.headline)
                    
                    Toggle("Launch automatically at Login", isOn: $launchAtLoginState)
                        .onChange(of: launchAtLoginState) { newValue in
                            LaunchAtLogin.setEnabled(newValue)
                            settings.launchAtLogin = newValue
                        }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                // Audio
                VStack(alignment: .leading, spacing: 14) {
                    Text("Audio Settings")
                        .font(.headline)
                    
                    Toggle("Mute Wallpaper Audio (Recommended)", isOn: $settings.isMuted)
                    
                    if !settings.isMuted {
                        HStack {
                            Image(systemName: "speaker.wave.1")
                            Slider(value: $settings.volume, in: 0.0...1.0)
                            Image(systemName: "speaker.wave.3")
                            Text("\(Int(settings.volume * 100))%")
                                .font(.caption)
                                .frame(width: 40)
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                // Cache & Storage
                VStack(alignment: .leading, spacing: 14) {
                    Text("Storage & Cache")
                        .font(.headline)
                    
                    HStack {
                        Button(action: {
                            NSWorkspace.shared.open(WallpaperStore.wallpapersDirectory)
                        }) {
                            Text("Open Wallpapers Folder in Finder")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        
                        Spacer()
                        
                        Button(action: {
                            clearCache()
                        }) {
                            Text("Clear Wallpaper Cache")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    
                    if let msg = cacheClearedMessage {
                        Text(msg)
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                // About
                VStack(alignment: .leading, spacing: 8) {
                    Text("About MaC Wallspace")
                        .font(.headline)
                    Text("Version 1.0.0 (Native Swift & AppKit)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Built specifically for older Macs that struggle with or cannot run macOS Sonoma aerial wallpapers or heavy Electron-based live wallpaper apps. Designed for near-zero CPU and battery footprint.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Link("View GitHub Repository (Private)", destination: URL(string: "https://github.com/Sam-bot-dev/mac-wallspace")!)
                        .font(.caption)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
        }
    }
    
    private func clearCache() {
        let store = WallpaperStore.shared
        let dir = WallpaperStore.wallpapersDirectory
        if let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
            for file in files {
                if file.lastPathComponent != "default_offline_loop.mp4" {
                    try? FileManager.default.removeItem(at: file)
                }
            }
        }
        store.loadCatalog()
        cacheClearedMessage = "Cache cleared. Default offline loop preserved."
    }
}
