import SwiftUI

public struct ProminentButtonStyle: ButtonStyle {
    public var backgroundColor: Color = .accentColor
    public var foregroundColor: Color = .white
    
    public init(backgroundColor: Color = .accentColor, foregroundColor: Color = .white) {
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
            .foregroundColor(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(configuration.isPressed ? Color.secondary.opacity(0.2) : Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
    }
}

public struct WallpaperCardView: View {
    public let item: WallpaperItem
    @ObservedObject var store = WallpaperStore.shared
    @ObservedObject var downloader = WallpaperDownloader.shared
    
    public var isActive: Bool {
        store.activeWallpaper?.id == item.id
    }
    
    public var isDownloading: Bool {
        downloader.isDownloading[item.id] ?? false
    }
    
    public var downloadProgress: Double {
        downloader.downloadProgress[item.id] ?? 0.0
    }
    
    private var thumbnailImage: NSImage? {
        if let path = item.thumbnailUrl, FileManager.default.fileExists(atPath: path) {
            return NSImage(contentsOfFile: path)
        }
        return nil
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail / Preview Box
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .frame(height: 140)
                    .overlay(
                        Group {
                            if let img = thumbnailImage {
                                Image(nsImage: img)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 140)
                                    .clipped()
                                    .cornerRadius(10)
                            } else {
                                VStack(spacing: 8) {
                                    Image(systemName: iconForCategory(item.category))
                                        .font(.system(size: 32))
                                        .foregroundColor(.accentColor)
                                    Text(item.title)
                                        .font(.headline)
                                        .lineLimit(1)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 8)
                                }
                            }
                        }
                    )
                
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
                        .background(Color.black.opacity(0.6))
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
                        store.setActiveWallpaper(item)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: isActive ? "checkmark.circle.fill" : "play.fill")
                            Text(isActive ? "Applied" : "Apply")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ProminentButtonStyle(backgroundColor: isActive ? Color.green : Color.accentColor))
                    .disabled(isActive)
                    
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
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? Color.accentColor : Color.clear, lineWidth: 2)
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
