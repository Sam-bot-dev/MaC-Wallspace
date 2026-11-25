import Foundation

public struct WallpaperItem: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public let title: String
    public let category: String
    public let resolution: String
    public let fileSizeMB: Double
    public let thumbnailUrl: String?
    public let videoUrl: String
    public var localFileName: String?
    public var isCustom: Bool
    public var dateAdded: Date
    public var author: String?
    
    public init(
        id: UUID = UUID(),
        title: String,
        category: String,
        resolution: String,
        fileSizeMB: Double,
        thumbnailUrl: String?,
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
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && !isDir.boolValue
    }
    
    public var localFileURL: URL? {
        if let localFileName = localFileName, !localFileName.isEmpty {
            let appSupport = WallpaperStore.wallpapersDirectory
            let fullPath = appSupport.appendingPathComponent(localFileName)
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: fullPath.path, isDirectory: &isDir), !isDir.boolValue {
                return fullPath
            }
        }
        
        // If it's a direct file path starting with /
        if videoUrl.hasPrefix("/") {
            let pathUrl = URL(fileURLWithPath: videoUrl)
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: pathUrl.path, isDirectory: &isDir), !isDir.boolValue {
                return pathUrl
            }
        }
        
        // If it's a file:// URL directly (e.g. custom imported)
        if let directUrl = URL(string: videoUrl), directUrl.isFileURL {
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: directUrl.path, isDirectory: &isDir), !isDir.boolValue {
                return directUrl
            }
        }
        
        // Fallback to filename derived from URL
        if let remoteUrl = URL(string: videoUrl), !remoteUrl.lastPathComponent.isEmpty {
            let expectedName = "\(id.uuidString)_\(remoteUrl.lastPathComponent)"
            let candidate = WallpaperStore.wallpapersDirectory.appendingPathComponent(expectedName)
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: candidate.path, isDirectory: &isDir), !isDir.boolValue {
                return candidate
            }
        }
        
        return nil
    }
}
