import Foundation

public struct CuratedCatalog {
    public static let categories = ["All", "Photos", "Anime & Cozy", "Nature", "Aerial", "Sci-Fi", "Minimalist", "Custom"]
    
    public static let items: [WallpaperItem] = [
        WallpaperItem(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            title: "Cosmic Nebula Flow",
            category: "Sci-Fi",
            resolution: "1080p (Optimized)",
            fileSizeMB: 8.4,
            thumbnailUrl: "https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?w=600&q=80",
            videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
            author: "Cosmos Motion Lab"
        ),
        WallpaperItem(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            title: "Misty Alpine Forest",
            category: "Nature",
            resolution: "1080p (Low Power)",
            fileSizeMB: 6.2,
            thumbnailUrl: "https://images.unsplash.com/photo-1448375240586-882707db888b?w=600&q=80",
            videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
            author: "Earth Scenic"
        ),
        WallpaperItem(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            title: "Tokyo Cyberpunk Rain",
            category: "Sci-Fi",
            resolution: "1080p (Vibrant)",
            fileSizeMB: 12.1,
            thumbnailUrl: "https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=600&q=80",
            videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
            author: "NeoShinjuku"
        ),
        WallpaperItem(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            title: "Earth Orbit Horizon",
            category: "Aerial",
            resolution: "4K (H.264 Accelerated)",
            fileSizeMB: 14.8,
            thumbnailUrl: "https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=600&q=80",
            videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4",
            author: "Orbital Spaceflight"
        ),
        WallpaperItem(
            id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
            title: "Lo-Fi Rainy Window",
            category: "Anime & Cozy",
            resolution: "1080p (Ultra Quiet)",
            fileSizeMB: 5.7,
            thumbnailUrl: "https://images.unsplash.com/photo-1515694346937-94d85e41e6f0?w=600&q=80",
            videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4",
            author: "Chilled Beats"
        ),
        WallpaperItem(
            id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
            title: "Minimalist Gradient Waves",
            category: "Minimalist",
            resolution: "1080p (Fluid)",
            fileSizeMB: 4.1,
            thumbnailUrl: "https://images.unsplash.com/photo-1550684848-fac1c5b4e853?w=600&q=80",
            videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackSeeTheWorld.mp4",
            author: "Aesthetic Studio"
        )
    ]
}
