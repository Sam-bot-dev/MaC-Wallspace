import SwiftUI

public enum MainTab: String, CaseIterable, Identifiable {
    case gallery = "Gallery"
    case library = "My Library"
    case playlists = "Playlists"
    case custom = "Import Media"
    case displays = "Displays"
    case performance = "Performance"
    case settings = "Settings"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .gallery: return "sparkles.rectangle.stack"
        case .library: return "square.grid.2x2"
        case .playlists: return "rectangle.stack.badge.play"
        case .custom: return "plus.circle"
        case .displays: return "display"
        case .performance: return "bolt.batteryblock"
        case .settings: return "gearshape"
        }
    }
}

public struct MainGalleryView: View {
    @State private var selectedTab: MainTab = .gallery
    @ObservedObject var store = WallpaperStore.shared
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var windowManager = DesktopWindowManager.shared
    
    private let columns = [
        GridItem(.adaptive(minimum: 220, maximum: 280), spacing: 16)
    ]
    
    public var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.accentColor)
                    Text("MaC Wallspace")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 12)
                
                Divider()
                    .padding(.bottom, 8)
                
                ForEach(MainTab.allCases) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: tab.icon)
                                .frame(width: 20)
                            Text(tab.rawValue)
                                .fontWeight(selectedTab == tab ? .semibold : .regular)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedTab == tab ? Color.accentColor.opacity(0.15) : Color.clear)
                        .foregroundColor(selectedTab == tab ? .accentColor : .primary)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 8)
                }
                
                Spacer()
                
                // Bottom Status Pill
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Circle()
                            .fill(windowManager.isMacDesktopExposed ? Color.gray : (settings.isPausedByUser ? Color.orange : Color.green))
                            .frame(width: 8, height: 8)
                        Text(windowManager.isMacDesktopExposed ? "macOS Desktop" : (settings.isPausedByUser ? "Paused" : "Active (60 FPS)"))
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
                    if !windowManager.isMacDesktopExposed, let active = store.activeWallpaper {
                        Text(active.title)
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(10)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .padding(12)
            }
            .frame(width: 200)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Content Area
            VStack(spacing: 0) {
                contentHeader
                Divider()
                contentBody
            }
            .background(Color(NSColor.underPageBackgroundColor))
        }
        .frame(minWidth: 840, minHeight: 540)
    }
    
    @ViewBuilder
    private var contentHeader: some View {
        HStack(spacing: 10) {
            Text(selectedTab.rawValue)
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            // Reset to Default Wallpaper Button
            Button(action: {
                DesktopWindowManager.shared.resetToDefaultWallpaper()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                    Text("Default Wallpaper")
                }
            }
            .buttonStyle(SecondaryButtonStyle())
            .help("Revert immediately to the built-in default wallpaper")
            
            // Toggle macOS Native Desktop Picture Button
            Button(action: {
                DesktopWindowManager.shared.toggleMacDesktop()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: windowManager.isMacDesktopExposed ? "sparkles" : "desktopcomputer")
                    Text(windowManager.isMacDesktopExposed ? "Restore Wallspace" : "macOS Desktop")
                }
            }
            .buttonStyle(SecondaryButtonStyle())
            .help(windowManager.isMacDesktopExposed ? "Show MaC Wallspace active wallpaper" : "Hide live wallpaper and show your default macOS desktop picture")
            
            // Quick playback toggle
            Button(action: {
                DesktopWindowManager.shared.togglePlayback()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: settings.isPausedByUser ? "play.fill" : "pause.fill")
                    Text(settings.isPausedByUser ? "Resume" : "Pause")
                }
            }
            .buttonStyle(SecondaryButtonStyle())
            
            Button(action: {
                DesktopWindowManager.shared.cycleNextWallpaper()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "forward.fill")
                    Text("Next")
                }
            }
            .buttonStyle(SecondaryButtonStyle())
            
            // 3D Coverflow Switcher Button
            Button(action: {
                CoverflowWindowController.shared.show()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "photo.stack.fill")
                    Text("3D Switcher")
                }
            }
            .buttonStyle(ProminentButtonStyle())
            .help("Launch 3D Coverflow Wallpaper Switcher (Arrow keys to browse, Enter to apply)")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
    
    @ViewBuilder
    private var contentBody: some View {
        switch selectedTab {
        case .gallery:
            gallerySection
        case .library:
            librarySection
        case .playlists:
            PlaylistView()
        case .custom:
            CustomImportView()
                .padding(20)
        case .displays:
            DisplaysConfigView()
        case .performance:
            PerformanceSettingsView()
        case .settings:
            SettingsView()
        }
    }
    
    @ViewBuilder
    private var gallerySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category Filter Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(availableCategories, id: \.self) { cat in
                        Button(action: {
                            settings.selectedCategory = cat
                        }) {
                            Text(cat)
                                .font(.caption)
                                .fontWeight(settings.selectedCategory == cat ? .bold : .medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(settings.selectedCategory == cat ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                                .foregroundColor(settings.selectedCategory == cat ? .white : .primary)
                                .cornerRadius(16)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 10)
            
            // Wallpapers Grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(filteredWallpapers) { item in
                        WallpaperCardView(item: item)
                    }
                }
                .padding(20)
            }
        }
    }
    
    @ViewBuilder
    private var librarySection: some View {
        let downloadedItems = store.wallpapers.filter { $0.isDownloaded }
        
        if downloadedItems.isEmpty {
            VStack(spacing: 12) {
                Spacer()
                Image(systemName: "photo.stack")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text("No Wallpapers in Library Yet")
                    .font(.headline)
                Text("Explore the Online Gallery or Import your own videos and photos.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(downloadedItems) { item in
                        WallpaperCardView(item: item)
                    }
                }
                .padding(20)
            }
        }
    }
    
    private var availableCategories: [String] {
        var base = ["All", "Omarchy", "Animated (Live)", "Anime", "Outrun", "Nord", "Gruvbox", "Nature", "Minimal", "Photos", "Custom"]
        let actual = Set(store.wallpapers.map { $0.category })
        for c in actual where !base.contains(c) {
            base.append(c)
        }
        return base
    }
    
    private var filteredWallpapers: [WallpaperItem] {
        if settings.selectedCategory == "All" {
            return store.wallpapers
        } else if settings.selectedCategory == "Omarchy" {
            return store.wallpapers.filter { $0.author?.contains("Omarchy") == true || $0.localFileName?.contains("omarchy") == true }
        } else {
            return store.wallpapers.filter { $0.category == settings.selectedCategory }
        }
    }
}
