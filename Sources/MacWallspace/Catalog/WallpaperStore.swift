import Foundation
import Combine

public final class WallpaperStore: ObservableObject {
    public static let shared = WallpaperStore()
    
    public static var appSupportDirectory: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("MacWallspace", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    public static var wallpapersDirectory: URL {
        let dir = appSupportDirectory.appendingPathComponent("Wallpapers", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    private var catalogFileURL: URL {
        return Self.appSupportDirectory.appendingPathComponent("catalog.json")
    }
    
    @Published public var wallpapers: [WallpaperItem] = []
    @Published public var activeWallpaper: WallpaperItem?
    
    private init() {
        loadCatalog()
        bootstrapDefaultWallpapers()
        restoreActiveWallpaper()
    }
    
    public func loadCatalog() {
        guard FileManager.default.fileExists(atPath: catalogFileURL.path),
              let data = try? Data(contentsOf: catalogFileURL),
              let items = try? JSONDecoder().decode([WallpaperItem].self, from: data) else {
            return
        }
        self.wallpapers = items
    }
    
    public func saveCatalog() {
        if let data = try? JSONEncoder().encode(wallpapers) {
            try? data.write(to: catalogFileURL)
        }
    }
    
    public func bootstrapDefaultWallpapers() {
        let curated = CuratedCatalog.items
        var currentItems = self.wallpapers
        
        for item in curated {
            if !currentItems.contains(where: { $0.id == item.id || $0.videoUrl == item.videoUrl }) {
                currentItems.append(item)
            }
        }
        
        self.wallpapers = currentItems
        saveCatalog()
    }
    
    public func restoreActiveWallpaper() {
        if let savedId = AppSettings.shared.currentWallpaperId,
           let uuid = UUID(uuidString: savedId),
           let found = wallpapers.first(where: { $0.id == uuid && $0.isDownloaded }) {
            self.activeWallpaper = found
        } else if let firstDownloaded = wallpapers.first(where: { $0.isDownloaded }) {
            self.activeWallpaper = firstDownloaded
            AppSettings.shared.currentWallpaperId = firstDownloaded.id.uuidString
        }
    }
    
    public func setActiveWallpaper(_ item: WallpaperItem) {
        guard item.isDownloaded, let _ = item.localFileURL else { return }
        self.activeWallpaper = item
        AppSettings.shared.currentWallpaperId = item.id.uuidString
        NotificationCenter.default.post(name: .macWallspaceDidChangeWallpaper, object: item)
    }
    
    public func importCustomVideo(from sourceURL: URL, title: String? = nil) -> WallpaperItem? {
        let filename = sourceURL.lastPathComponent
        let targetFileName = "\(UUID().uuidString)_\(filename)"
        let targetURL = Self.wallpapersDirectory.appendingPathComponent(targetFileName)
        
        do {
            if FileManager.default.fileExists(atPath: targetURL.path) {
                try FileManager.default.removeItem(at: targetURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: targetURL)
            
            let fileSize = (try? FileManager.default.attributesOfItem(atPath: targetURL.path)[.size] as? Double) ?? 0.0
            let fileSizeMB = fileSize / (1024 * 1024)
            
            let item = WallpaperItem(
                id: UUID(),
                title: title ?? sourceURL.deletingPathExtension().lastPathComponent,
                category: "Custom",
                resolution: "Original",
                fileSizeMB: round(fileSizeMB * 10) / 10,
                videoUrl: targetURL.absoluteString,
                localFileName: targetFileName,
                isCustom: true,
                dateAdded: Date(),
                author: "Local Import"
            )
            
            wallpapers.insert(item, at: 0)
            saveCatalog()
            setActiveWallpaper(item)
            return item
        } catch {
            print("Failed to import custom video: \(error)")
            return nil
        }
    }
    
    public func deleteWallpaper(_ item: WallpaperItem) {
        if let localURL = item.localFileURL {
            try? FileManager.default.removeItem(at: localURL)
        }
        
        if item.isCustom {
            wallpapers.removeAll(where: { $0.id == item.id })
        } else {
            // For curated items, mark as not downloaded locally
            if let index = wallpapers.firstIndex(where: { $0.id == item.id }) {
                wallpapers[index].localFileName = nil
            }
        }
        saveCatalog()
        
        if activeWallpaper?.id == item.id {
            activeWallpaper = nil
            AppSettings.shared.currentWallpaperId = nil
            if let next = wallpapers.first(where: { $0.isDownloaded }) {
                setActiveWallpaper(next)
            }
        }
    }
}

public extension Notification.Name {
    static let macWallspaceDidChangeWallpaper = Notification.Name("macWallspaceDidChangeWallpaper")
    static let macWallspaceTogglePlayback = Notification.Name("macWallspaceTogglePlayback")
}
