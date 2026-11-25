import SwiftUI
import AppKit

public struct CoverflowSwitcherView: View {
    @ObservedObject var store = WallpaperStore.shared
    @ObservedObject var playlistManager = PlaylistManager.shared
    
    @State private var selectedIndex: Int = 0
    @State private var appliedToast: Bool = false
    
    // Display items from active playlist if available, otherwise all downloaded
    private var availableWallpapers: [WallpaperItem] {
        if let playlist = playlistManager.activePlaylist, !playlist.itemIds.isEmpty {
            let items = playlist.itemIds.compactMap { id in
                store.wallpapers.first(where: { $0.id == id && $0.isDownloaded })
            }
            if !items.isEmpty { return items }
        }
        let downloaded = store.wallpapers.filter { $0.isDownloaded }
        return downloaded.isEmpty ? store.wallpapers : downloaded
    }
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Dark cinematic backdrop
            Color(red: 0.05, green: 0.06, blue: 0.09)
                .edgesIgnoringSafeArea(.all)
            
            // Soft atmospheric background glow from current wallpaper
            if !availableWallpapers.isEmpty && selectedIndex < availableWallpapers.count {
                let currentItem = availableWallpapers[selectedIndex]
                if let thumb = currentItem.thumbnailUrl, FileManager.default.fileExists(atPath: thumb),
                   let nsImage = NSImage(contentsOfFile: thumb) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .blur(radius: 60)
                        .opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                }
            }
            
            VStack(spacing: 20) {
                // Top Header Bar
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Image(systemName: "photo.stack.fill")
                                .font(.title3)
                                .foregroundColor(.accentColor)
                            Text("MaC Wallspace Switcher")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            if let playlist = playlistManager.activePlaylist {
                                Text("•  \(playlist.name)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text("Use ← and → arrow keys to browse, Enter (↵) to apply, Esc to close")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        CoverflowWindowController.shared.close()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 30)
                .padding(.top, 24)
                
                Spacer()
                
                // 3D Coverflow Stage
                if availableWallpapers.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No downloaded wallpapers yet")
                            .font(.headline)
                        Text("Download wallpapers from the Gallery or import your own.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 320)
                } else {
                    coverflowStage
                        .frame(height: 330)
                }
                
                Spacer()
                
                // Bottom Metadata & Controls
                if !availableWallpapers.isEmpty && selectedIndex < availableWallpapers.count {
                    let currentItem = availableWallpapers[selectedIndex]
                    let isCurrentActive = (store.activeWallpaper?.id == currentItem.id)
                    
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Text(currentItem.title)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(currentItem.resolution)
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.3))
                                .foregroundColor(.accentColor)
                                .cornerRadius(4)
                            
                            Text(currentItem.category)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.1))
                                .foregroundColor(.secondary)
                                .cornerRadius(4)
                        }
                        
                        HStack(spacing: 16) {
                            Button(action: {
                                navigatePrevious()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.left")
                                    Text("Previous (←)")
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            
                            Button(action: {
                                applyCurrent()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: isCurrentActive ? "checkmark.circle.fill" : "play.fill")
                                    Text(isCurrentActive ? "Applied to Desktop" : "Set as Wallpaper (Enter ↵)")
                                        .fontWeight(.bold)
                                }
                                .padding(.horizontal, 8)
                            }
                            .buttonStyle(ProminentButtonStyle(backgroundColor: isCurrentActive ? Color.green : Color.accentColor))
                            
                            Button(action: {
                                navigateNext()
                            }) {
                                HStack {
                                    Text("Next (→)")
                                    Image(systemName: "arrow.right")
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                        
                        // Counter index
                        Text("\(selectedIndex + 1) of \(availableWallpapers.count)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 24)
                }
            }
            
            // Applied Toast Overlay
            if appliedToast {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Wallpaper Applied to Desktop!")
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.85))
                    .foregroundColor(.white)
                    .cornerRadius(25)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.green.opacity(0.6), lineWidth: 1.5)
                    )
                    .shadow(radius: 10)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(minWidth: 920, minHeight: 560)
        .onAppear {
            syncInitialIndex()
            setupKeyboardMonitor()
        }
    }
    
    // MARK: - 3D Coverflow Stage
    
    @ViewBuilder
    private var coverflowStage: some View {
        let count = availableWallpapers.count
        
        ZStack {
            ForEach(0..<count, id: \.self) { idx in
                let offset = idx - selectedIndex
                
                // Only render items within 4 steps of center for max 60 FPS performance
                if abs(offset) <= 4 {
                    cardView(for: availableWallpapers[idx], offset: offset, index: idx)
                        .zIndex(Double(100 - abs(offset)))
                }
            }
        }
    }
    
    @ViewBuilder
    private func cardView(for item: WallpaperItem, offset: Int, index: Int) -> some View {
        let isCenter = (offset == 0)
        let cardWidth: CGFloat = 460
        let cardHeight: CGFloat = 260
        
        // Perspective layout calculations
        let xOffset: CGFloat = {
            if offset == 0 { return 0 }
            let sign: CGFloat = (offset > 0) ? 1.0 : -1.0
            return (sign * 230) + (CGFloat(offset) * 65)
        }()
        
        let angle: Double = {
            if offset == 0 { return 0 }
            return (offset > 0) ? -42 : 42
        }()
        
        let scale: CGFloat = isCenter ? 1.0 : max(0.65, 0.86 - (CGFloat(abs(offset)) * 0.05))
        let opacity: Double = isCenter ? 1.0 : max(0.4, 0.85 - (Double(abs(offset)) * 0.12))
        
        ZStack {
            // Card Content
            if let thumb = item.thumbnailUrl, FileManager.default.fileExists(atPath: thumb),
               let nsImage = NSImage(contentsOfFile: thumb) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: cardWidth, height: cardHeight)
                    .clipped()
            } else {
                ZStack {
                    Color(NSColor.controlBackgroundColor)
                    VStack(spacing: 8) {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.accentColor)
                        Text(item.title)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                }
                .frame(width: cardWidth, height: cardHeight)
            }
            
            // Frame overlay & subtle gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.6)]),
                startPoint: .center,
                endPoint: .bottom
            )
            
            // Active Desktop Badge
            if store.activeWallpaper?.id == item.id {
                VStack {
                    HStack {
                        Spacer()
                        Text("ACTIVE")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                            .padding(10)
                    }
                    Spacer()
                }
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isCenter ? Color.accentColor : Color.white.opacity(0.15), lineWidth: isCenter ? 2.5 : 1)
        )
        .shadow(color: isCenter ? Color.accentColor.opacity(0.35) : Color.black.opacity(0.4), radius: isCenter ? 18 : 8, x: 0, y: isCenter ? 8 : 4)
        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0))
        .scaleEffect(scale)
        .offset(x: xOffset)
        .opacity(opacity)
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: selectedIndex)
        .onTapGesture {
            if isCenter {
                applyCurrent()
            } else {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                    selectedIndex = index
                }
            }
        }
    }
    
    // MARK: - Actions & Keyboard
    
    private func syncInitialIndex() {
        if let current = store.activeWallpaper,
           let idx = availableWallpapers.firstIndex(where: { $0.id == current.id }) {
            self.selectedIndex = idx
        } else {
            self.selectedIndex = 0
        }
    }
    
    private func navigatePrevious() {
        guard !availableWallpapers.isEmpty else { return }
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            selectedIndex = max(0, selectedIndex - 1)
        }
    }
    
    private func navigateNext() {
        guard !availableWallpapers.isEmpty else { return }
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            selectedIndex = min(availableWallpapers.count - 1, selectedIndex + 1)
        }
    }
    
    private func applyCurrent() {
        guard !availableWallpapers.isEmpty, selectedIndex < availableWallpapers.count else { return }
        let item = availableWallpapers[selectedIndex]
        if !item.isDownloaded {
            WallpaperDownloader.shared.downloadWallpaper(item)
            return
        }
        
        DesktopWindowManager.shared.showAllWindows()
        store.setActiveWallpaper(item)
        
        withAnimation {
            appliedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation {
                appliedToast = false
            }
        }
    }
    
    private func setupKeyboardMonitor() {
        CoverflowWindowController.shared.onLeftArrow = { [self] in
            navigatePrevious()
        }
        CoverflowWindowController.shared.onRightArrow = { [self] in
            navigateNext()
        }
        CoverflowWindowController.shared.onReturn = { [self] in
            applyCurrent()
        }
        CoverflowWindowController.shared.onEscape = {
            CoverflowWindowController.shared.close()
        }
    }
}
