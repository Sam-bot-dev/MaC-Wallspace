import Foundation
import Combine

public final class WallpaperDownloader: NSObject, ObservableObject, URLSessionDownloadDelegate {
    public static let shared = WallpaperDownloader()
    
    @Published public var downloadProgress: [UUID: Double] = [:]
    @Published public var isDownloading: [UUID: Bool] = [:]
    
    private var activeTasks: [Int: (UUID, WallpaperItem)] = [:]
    private var session: URLSession!
    
    private override init() {
        super.init()
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }
    
    public func downloadWallpaper(_ item: WallpaperItem, autoApply: Bool = true) {
        guard let url = URL(string: item.videoUrl), !item.isDownloaded else { return }
        
        isDownloading[item.id] = true
        downloadProgress[item.id] = 0.05
        
        let task = session.downloadTask(with: url)
        activeTasks[task.taskIdentifier] = (item.id, item)
        task.resume()
    }
    
    // MARK: - URLSessionDownloadDelegate
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let (itemId, item) = activeTasks[downloadTask.taskIdentifier] else { return }
        
        let fileExtension = (URL(string: item.videoUrl)?.pathExtension.isEmpty == false)
            ? (URL(string: item.videoUrl)!.pathExtension)
            : "mp4"
            
        let targetFileName = "\(itemId.uuidString).\(fileExtension)"
        let destinationURL = WallpaperStore.wallpapersDirectory.appendingPathComponent(targetFileName)
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: location, to: destinationURL)
            
            // Update store
            DispatchQueue.main.async {
                if let index = WallpaperStore.shared.wallpapers.firstIndex(where: { $0.id == itemId }) {
                    WallpaperStore.shared.wallpapers[index].localFileName = targetFileName
                    WallpaperStore.shared.saveCatalog()
                    
                    let updatedItem = WallpaperStore.shared.wallpapers[index]
                    WallpaperStore.shared.setActiveWallpaper(updatedItem)
                }
                
                self.isDownloading[itemId] = false
                self.downloadProgress[itemId] = 1.0
                self.activeTasks.removeValue(forKey: downloadTask.taskIdentifier)
            }
        } catch {
            print("Failed to store downloaded wallpaper: \(error)")
            DispatchQueue.main.async {
                self.isDownloading[itemId] = false
                self.downloadProgress.removeValue(forKey: itemId)
                self.activeTasks.removeValue(forKey: downloadTask.taskIdentifier)
            }
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let (itemId, _) = activeTasks[downloadTask.taskIdentifier] else { return }
        
        if totalBytesExpectedToWrite > 0 {
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            DispatchQueue.main.async {
                self.downloadProgress[itemId] = progress
            }
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Download task failed: \(error.localizedDescription)")
            guard let (itemId, _) = activeTasks[task.taskIdentifier] else { return }
            DispatchQueue.main.async {
                self.isDownloading[itemId] = false
                self.downloadProgress.removeValue(forKey: itemId)
                self.activeTasks.removeValue(forKey: task.taskIdentifier)
            }
        }
    }
}
