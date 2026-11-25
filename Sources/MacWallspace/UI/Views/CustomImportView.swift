import SwiftUI
import UniformTypeIdentifiers

public struct CustomImportView: View {
    @ObservedObject var store = WallpaperStore.shared
    @State private var isTargeted: Bool = false
    @State private var statusMessage: String?
    
    public var body: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isTargeted ? Color.accentColor : Color.secondary.opacity(0.4),
                        style: StrokeStyle(lineWidth: 2, dash: [8])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isTargeted ? Color.accentColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                    )
                
                VStack(spacing: 12) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 44))
                        .foregroundColor(isTargeted ? .accentColor : .secondary)
                    
                    Text("Drag & Drop Video File Here")
                        .font(.headline)
                    
                    Text("Supports MP4, MOV, M4V, and Animated GIF\nHardware-accelerated decoding via VideoToolbox")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: selectFileManually) {
                        HStack {
                            Image(systemName: "folder")
                            Text("Browse Files...")
                        }
                    }
                    .buttonStyle(ProminentButtonStyle())
                }
                .padding(24)
            }
            .frame(height: 220)
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                handleDrop(providers: providers)
                return true
            }
            
            if let msg = statusMessage {
                Text(msg)
                    .font(.footnote)
                    .foregroundColor(.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("💡 Pro-Tips for Older Macs:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("• 1080p H.264 MP4 videos will consume less than 2% CPU on Intel Core i5/i7 Macs.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("• Shorter loop durations (5 to 30 seconds) conserve RAM and decode cache.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
        }
    }
    
    private func selectFileManually() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [
            UTType.mpeg4Movie,
            UTType.quickTimeMovie,
            UTType.gif,
            UTType.movie
        ]
        
        if panel.runModal() == .OK, let url = panel.url {
            importVideo(from: url)
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            guard let fileURL = url else { return }
            DispatchQueue.main.async {
                self.importVideo(from: fileURL)
            }
        }
    }
    
    private func importVideo(from url: URL) {
        if let item = store.importCustomVideo(from: url) {
            statusMessage = "Successfully imported & applied '\(item.title)'!"
        } else {
            statusMessage = "Failed to import video. Please check file format."
        }
    }
}
