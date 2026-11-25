import SwiftUI

public struct PlaylistView: View {
    @ObservedObject var playlistManager = PlaylistManager.shared
    @ObservedObject var store = WallpaperStore.shared
    
    @State private var selectedPlaylistId: UUID = PlaylistManager.defaultPlaylistId
    @State private var playlistScrollTarget: UUID?
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
            // Top Playlist Selector Bar with Scroll Arrows & Scrollbar
            HStack(spacing: 8) {
                ScrollViewReader { proxy in
                    HStack(spacing: 6) {
                        // Left Arrow Button
                        Button(action: {
                            let playlists = playlistManager.playlists
                            guard !playlists.isEmpty else { return }
                            let currentTarget = playlistScrollTarget ?? selectedPlaylistId
                            let currentIdx = playlists.firstIndex(where: { $0.id == currentTarget }) ?? 0
                            let prevIdx = max(0, currentIdx - 2)
                            let targetId = playlists[prevIdx].id
                            playlistScrollTarget = targetId
                            withAnimation(.easeInOut(duration: 0.25)) {
                                proxy.scrollTo(targetId, anchor: .leading)
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color(red: 0.18, green: 0.18, blue: 0.22))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Scroll playlists left")
                        
                        ScrollView(.horizontal, showsIndicators: true) {
                            HStack(spacing: 8) {
                                ForEach(playlistManager.playlists) { playlist in
                                    let isSelected = (playlist.id == selectedPlaylistId)
                                    let isActive = (playlist.id == playlistManager.activePlaylistId)
                                    
                                    Button(action: {
                                        selectedPlaylistId = playlist.id
                                        playlistScrollTarget = playlist.id
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            proxy.scrollTo(playlist.id, anchor: .center)
                                        }
                                    }) {
                                        HStack(spacing: 6) {
                                            if isActive {
                                                Circle()
                                                    .fill(Color.green)
                                                    .frame(width: 6, height: 6)
                                            }
                                            Text(playlist.name)
                                                .fontWeight(isSelected ? .bold : .medium)
                                                .lineLimit(1)
                                            Text("(\(playlist.itemIds.count))")
                                                .font(.caption)
                                                .foregroundColor(isSelected ? .green : .secondary)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .background(isSelected ? Color.green.opacity(0.2) : Color.white.opacity(0.06))
                                        .foregroundColor(isSelected ? .green : .white)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(isSelected ? Color.green.opacity(0.6) : Color.white.opacity(0.12), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .id(playlist.id)
                                }
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 2)
                        }
                        
                        // Right Arrow Button
                        Button(action: {
                            let playlists = playlistManager.playlists
                            guard !playlists.isEmpty else { return }
                            let currentTarget = playlistScrollTarget ?? selectedPlaylistId
                            let currentIdx = playlists.firstIndex(where: { $0.id == currentTarget }) ?? 0
                            let nextIdx = min(playlists.count - 1, currentIdx + 2)
                            let targetId = playlists[nextIdx].id
                            playlistScrollTarget = targetId
                            withAnimation(.easeInOut(duration: 0.25)) {
                                proxy.scrollTo(targetId, anchor: .trailing)
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color(red: 0.18, green: 0.18, blue: 0.22))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Scroll playlists right")
                    }
                }
                
                Divider()
                    .frame(height: 24)
                
                Button(action: {
                    newPlaylistName = ""
                    isCreatingNewPlaylist = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("New Playlist")
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                }
                .buttonStyle(SecondaryButtonStyle())
                .fixedSize()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(red: 0.05, green: 0.05, blue: 0.07))
            
            Divider()
            
            // New Playlist inline creation prompt
            if isCreatingNewPlaylist {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.stack.badge.plus")
                        .foregroundColor(.green)
                    TextField("Enter playlist name (e.g. Anime Favorites, Relaxing, 4K)", text: $newPlaylistName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Create") {
                        if !newPlaylistName.trimmingCharacters(in: .whitespaces).isEmpty {
                            let created = playlistManager.createPlaylist(name: newPlaylistName)
                            selectedPlaylistId = created.id
                        }
                        isCreatingNewPlaylist = false
                    }
                    .buttonStyle(ProminentButtonStyle(backgroundColor: .green))
                    .fixedSize()
                    
                    Button("Cancel") {
                        isCreatingNewPlaylist = false
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .fixedSize()
                }
                .padding(12)
                .background(Color(red: 0.08, green: 0.08, blue: 0.10))
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
                            .foregroundColor(.white)
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
                        .buttonStyle(ProminentButtonStyle(backgroundColor: .green))
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(playlistItems) { item in
                                playlistCard(item: item, playlist: playlist)
                            }
                        }
                        .padding(20)
                    }
                    .background(Color.black)
                }
            }
        }
        .background(Color.black)
        .sheet(isPresented: $showAddWallpapersSheet) {
            addWallpapersSheet
        }
    }
    
    // MARK: - Header Controls
    
    @ViewBuilder
    private func playlistHeaderControls(playlist: Playlist) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(playlist.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if playlist.id == playlistManager.activePlaylistId {
                        Text("ACTIVE PLAYLIST")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.25))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                }
                
                Text("\(playlist.itemIds.count) wallpapers • \(playlist.isShuffle ? "Shuffle On" : "Sequential")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
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
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                }
                .buttonStyle(ProminentButtonStyle(backgroundColor: Color.green))
                .fixedSize()
            }
            
            // Next / Prev Wallpaper in Playlist
            HStack(spacing: 2) {
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
            HStack(spacing: 4) {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.secondary)
                Picker("", selection: Binding(
                    get: { playlist.cycleIntervalMinutes },
                    set: { playlistManager.setCycleInterval(minutes: $0, for: playlist.id) }
                )) {
                    Text("Manual").tag(0)
                    Text("5 min").tag(5)
                    Text("15 min").tag(15)
                    Text("30 min").tag(30)
                    Text("1 Hour").tag(60)
                }
                .frame(width: 95)
            }
            
            // Shuffle Toggle
            Button(action: {
                playlistManager.setShuffle(!playlist.isShuffle, for: playlist.id)
            }) {
                Image(systemName: "shuffle")
                    .foregroundColor(playlist.isShuffle ? .green : .secondary)
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
        .background(Color(red: 0.08, green: 0.08, blue: 0.10))
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
                        .background(Circle().fill(Color.black.opacity(0.8)))
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
                    .foregroundColor(.white)
                Spacer()
                Button("Done") {
                    showAddWallpapersSheet = false
                }
                .buttonStyle(ProminentButtonStyle(backgroundColor: .green))
            }
            .padding()
            
            Divider()
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(store.wallpapers.filter { $0.isDownloaded }) { item in
                        let inPlaylist = currentPlaylist?.itemIds.contains(item.id) ?? false
                        
                        VStack(spacing: 8) {
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
                                .buttonStyle(ProminentButtonStyle(backgroundColor: .green))
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color.black)
        }
        .frame(minWidth: 600, minHeight: 450)
        .background(Color(red: 0.08, green: 0.08, blue: 0.10))
    }
}
