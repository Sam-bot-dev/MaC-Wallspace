import SwiftUI

public struct ProminentButtonStyle: ButtonStyle {
    public var backgroundColor: Color = .green
    public var foregroundColor: Color = .white
    
    public init(backgroundColor: Color = .green, foregroundColor: Color = .white) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(configuration.isPressed ? backgroundColor.opacity(0.7) : backgroundColor)
            .cornerRadius(6)
    }
}

public struct SecondaryButtonStyle: ButtonStyle {
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(configuration.isPressed ? Color.white.opacity(0.15) : Color.white.opacity(0.08))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            )
    }
}

public struct WallpaperCardView: View {
    public let item: WallpaperItem
    @ObservedObject var store = WallpaperStore.shared
    @ObservedObject var downloader = WallpaperDownloader.shared
    @ObservedObject var playlistManager = PlaylistManager.shared
    @State private var loadedImage: NSImage? = nil
    
    public init(item: WallpaperItem) {
        self.item = item
    }
    
    public init(wallpaper: WallpaperItem) {
        self.item = wallpaper
    }
    
    public var isActive: Bool {
        store.activeWallpaper?.id == item.id
    }
    
    public var isInActivePlaylist: Bool {
        playlistManager.activePlaylist?.itemIds.contains(item.id) ?? false
    }
    
    public var isDownloading: Bool {
        downloader.isDownloading[item.id] ?? false
    }
    
    public var downloadProgress: Double {
        downloader.downloadProgress[item.id] ?? 0.0
    }
    
    private var thumbnailImage: NSImage? {
        guard let path = item.thumbnailUrl else { return nil }
        
        // 1. Direct path or file exists
        if FileManager.default.fileExists(atPath: path) {
            return NSImage(contentsOfFile: path)
        }
        
        // 2. Bundled resource (previews/)
        if let bundleURL = Bundle.main.resourceURL {
            let inPreviews = bundleURL.appendingPathComponent("previews/\(path)").path
            if FileManager.default.fileExists(atPath: inPreviews) {
                return NSImage(contentsOfFile: inPreviews)
            }
            let direct = bundleURL.appendingPathComponent(path).path
            if FileManager.default.fileExists(atPath: direct) {
                return NSImage(contentsOfFile: direct)
            }
        }
        
        // 3. Application Support / Thumbnails
        let inThumbnails = WallpaperStore.thumbnailsDirectory.appendingPathComponent(path).path
        if FileManager.default.fileExists(atPath: inThumbnails) {
            return NSImage(contentsOfFile: inThumbnails)
        }
        
        let byId = WallpaperStore.thumbnailsDirectory.appendingPathComponent("\(item.id.uuidString).jpg").path
        if FileManager.default.fileExists(atPath: byId) {
            return NSImage(contentsOfFile: byId)
        }
        
        // 4. Fallback dev docs preview
        let devFallback = "/Users/sammy/Desktop/Code/MaC-Wallspace/docs/previews/\(path)"
        if FileManager.default.fileExists(atPath: devFallback) {
            return NSImage(contentsOfFile: devFallback)
        }
        
        return nil
    }
    
    private func loadAsyncThumbnail() {
        if let direct = thumbnailImage {
            self.loadedImage = direct
            return
        }
        
        let candidateURL: String? = {
            if let t = item.thumbnailUrl, t.hasPrefix("http") { return t }
            let v = item.videoUrl
            let ext = (URL(string: v)?.pathExtension ?? "").lowercased()
            if ["jpg", "jpeg", "png", "webp"].contains(ext) && v.hasPrefix("http") {
                return v
            }
            return nil
        }()
        
        guard let urlStr = candidateURL, let url = URL(string: urlStr) else { return }
        let cachedFile = WallpaperStore.thumbnailsDirectory.appendingPathComponent("\(item.id.uuidString).jpg")
        
        if FileManager.default.fileExists(atPath: cachedFile.path), let cached = NSImage(contentsOf: cachedFile) {
            self.loadedImage = cached
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let img = NSImage(data: data) else { return }
            if let tiff = img.tiffRepresentation,
               let rep = NSBitmapImageRep(data: tiff),
               let jpeg = rep.representation(using: .jpeg, properties: [:]) {
                try? jpeg.write(to: cachedFile)
            }
            DispatchQueue.main.async {
                self.loadedImage = img
            }
        }.resume()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail / Preview Box — 100% Contained, Never Spills Out
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Color(red: 0.04, green: 0.04, blue: 0.05)
                    
                    if let img = loadedImage ?? thumbnailImage {
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: 140)
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: iconForCategory(item.category))
                                .font(.system(size: 32))
                                .foregroundColor(.green)
                            Text(item.title)
                                .font(.headline)
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }
                    }
                }
                .frame(height: 140)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .onAppear {
                    loadAsyncThumbnail()
                }
                
                // Badges
                HStack(spacing: 4) {
                    if isActive {
                        Text("ACTIVE")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    
                    Text(item.resolution)
                        .font(.system(size: 9, weight: .semibold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                .padding(8)
            }
            
            // Metadata
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(item.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Spacer()
                    if item.fileSizeMB > 0 {
                        Text("\(String(format: "%.1f", item.fileSizeMB)) MB")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let author = item.author {
                    Text(author)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            // Action Buttons
            HStack(spacing: 8) {
                if item.isDownloaded {
                    Button(action: {
                        DesktopWindowManager.shared.showAllWindows()
                        store.setActiveWallpaper(item)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: isActive ? "checkmark.circle.fill" : "play.fill")
                            Text(isActive ? "Applied" : "Apply")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ProminentButtonStyle(backgroundColor: isActive ? Color.green : Color.green.opacity(0.85)))
                    .disabled(isActive)
                    
                    Button(action: {
                        if let activeId = playlistManager.activePlaylistId {
                            playlistManager.toggleItem(item.id, in: activeId)
                        }
                    }) {
                        Image(systemName: isInActivePlaylist ? "text.badge.checkmark" : "text.badge.plus")
                            .foregroundColor(isInActivePlaylist ? .green : .secondary)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .help(isInActivePlaylist ? "In active playlist (click to remove)" : "Add to active playlist")
                    
                    if item.isCustom || item.localFileName != nil {
                        Button(action: {
                            store.deleteWallpaper(item)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .help("Delete from local library")
                    }
                } else if isDownloading {
                    VStack(spacing: 4) {
                        ProgressView(value: downloadProgress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle())
                        Text("\(Int(downloadProgress * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Button(action: {
                        downloader.downloadWallpaper(item)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle")
                            Text("Download")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.08, green: 0.08, blue: 0.10))
                .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? Color.green : Color.white.opacity(0.12), lineWidth: isActive ? 2 : 1)
        )
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Aerial": return "airplane"
        case "Nature": return "leaf.fill"
        case "Sci-Fi": return "sparkles"
        case "Anime & Cozy": return "cup.and.saucer.fill"
        case "Minimalist": return "waveform"
        case "Custom": return "video.badge.plus"
        default: return "photo.fill"
        }
    }
}
