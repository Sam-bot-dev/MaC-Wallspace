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
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 44))
                        .foregroundColor(isTargeted ? .accentColor : .secondary)
                    
                    Text("Drag & Drop Video or Photo Wallpaper Here")
                        .font(.headline)
                    
                    Text("Supports Live Videos (MP4, MOV, GIF) & High-Res Photos (PNG, JPG, HEIC, WEBP)\nPhotos run at 0.0% CPU • Videos run at smooth 60 FPS")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: selectFileManually) {
                        HStack {
                            Image(systemName: "folder")
                            Text("Browse Videos & Photos...")
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
                Text("💡 Pro-Tips for Wallpaper Formats:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("• Photos (PNG, JPG, HEIC) use zero decode overhead and crisp Retina scaling.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("• 60 FPS H.264 MP4 videos will match your Mac's screen refresh rate.")
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
            UTType.movie,
            UTType.image,
            UTType.jpeg,
            UTType.png,
            UTType.heic
        ]
        
        if panel.runModal() == .OK, let url = panel.url {
            importMedia(from: url)
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            guard let fileURL = url else { return }
            DispatchQueue.main.async {
                self.importMedia(from: fileURL)
            }
        }
    }
    
    private func importMedia(from url: URL) {
        if let item = store.importCustomMedia(from: url) {
            statusMessage = "✓ Successfully imported & applied '\(item.title)'!"
        } else {
            statusMessage = "Failed to import file. Please check format."
        }
    }
}
