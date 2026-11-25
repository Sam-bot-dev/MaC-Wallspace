import SwiftUI

public struct PlaylistView: View {
    @ObservedObject var playlistManager = PlaylistManager.shared
    @ObservedObject var store = WallpaperStore.shared
    
    @State private var selectedPlaylistId: UUID = PlaylistManager.defaultPlaylistId
    @State private var isCreatingNewPlaylist: Bool = false
    @State private var newPlaylistName: String = ""
    @State private var showAddWallpapersSheet: Bool = false
    
    private let columns = [
        GridItem(.adaptive(minimum: 220, maximum: 280), spacing: 16)
    ]
    
    private var currentPlaylist: Playlist? {
        playlistManager.playlists.first(where: { $0.id == selectedPlaylistId })
            ?? playlistManager.playlists.first
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top Playlist Selector Bar
            HStack(spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(playlistManager.playlists) { playlist in
                            let isSelected = (playlist.id == selectedPlaylistId)
                            let isActive = (playlist.id == playlistManager.activePlaylistId)
                            
                            Button(action: {
                                selectedPlaylistId = playlist.id
                            }) {
                                HStack(spacing: 6) {
                                    if isActive {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 6, height: 6)
                                    }
                                    Text(playlist.name)
                                        .fontWeight(isSelected ? .bold : .regular)
                                    Text("(\(playlist.itemIds.count))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(isSelected ? Color.accentColor.opacity(0.2) : Color(NSColor.controlBackgroundColor))
                                .foregroundColor(isSelected ? .accentColor : .primary)
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 2)
                }
                
                Spacer()
                
                Button(action: {
                    newPlaylistName = ""
                    isCreatingNewPlaylist = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("New Playlist")
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // New Playlist inline creation prompt
            if isCreatingNewPlaylist {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.stack.badge.plus")
                        .foregroundColor(.accentColor)
                    TextField("Enter playlist name (e.g. Anime Favorites, Relaxing, 4K)", text: $newPlaylistName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Create") {
                        if !newPlaylistName.trimmingCharacters(in: .whitespaces).isEmpty {
                            let created = playlistManager.createPlaylist(name: newPlaylistName)
                            selectedPlaylistId = created.id
                        }
                        isCreatingNewPlaylist = false
                    }
                    .buttonStyle(ProminentButtonStyle())
                    
                    Button("Cancel") {
                        isCreatingNewPlaylist = false
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                Divider()
            }
            
            // Playlist Header Controls
            if let playlist = currentPlaylist {
                playlistHeaderControls(playlist: playlist)
                Divider()
                
                // Wallpaper Grid in Playlist
                let playlistItems = playlist.itemIds.compactMap { id in
                    store.wallpapers.first(where: { $0.id == id })
                }
                
                if playlistItems.isEmpty {
                    VStack(spacing: 14) {
                        Spacer()
                        Image(systemName: "play.square.stack")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary.opacity(0.6))
                        Text("This playlist is empty")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Whenever you add or import a live wallpaper, it is automatically saved here.\nYou can also add existing wallpapers below:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            showAddWallpapersSheet = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Wallpapers to Playlist")
                            }
                        }
                        .buttonStyle(ProminentButtonStyle())
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(playlistItems) { item in
                                playlistCard(item: item, playlist: playlist)
                            }
                        }
                        .padding(20)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddWallpapersSheet) {
            addWallpapersSheet
        }
    }
    
    // MARK: - Header Controls
    
    @ViewBuilder
    private func playlistHeaderControls(playlist: Playlist) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(playlist.name)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    if playlist.id == playlistManager.activePlaylistId {
                        Text("ACTIVE PLAYLIST")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                }
                
                Text("\(playlist.itemIds.count) wallpapers • \(playlist.isShuffle ? "Shuffle On" : "Sequential")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Activate Playlist Button
            if playlist.id != playlistManager.activePlaylistId {
                Button(action: {
                    playlistManager.activePlaylistId = playlist.id
                    playlistManager.cycleNext()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                        Text("Set Active & Play")
                    }
                }
                .buttonStyle(ProminentButtonStyle())
            }
            
            // Next / Prev Wallpaper in Playlist
            HStack(spacing: 4) {
                Button(action: {
                    playlistManager.activePlaylistId = playlist.id
                    playlistManager.cyclePrevious()
                }) {
                    Image(systemName: "backward.fill")
                }
                .buttonStyle(SecondaryButtonStyle())
                .help("Previous Wallpaper in Playlist")
                
                Button(action: {
                    playlistManager.activePlaylistId = playlist.id
                    playlistManager.cycleNext()
                }) {
                    Image(systemName: "forward.fill")
                }
                .buttonStyle(SecondaryButtonStyle())
                .help("Next Wallpaper in Playlist")
            }
            
            // Auto Cycle Picker
            HStack(spacing: 6) {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.secondary)
                Picker("", selection: Binding(
                    get: { playlist.cycleIntervalMinutes },
                    set: { playlistManager.setCycleInterval(minutes: $0, for: playlist.id) }
                )) {
                    Text("Manual Only").tag(0)
                    Text("Every 5 min").tag(5)
                    Text("Every 15 min").tag(15)
                    Text("Every 30 min").tag(30)
                    Text("Every 1 Hour").tag(60)
                }
                .frame(width: 130)
            }
            
            // Shuffle Toggle
            Button(action: {
                playlistManager.setShuffle(!playlist.isShuffle, for: playlist.id)
            }) {
                Image(systemName: "shuffle")
                    .foregroundColor(playlist.isShuffle ? .accentColor : .secondary)
            }
            .buttonStyle(SecondaryButtonStyle())
            .help(playlist.isShuffle ? "Shuffle is ON" : "Shuffle is OFF")
            
            // Add Wallpapers Button
            Button(action: {
                showAddWallpapersSheet = true
            }) {
                Image(systemName: "plus.circle")
            }
            .buttonStyle(SecondaryButtonStyle())
            .help("Add Wallpapers to this Playlist")
            
            // Delete Playlist (if not default)
            if !playlist.isDefault {
                Button(action: {
                    playlistManager.deletePlaylist(id: playlist.id)
                    selectedPlaylistId = PlaylistManager.defaultPlaylistId
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(SecondaryButtonStyle())
                .help("Delete Playlist")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }
    
    // MARK: - Card Inside Playlist
    
    @ViewBuilder
    private func playlistCard(item: WallpaperItem, playlist: Playlist) -> some View {
        let isCurrent = (store.activeWallpaper?.id == item.id)
        
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                WallpaperCardView(wallpaper: item)
                
                // Remove from playlist button (x)
                Button(action: {
                    playlistManager.removeItem(item.id, from: playlist.id)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .background(Circle().fill(Color.black.opacity(0.6)))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(8)
                .help("Remove from this playlist")
            }
            
            if isCurrent {
                HStack {
                    Circle().fill(Color.green).frame(width: 6, height: 6)
                    Text("CURRENT DESKTOP")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.green)
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Add Wallpapers Sheet
    
    @ViewBuilder
    private var addWallpapersSheet: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Add Wallpapers to '\(currentPlaylist?.name ?? "Playlist")'")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    showAddWallpapersSheet = false
                }
                .buttonStyle(ProminentButtonStyle())
            }
            .padding()
            
            Divider()
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(store.wallpapers.filter { $0.isDownloaded }) { item in
                        let inPlaylist = currentPlaylist?.itemIds.contains(item.id) ?? false
                        
                        VStack {
                            WallpaperCardView(wallpaper: item)
                            
                            if inPlaylist {
                                Button(action: {
                                    if let id = currentPlaylist?.id {
                                        playlistManager.toggleItem(item.id, in: id)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("In Playlist")
                                    }
                                }
                                .buttonStyle(SecondaryButtonStyle())
                            } else {
                                Button(action: {
                                    if let id = currentPlaylist?.id {
                                        playlistManager.toggleItem(item.id, in: id)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle")
                                        Text("Add to Playlist")
                                    }
                                }
                                .buttonStyle(ProminentButtonStyle())
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 600, minHeight: 450)
    }
}
