import Foundation

public struct CuratedCatalog {
    public static let categories = [
        "All",
        "Omarchy",
        "Animated (Live)",
        "Anime",
        "Outrun",
        "Nord",
        "Gruvbox",
        "Nature",
        "Minimal",
        "Photos",
        "Custom"
    ]
    
    private static let rawBase = "https://raw.githubusercontent.com/dharmx/walls/main"
    
    public static let items: [WallpaperItem] = [
        // MARK: - Omarchy Live / Animated Video Loops (60 FPS & High Quality)
        WallpaperItem(
            id: UUID(uuidString: "a1111111-0000-0000-0000-000000000001")!,
            title: "Anime Sky & Train Station",
            category: "Anime",
            resolution: "1080p (60 FPS)",
            fileSizeMB: 41.6,
            thumbnailUrl: "preview_lofi_headphones.jpg",
            videoUrl: "\(rawBase)/animated/anime-school-girl-watching-the-sky-at-the-train-station-moewalls-com.mp4",
            author: "Omarchy (dharmx/walls)"
        ),
        WallpaperItem(
            id: UUID(uuidString: "a1111111-0000-0000-0000-000000000002")!,
            title: "Berserk: Manga Eclipse Live",
            category: "Anime",
            resolution: "1080p (60 FPS)",
            fileSizeMB: 24.1,
            thumbnailUrl: "preview_berserk.jpg",
            videoUrl: "\(rawBase)/animated/berserk-manga-eclipse-moewalls-com.mp4",
            author: "Omarchy (dharmx/walls)"
        ),
        WallpaperItem(
            id: UUID(uuidString: "a1111111-0000-0000-0000-000000000003")!,
            title: "Bocchi The Rock: Train Journey",
            category: "Anime",
            resolution: "1080p (60 FPS)",
            fileSizeMB: 37.4,
            thumbnailUrl: "preview_bocchi.jpg",
            videoUrl: "\(rawBase)/animated/kessoku-band-in-the-train-bocchi-the-rock-moewalls-com.mp4",
            author: "Omarchy (dharmx/walls)"
        ),
        WallpaperItem(
            id: UUID(uuidString: "a1111111-0000-0000-0000-000000000004")!,
            title: "Studio Ghibli: Totoro Starry Night",
            category: "Anime",
            resolution: "1080p (60 FPS)",
            fileSizeMB: 37.9,
            thumbnailUrl: "preview_totoro.jpg",
            videoUrl: "\(rawBase)/animated/totoro-starry-night-sky-moewalls-com.mp4",
            author: "Omarchy (dharmx/walls)"
        ),
        WallpaperItem(
            id: UUID(uuidString: "a1111111-0000-0000-0000-000000000005")!,
            title: "Totoro in the Rain",
            category: "Anime",
            resolution: "1080p (60 FPS)",
            fileSizeMB: 27.2,
            thumbnailUrl: "preview_totoro.jpg",
            videoUrl: "\(rawBase)/animated/totoro-in-the-rain-moewalls-com.mp4",
            author: "Omarchy (dharmx/walls)"
        ),
        WallpaperItem(
            id: UUID(uuidString: "a1111111-0000-0000-0000-000000000006")!,
            title: "Sailor Moon: Retro Rainy Window",
            category: "Anime",
            resolution: "GIF (0% CPU)",
            fileSizeMB: 1.7,
            thumbnailUrl: "preview_sailor_moon.jpg",
            videoUrl: "\(rawBase)/animated/sailor-moon-window.gif",
            author: "Omarchy (dharmx/walls)"
        ),
        WallpaperItem(
            id: UUID(uuidString: "a1111111-0000-0000-0000-000000000007")!,
            title: "Yor Forger: Assassin Stance",
            category: "Anime",
            resolution: "1080p (60 FPS)",
            fileSizeMB: 47.8,
            thumbnailUrl: "preview_yor_forger.jpg",
            videoUrl: "\(rawBase)/animated/yor-forger-bloody-needles-spy-x-family-moewalls-com.mp4",
            author: "Omarchy (dharmx/walls)"
        ),
        WallpaperItem(
            id: UUID(uuidString: "a1111111-0000-0000-0000-000000000008")!,
            title: "Zero Two: Darling Drift",
            category: "Anime",
            resolution: "1080p (60 FPS)",
            fileSizeMB: 30.6,
            thumbnailUrl: "preview_zero_two.jpg",
            videoUrl: "\(rawBase)/animated/zero-two-bouncing-moewalls-com.mp4",
            author: "Omarchy (dharmx/walls)"
        ),
        WallpaperItem(
            id: UUID(uuidString: "a1111111-0000-0000-0000-000000000009")!,
            title: "Star Wars: Ghibli Style",
            category: "Anime",
            resolution: "1080p (60 FPS)",
            fileSizeMB: 33.0,
            thumbnailUrl: "preview_celestial_veil.jpg",
            videoUrl: "\(rawBase)/animated/star-wars-ghibli-style-moewalls-com.mp4",
            author: "Omarchy (dharmx/walls)"
        ),
        WallpaperItem(
            id: UUID(uuidString: "a1111111-0000-0000-0000-000000000010")!,
            title: "Pixel Cozy Fireplace",
            category: "Minimal",
            resolution: "GIF (0% CPU)",
            fileSizeMB: 0.6,
            thumbnailUrl: "preview_outrun_sunset.jpg",
            videoUrl: "\(rawBase)/animated/fireplace.gif",
            author: "Omarchy (dharmx/walls)"
        ),
        WallpaperItem(
            id: UUID(uuidString: "a1111111-0000-0000-0000-000000000011")!,
            title: "Retro Pixel Moon Orbit",
            category: "Minimal",
            resolution: "GIF (0% CPU)",
            fileSizeMB: 2.7,
            thumbnailUrl: "preview_waves_monochrome.jpg",
            videoUrl: "\(rawBase)/animated/moon.gif",
            author: "Omarchy (dharmx/walls)"
        ),
        WallpaperItem(
            id: UUID(uuidString: "a1111111-0000-0000-0000-000000000012")!,
            title: "Lofi Rain Cityscape",
            category: "Anime",
            resolution: "GIF (0% CPU)",
            fileSizeMB: 2.4,
            thumbnailUrl: "preview_sakura_blade.jpg",
            videoUrl: "\(rawBase)/animated/city.gif",
            author: "Omarchy (dharmx/walls)"
        ),
        WallpaperItem(
            id: UUID(uuidString: "a1111111-0000-0000-0000-000000000013")!,
            title: "Breathe: Calming Minimal Loop",
            category: "Minimal",
            resolution: "1080p (Smooth)",
            fileSizeMB: 1.1,
            thumbnailUrl: "preview_celestial_veil.jpg",
            videoUrl: "\(rawBase)/animated/breathe.mp4",
            author: "Omarchy (dharmx/walls)"
        ),

        // MARK: - Omarchy Outrun & Synthwave Retinas
        WallpaperItem(
            id: UUID(uuidString: "b1111111-0000-0000-0000-000000000001")!,
            title: "Outrun Sunset Skyline",
            category: "Outrun",
            resolution: "Retina 4K (0% CPU)",
            fileSizeMB: 2.0,
            thumbnailUrl: "preview_outrun_sunset.jpg",
            videoUrl: "\(rawBase)/outrun/a_city_skyline_with_a_sunset_in_the_background.png",
            author: "Omarchy (dharmx/walls)"
        ),
        WallpaperItem(
            id: UUID(uuidString: "b1111111-0000-0000-0000-000000000002")!,
            title: "Neon Sports Car Cyberpunk",
            category: "Outrun",
            resolution: "Retina 4K (0% CPU)",
            fileSizeMB: 9.3,
            thumbnailUrl: "preview_outrun_sunset.jpg",
            videoUrl: "\(rawBase)/outrun/a_sports_car_with_neon_lights.png",
            author: "Omarchy (dharmx/walls)"
        ),
        WallpaperItem(
            id: UUID(uuidString: "b1111111-0000-0000-0000-000000000003")!,
            title: "Purple Glow Gas Station",
            category: "Outrun",
            resolution: "Retina HD (0% CPU)",
            fileSizeMB: 0.8,
            thumbnailUrl: "preview_outrun_sunset.jpg",
            videoUrl: "\(rawBase)/outrun/a_gas_station_with_purple_lights.jpg",
            author: "Omarchy (dharmx/walls)"
        ),
        WallpaperItem(
            id: UUID(uuidString: "b1111111-0000-0000-0000-000000000004")!,
            title: "Night City Glowing Signs",
            category: "Outrun",
            resolution: "Retina HD (0% CPU)",
            fileSizeMB: 2.3,
            thumbnailUrl: "preview_outrun_sunset.jpg",
            videoUrl: "\(rawBase)/outrun/a_street_with_buildings_and_signs.png",
            author: "Omarchy (dharmx/walls)"
        ),

        // MARK: - Omarchy Nord & Gruvbox Themes
        WallpaperItem(
            id: UUID(uuidString: "c1111111-0000-0000-0000-000000000001")!,
            title: "Nordic Mountain Valley",
            category: "Nord",
            resolution: "Retina HD (0% CPU)",
            fileSizeMB: 1.8,
            thumbnailUrl: "preview_waves_monochrome.jpg",
            videoUrl: "\(rawBase)/nord/a_view_of_a_valley_with_mountains_in_the_background.png",
            author: "Omarchy (dharmx/walls)"
        ),
        WallpaperItem(
            id: UUID(uuidString: "c1111111-0000-0000-0000-000000000002")!,
            title: "Gruvbox Bamboo Solitude",
            category: "Gruvbox",
            resolution: "Retina HD (0% CPU)",
            fileSizeMB: 1.8,
            thumbnailUrl: "preview_totoro.jpg",
            videoUrl: "\(rawBase)/gruvbox/a_bench_in_a_bamboo_forest.png",
            author: "Omarchy (dharmx/walls)"
        ),
        WallpaperItem(
            id: UUID(uuidString: "c1111111-0000-0000-0000-000000000003")!,
            title: "Nord Alpine River Bridge",
            category: "Nord",
            resolution: "Retina HD (0% CPU)",
            fileSizeMB: 0.5,
            thumbnailUrl: "preview_waves_monochrome.jpg",
            videoUrl: "\(rawBase)/nord/a_body_of_water_with_a_bridge_and_trees.jpg",
            author: "Omarchy (dharmx/walls)"
        ),

        // MARK: - Omarchy Nature & Minimal Themes
        WallpaperItem(
            id: UUID(uuidString: "d1111111-0000-0000-0000-000000000001")!,
            title: "Palm Beach Full Moon",
            category: "Nature",
            resolution: "Retina 4K (0% CPU)",
            fileSizeMB: 10.8,
            thumbnailUrl: "preview_outrun_sunset.jpg",
            videoUrl: "\(rawBase)/nature/a_beach_with_palm_trees_and_a_moon.png",
            author: "Omarchy (dharmx/walls)"
        ),
        WallpaperItem(
            id: UUID(uuidString: "d1111111-0000-0000-0000-000000000002")!,
            title: "Bamboo Forest Solitude",
            category: "Nature",
            resolution: "Retina HD (0% CPU)",
            fileSizeMB: 1.8,
            thumbnailUrl: "preview_totoro.jpg",
            videoUrl: "\(rawBase)/nature/a_bench_in_a_bamboo_forest.png",
            author: "Omarchy (dharmx/walls)"
        ),
        WallpaperItem(
            id: UUID(uuidString: "d1111111-0000-0000-0000-000000000003")!,
            title: "Monochrome Tree of Life",
            category: "Minimal",
            resolution: "Retina HD (0% CPU)",
            fileSizeMB: 0.2,
            thumbnailUrl: "preview_waves_monochrome.jpg",
            videoUrl: "\(rawBase)/minimal/a_black_and_white_diagram_of_a_tree_of_life.jpg",
            author: "Omarchy (dharmx/walls)"
        ),

        // MARK: - Built-in Cloud Starter Videos
        WallpaperItem(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            title: "Cosmic Nebula Flow",
            category: "Sci-Fi",
            resolution: "1080p (Optimized)",
            fileSizeMB: 8.4,
            thumbnailUrl: "preview_celestial_veil.jpg",
            videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
            author: "Cosmos Motion Lab"
        ),
        WallpaperItem(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            title: "Misty Alpine Forest",
            category: "Nature",
            resolution: "1080p (Low Power)",
            fileSizeMB: 6.2,
            thumbnailUrl: "preview_waves_monochrome.jpg",
            videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
            author: "Earth Scenic"
        ),
        WallpaperItem(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            title: "Tokyo Cyberpunk Rain",
            category: "Sci-Fi",
            resolution: "1080p (Vibrant)",
            fileSizeMB: 12.1,
            thumbnailUrl: "preview_sakura_blade.jpg",
            videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
            author: "NeoShinjuku"
        ),
        WallpaperItem(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            title: "Earth Orbit Horizon",
            category: "Nature",
            resolution: "4K (H.264 Accelerated)",
            fileSizeMB: 14.8,
            thumbnailUrl: "preview_celestial_veil.jpg",
            videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4",
            author: "Orbital Spaceflight"
        ),
        WallpaperItem(
            id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
            title: "Lo-Fi Rainy Window",
            category: "Anime",
            resolution: "1080p (Ultra Quiet)",
            fileSizeMB: 5.7,
            thumbnailUrl: "preview_lofi_headphones.jpg",
            videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4",
            author: "Chilled Beats"
        ),
        WallpaperItem(
            id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
            title: "Minimalist Gradient Waves",
            category: "Minimal",
            resolution: "1080p (Fluid)",
            fileSizeMB: 4.1,
            thumbnailUrl: "preview_waves_monochrome.jpg",
            videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackSeeTheWorld.mp4",
            author: "Aesthetic Studio"
        )
    ]
}
