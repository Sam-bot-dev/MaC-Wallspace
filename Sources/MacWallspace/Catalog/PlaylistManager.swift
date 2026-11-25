import Foundation
import Combine

public final class PlaylistManager: ObservableObject {
    public static let shared = PlaylistManager()
    
    public static let defaultPlaylistId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    
    private var fileURL: URL {
        return WallpaperStore.appSupportDirectory.appendingPathComponent("playlists.json")
    }
    
    @Published public var playlists: [Playlist] = []
    @Published public var activePlaylistId: UUID? {
        didSet {
            UserDefaults.standard.set(activePlaylistId?.uuidString, forKey: "mac_wallspace_active_playlist_id")
            setupAutoCycleTimer()
        }
    }
    
    private var cycleTimer: Timer?
    
    private init() {
        loadPlaylists()
        ensureDefaultPlaylistExists()
        restoreActivePlaylist()
    }
    
    public var activePlaylist: Playlist? {
        guard let id = activePlaylistId else { return nil }
        return playlists.first(where: { $0.id == id })
    }
    
    // MARK: - Persistence
    
    public func loadPlaylists() {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let items = try? JSONDecoder().decode([Playlist].self, from: data) else {
            return
        }
        self.playlists = items
    }
    
    public func savePlaylists() {
        if let data = try? JSONEncoder().encode(playlists) {
            try? data.write(to: fileURL)
        }
    }
    
    public func ensureDefaultPlaylistExists() {
        if !playlists.contains(where: { $0.id == Self.defaultPlaylistId }) {
            // Populate with initially downloaded wallpapers
            let downloadedIds = WallpaperStore.shared.wallpapers
                .filter { $0.isDownloaded }
                .map { $0.id }
            
            let defaultPlaylist = Playlist(
                id: Self.defaultPlaylistId,
                name: "My Live Wallpapers",
                itemIds: downloadedIds,
                isDefault: true,
                cycleIntervalMinutes: 0,
                isShuffle: false
            )
            playlists.insert(defaultPlaylist, at: 0)
            savePlaylists()
        }
    }
    
    public func restoreActivePlaylist() {
        if let savedId = UserDefaults.standard.string(forKey: "mac_wallspace_active_playlist_id"),
           let uuid = UUID(uuidString: savedId),
           playlists.contains(where: { $0.id == uuid }) {
            self.activePlaylistId = uuid
        } else {
            self.activePlaylistId = Self.defaultPlaylistId
        }
        setupAutoCycleTimer()
    }
    
    // MARK: - Playlist Operations
    
    public func createPlaylist(name: String) -> Playlist {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmed.isEmpty ? "New Playlist" : trimmed
        let newPlaylist = Playlist(
            id: UUID(),
            name: finalName,
            itemIds: [],
            isDefault: false
        )
        playlists.append(newPlaylist)
        savePlaylists()
        return newPlaylist
    }
    
    public func deletePlaylist(id: UUID) {
        // Cannot delete default playlist
        guard id != Self.defaultPlaylistId else { return }
        playlists.removeAll(where: { $0.id == id })
        if activePlaylistId == id {
            activePlaylistId = Self.defaultPlaylistId
        }
        savePlaylists()
    }
    
    public func renamePlaylist(id: UUID, newName: String) {
        guard let index = playlists.firstIndex(where: { $0.id == id }) else { return }
        playlists[index].name = newName
        savePlaylists()
    }
    
    public func addItem(_ itemId: UUID, to playlistId: UUID) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistId }) else { return }
        if !playlists[index].itemIds.contains(itemId) {
            playlists[index].itemIds.append(itemId)
            savePlaylists()
        }
    }
    
    public func removeItem(_ itemId: UUID, from playlistId: UUID) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistId }) else { return }
        playlists[index].itemIds.removeAll(where: { $0 == itemId })
        savePlaylists()
    }
    
    public func toggleItem(_ itemId: UUID, in playlistId: UUID) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistId }) else { return }
        if playlists[index].itemIds.contains(itemId) {
            playlists[index].itemIds.removeAll(where: { $0 == itemId })
        } else {
            playlists[index].itemIds.append(itemId)
        }
        savePlaylists()
    }
    
    public func setCycleInterval(minutes: Int, for playlistId: UUID) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistId }) else { return }
        playlists[index].cycleIntervalMinutes = minutes
        savePlaylists()
        if activePlaylistId == playlistId {
            setupAutoCycleTimer()
        }
    }
    
    public func setShuffle(_ shuffle: Bool, for playlistId: UUID) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistId }) else { return }
        playlists[index].isShuffle = shuffle
        savePlaylists()
    }
    
    /// Automatically called when user imports or adds any custom live wallpaper
    public func registerNewlyAddedWallpaper(id: UUID) {
        // Add to default "My Live Wallpapers" playlist
        addItem(id, to: Self.defaultPlaylistId)
        
        // Also add to active playlist if different
        if let activeId = activePlaylistId, activeId != Self.defaultPlaylistId {
            addItem(id, to: activeId)
        }
    }
    
    // MARK: - Cycling Engine
    
    public func cycleNext() {
        guard let playlist = activePlaylist, !playlist.itemIds.isEmpty else {
            // Fallback to cycling all downloaded wallpapers
            cycleAllDownloadedNext()
            return
        }
        
        // Map itemIds to downloaded items
        let store = WallpaperStore.shared
        let availableItems = playlist.itemIds.compactMap { id in
            store.wallpapers.first(where: { $0.id == id && $0.isDownloaded })
        }
        
        guard !availableItems.isEmpty else {
            cycleAllDownloadedNext()
            return
        }
        
        if playlist.isShuffle && availableItems.count > 1 {
            let currentId = store.activeWallpaper?.id
            let candidates = availableItems.filter { $0.id != currentId }
            if let randomItem = candidates.randomElement() {
                store.setActiveWallpaper(randomItem)
                return
            }
        }
        
        // Sequential cycle
        if let current = store.activeWallpaper,
           let currentIndex = availableItems.firstIndex(where: { $0.id == current.id }) {
            let nextIndex = (currentIndex + 1) % availableItems.count
            store.setActiveWallpaper(availableItems[nextIndex])
        } else if let first = availableItems.first {
            store.setActiveWallpaper(first)
        }
    }
    
    public func cyclePrevious() {
        guard let playlist = activePlaylist, !playlist.itemIds.isEmpty else {
            cycleAllDownloadedPrevious()
            return
        }
        
        let store = WallpaperStore.shared
        let availableItems = playlist.itemIds.compactMap { id in
            store.wallpapers.first(where: { $0.id == id && $0.isDownloaded })
        }
        
        guard !availableItems.isEmpty else {
            cycleAllDownloadedPrevious()
            return
        }
        
        if let current = store.activeWallpaper,
           let currentIndex = availableItems.firstIndex(where: { $0.id == current.id }) {
            let prevIndex = (currentIndex - 1 + availableItems.count) % availableItems.count
            store.setActiveWallpaper(availableItems[prevIndex])
        } else if let last = availableItems.last {
            store.setActiveWallpaper(last)
        }
    }
    
    private func cycleAllDownloadedNext() {
        let downloaded = WallpaperStore.shared.wallpapers.filter { $0.isDownloaded }
        guard downloaded.count > 1 else { return }
        if let current = WallpaperStore.shared.activeWallpaper,
           let idx = downloaded.firstIndex(where: { $0.id == current.id }) {
            let nextIdx = (idx + 1) % downloaded.count
            WallpaperStore.shared.setActiveWallpaper(downloaded[nextIdx])
        } else if let first = downloaded.first {
            WallpaperStore.shared.setActiveWallpaper(first)
        }
    }
    
    private func cycleAllDownloadedPrevious() {
        let downloaded = WallpaperStore.shared.wallpapers.filter { $0.isDownloaded }
        guard downloaded.count > 1 else { return }
        if let current = WallpaperStore.shared.activeWallpaper,
           let idx = downloaded.firstIndex(where: { $0.id == current.id }) {
            let prevIdx = (idx - 1 + downloaded.count) % downloaded.count
            WallpaperStore.shared.setActiveWallpaper(downloaded[prevIdx])
        } else if let last = downloaded.last {
            WallpaperStore.shared.setActiveWallpaper(last)
        }
    }
    
    // MARK: - Auto-Cycle Timer
    
    public func setupAutoCycleTimer() {
        cycleTimer?.invalidate()
        cycleTimer = nil
        
        guard let playlist = activePlaylist, playlist.cycleIntervalMinutes > 0 else {
            return
        }
        
        let interval = Double(playlist.cycleIntervalMinutes * 60)
        cycleTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            // Do not cycle if paused by user or during system sleep / battery pause
            if AppSettings.shared.isPausedByUser { return }
            if AppSettings.shared.pauseOnBattery && PowerGovernor.shared.isOnBattery { return }
            self.cycleNext()
        }
    }
}
