import Foundation

public struct WallpaperItem: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var title: String
    public var category: String
    public var resolution: String
    public var fileSizeMB: Double
    public var thumbnailUrl: String?
    public var videoUrl: String
    public var localFileName: String?
    public var isCustom: Bool
    public var dateAdded: Date
    public var author: String?
    
    public init(
        id: UUID = UUID(),
        title: String,
        category: String,
        resolution: String = "1080p",
        fileSizeMB: Double = 0.0,
        thumbnailUrl: String? = nil,
        videoUrl: String,
        localFileName: String? = nil,
        isCustom: Bool = false,
        dateAdded: Date = Date(),
        author: String? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.resolution = resolution
        self.fileSizeMB = fileSizeMB
        self.thumbnailUrl = thumbnailUrl
        self.videoUrl = videoUrl
        self.localFileName = localFileName
        self.isCustom = isCustom
        self.dateAdded = dateAdded
        self.author = author
    }
    
    public var isDownloaded: Bool {
        guard let url = localFileURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    public var localFileURL: URL? {
        if let localFileName = localFileName {
            let appSupport = WallpaperStore.wallpapersDirectory
            let fullPath = appSupport.appendingPathComponent(localFileName)
            if FileManager.default.fileExists(atPath: fullPath.path) {
                return fullPath
            }
        }
        
        // If it's a file:// URL directly (e.g. custom imported)
        if let directUrl = URL(string: videoUrl), directUrl.isFileURL {
            return directUrl
        }
        
        // Fallback to filename derived from URL
        if let remoteUrl = URL(string: videoUrl) {
            let expectedName = "\(id.uuidString)_\(remoteUrl.lastPathComponent)"
            let candidate = WallpaperStore.wallpapersDirectory.appendingPathComponent(expectedName)
            if FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
        }
        
        return nil
    }
}
