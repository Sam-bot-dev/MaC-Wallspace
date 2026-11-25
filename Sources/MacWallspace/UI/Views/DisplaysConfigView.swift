import SwiftUI

public struct DisplaysConfigView: View {
    @ObservedObject var monitor = DisplayMonitor.shared
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var store = WallpaperStore.shared
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Connected Displays")
                .font(.headline)
            
            ForEach(monitor.displays) { display in
                HStack(spacing: 16) {
                    Image(systemName: display.isMain ? "display" : "display.2")
                        .font(.system(size: 32))
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(display.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            if display.isMain {
                                Text("Primary")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                        
                        Text("Resolution: \(display.resolution)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if let active = store.activeWallpaper {
                        Text(active.title)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Display Fit & Scaling")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Picker("Scaling Mode", selection: $settings.scaleMode) {
                    Text("Aspect Fill (Full Screen, No Borders)").tag("aspectFill")
                    Text("Aspect Fit (Preserve Aspect Ratio)").tag("aspectFit")
                }
                .pickerStyle(RadioGroupPickerStyle())
            }
            
            Spacer()
        }
        .padding()
    }
}
