# MaC-Wallspace — Ultra-Lightweight Live Wallpaper Engine for Older Macs 🖼️⚡

[![macOS: 11.0+](https://img.shields.io/badge/macOS-11.0%2B%20(Big%20Sur%20%E2%86%92%20Sequoia)-000000.svg?logo=apple&logoColor=white)](https://github.com/Sam-bot-dev/MaC-Wallspace)
[![Architecture: Universal](https://img.shields.io/badge/Architecture-Intel%20x86__64%20%7C%20Apple%20Silicon-blue.svg)](https://github.com/Sam-bot-dev/MaC-Wallspace)
[![Hardware Acceleration](https://img.shields.io/badge/VideoToolbox-Hardware%20H.264%2FHEVC-10b981.svg)](https://github.com/Sam-bot-dev/MaC-Wallspace)
[![Battery Impact](https://img.shields.io/badge/Battery%20Drain-Zero%20(Auto--Pause%20on%20Battery)-brightgreen.svg)](#7-intelligent-battery--thermal-governors)
[![RAM Footprint](https://img.shields.io/badge/RAM-~25MB%20(vs%20500MB%2B%20Electron)-brightgreen.svg)](#-5-performance-benchmarks-mac-wallspace-vs-alternatives)
[![CPU Usage](https://img.shields.io/badge/CPU-%3C1.5%25%20Idle%20Decode-blueviolet.svg)](#-5-performance-benchmarks-mac-wallspace-vs-alternatives)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **Run silky-smooth 4K, 1080p, and custom animated live wallpapers on older Intel & Apple Silicon Macs without thermal throttling, roaring fans, or battery drain.**
>
> Built natively in **Swift, AppKit, and AVFoundation** with zero Electron, zero web wrappers, and near-zero system overhead.

---

## 📑 Table of Contents
1. [The Problem: Why Older Macs Struggle](#1-the-problem-why-older-macs-struggle)
2. [What MaC-Wallspace Does](#2-what-mac-wallspace-does)
3. [Architecture & Engine Workflow](#3-architecture--engine-workflow)
4. [Adding Your Own Live Wallpapers](#4-adding-your-own-live-wallpapers)
5. [Dynamic Playlists & Auto-Cycling](#5-dynamic-playlists--auto-cycling)
6. [Pre-Installed & Provided Live Wallpapers](#6-pre-installed--provided-live-wallpapers)
7. [Performance Benchmarks: MaC-Wallspace vs. Alternatives](#7-performance-benchmarks-mac-wallspace-vs-alternatives)
8. [Intelligent Battery & Thermal Governors](#8-intelligent-battery--thermal-governors-zero-battery-drain)
9. [Installation & Quick Start](#9-installation--quick-start)
10. [Menu Bar Controls & Shortcuts](#10-menu-bar-controls--shortcuts)
11. [Repository Structure](#11-repository-structure)
12. [License](#12-license)

---

## 1. The Problem: Why Older Macs Struggle

Millions of Macs running macOS Big Sur (11), Monterey (12), and Ventura (13) — especially Intel Core i5/i7 models — are artificially excluded or severely penalized by existing live wallpaper solutions:

1. **Apple's macOS Sonoma API Lockout**:  
   Apple introduced dynamic aerial wallpapers in macOS 14 Sonoma, but deliberately excluded older macOS versions and older Intel hardware.
2. **The Electron & Web-Wrapper Bloat**:  
   Popular apps like Wallspace or third-party wallpaper engines wrap web browsers or Electron shells. On an older MacBook Air or Pro, running a 500MB+ Chromium runtime alongside video decoding causes:
   - **40% to 80% CPU spikes** on dual-core and quad-core Intel chips.
   - **Loud thermal fans** kicking in within minutes.
   - **Battery drain** that cuts laptop run-time down to under an hour.
3. **Broken Desktop Interactivity**:  
   Poorly written wallpaper apps capture mouse clicks or break Finder desktop icon drag-and-drop, lasso file selection, and right-click context menus.

---

## 2. What MaC-Wallspace Does

**MaC-Wallspace** replaces heavy third-party runtimes with a native, pure Swift micro-engine designed directly against low-level macOS AppKit and VideoToolbox APIs:

- 🪶 **Under 1 MB Distribution Size**: Complete installer `.dmg` is only ~540 KB.
- ⚡ **Direct Hardware Decoding**: VideoToolbox H.264/HEVC hardware acceleration draws < 1.5% CPU.
- 🗂️ **3D Coverflow HUD Switcher**: Press `Cmd + Shift + W` or click "3D Switcher" to browse wallpapers in an interactive 3D perspective carousel with arrow keys (`←` / `→`) and `Enter` (↵) to apply immediately.
- 🎨 **Omarchy Wallpapers & Theme Playlists**: Bundles curated live and static wallpapers from [**Omarchy** (`dharmx/walls`)](https://github.com/dharmx/walls), cleanly split into theme playlists (*Animated Live, Anime, Outrun, Nord, Gruvbox, Nature, Minimal*).
- 🖱️ **Zero Interference with Desktop**: Sets `ignoresMouseEvents = true` behind `kCGDesktopWindowLevel`, preserving 100% of Finder desktop icon clicks, folder operations, and drag selections.
- 🔋 **Smart Battery Governor**: Automatically halts video playback when unplugged or below 20% battery.
- 🎮 **Fullscreen App & Game Detection**: Instantly pauses decoding when games, browsers, or code editors enter fullscreen mode, releasing 100% GPU/CPU power to your active tasks.
- 🖥️ **Multi-Display & Spaces Support**: Automatically detects hot-plugged displays and maintains seamless desktop coverage across Mission Control Spaces without black flashes.

---

## 3. Architecture & Engine Workflow

```mermaid
flowchart TD
    subgraph Inputs ["Wallpaper Sources"]
        USER["User Video Import (MP4 / MOV / GIF)"]
        BUILTIN["Pre-Installed Offline Shaders"]
        FEED["Curated Online Catalog"]
    end

    subgraph Store ["Wallpaper Storage & Extraction"]
        STORE["WallpaperStore (~/Library/Application Support/MacWallspace)"]
        THUMB["AVAssetImageGenerator (Extract 640x360 Live Thumbnails)"]
    end

    subgraph Governors ["Power & Occlusion Governors"]
        POW["PowerGovernor (IOKit Battery & Sleep Monitor)"]
        FULL["FullscreenDetector (CGWindowList Occlusion Check)"]
    end

    subgraph Engine ["Native macOS Engine"]
        WIN["DesktopWindowManager (kCGDesktopWindowLevel)"]
        VIEW["VideoPlayerView (AVPlayerLayer & AVPlayerLooper)"]
        VT["Apple VideoToolbox (Hardware Acceleration)"]
    end

    subgraph Canvas ["macOS Workspace Canvas"]
        FINDER["Finder Desktop Icons & Lasso Selection (Fully Interactive)"]
        SCREEN1["Primary Display"]
        SCREEN2["External Monitor"]
    end

    USER --> STORE
    BUILTIN --> STORE
    FEED --> STORE
    STORE --> THUMB
    STORE --> WIN

    POW -.->|Pause on Battery / Sleep| VIEW
    FULL -.->|Pause on Fullscreen App| VIEW

    WIN --> VIEW
    VIEW --> VT
    VT --> SCREEN1
    VT --> SCREEN2
    SCREEN1 -.->|ignoresMouseEvents = true| FINDER
    SCREEN2 -.->|ignoresMouseEvents = true| FINDER
```

---

## 4. Adding Your Own Live Wallpapers

You can easily add your own custom live wallpapers and have them run immediately on your desktop:

### Method A: Drag & Drop (Easiest)
1. Open the MaC-Wallspace Gallery (`Cmd + ,` or click the menu bar icon).
2. Go to the **Import Custom** tab.
3. Drag and drop any `.mp4`, `.mov`, `.m4v`, or animated `.gif` file into the dropzone.
4. The engine automatically extracts video metadata, generates a preview thumbnail, and immediately sets it as your active desktop wallpaper!

### Method B: In-App File Browser
1. Click **Browse Files...** in the Import Custom tab.
2. Select your video file.
3. Click Open — your wallpaper is imported into your personal library and applied instantly.

### Method C: Terminal / Command-Line
You can add wallpapers directly from your terminal or shell scripts:
```bash
make add VIDEO=~/Downloads/my_favorite_wallpaper.mp4
```
Or run the standalone importer:
```bash
./scripts/add_wallpaper.sh ~/Movies/cyberpunk_city.mp4
```

---

## 5. Dynamic Playlists & Auto-Cycling

MaC-Wallspace includes a built-in playlist engine that lets you organize and cycle through your live wallpapers seamlessly:

- 📥 **Automatic Playlist Ingestion**: Whenever you import or add a new live wallpaper (MP4, MOV, or animated loop), it is **automatically added** to your *"My Live Wallpapers"* playlist.
- 🗂️ **Custom Playlists**: Create specialized playlists (e.g. *Anime Vibes*, *Cyberpunk Night*, *Ambient Nature*, *Study Chill*).
- 🔄 **Auto-Cycling Intervals**: Automatically transition to the next wallpaper in your playlist every **5 minutes**, **15 minutes**, **30 minutes**, or **1 hour**.
- 🔀 **Smart Shuffle**: Randomize your wallpaper loop to keep your Mac desktop feeling fresh throughout the day.
- ⌨️ **Instant Cycling Shortcuts**:
  - `Cmd + N` — Switch immediately to the **Next** wallpaper in your active playlist.
  - `Cmd + Shift + N` — Switch back to the **Previous** wallpaper.
- 🔋 **Battery-Aware Cycling**: The auto-cycling timer respects power management — if your Mac is running on battery or in display sleep, background timer wakeups are halted to prevent battery drain.

---

## 6. Pre-Installed & Omarchy Wallpapers with Live Previews

MaC-Wallspace includes curated high-definition 4K & 1080p live loops and Retina static wallpapers out-of-the-box, with full attribution to [**Omarchy** (`dharmx/walls`)](https://github.com/dharmx/walls).

### 🖼️ Featured Community Wallpapers (Click Any Image to View Full Size)

| 🗡️ **Bleach Manga Ichigo** | 🎀 **Cat Maid Logo** | 🎧 **Lo-Fi Headphones** | 🐰 **Bunny & Chick Meadow** |
| :---: | :---: | :---: | :---: |
| [![Bleach Manga](docs/previews/preview_ichigo_manga.jpg)](docs/previews/preview_ichigo_manga.jpg) | [![Cat Maid](docs/previews/preview_cat_maid_logo.jpg)](docs/previews/preview_cat_maid_logo.jpg) | [![Lo-Fi Headphones](docs/previews/preview_lofi_headphones.jpg)](docs/previews/preview_lofi_headphones.jpg) | [![Bunny & Chick](docs/previews/preview_bunny_chick.jpg)](docs/previews/preview_bunny_chick.jpg) |
| **5K Ultra-Retina (5120×2880)** | **Ultrawide 21:9 (2560×1080)** | **1080p Aesthetic (1920×1080)** | **1080p Nature (1920×1080)** |

### 🎬 Curated Live & Static Wallpapers

| Wallpaper Title | Theme / Style | Resolution & Format | Preview (Click to Enlarge) |
| :--- | :--- | :--- | :---: |
| **Bleach Manga (Ichigo)** | Manga / Shonen | Retina Ultra-HD Photo | <a href="docs/previews/preview_ichigo_manga.jpg"><img src="docs/previews/preview_ichigo_manga.jpg" width="240" alt="Bleach Manga"></a> |
| **Anime Cat Maid Logo** | Minimal Anime Logo | Retina 1080p Photo | <a href="docs/previews/preview_cat_maid_logo.jpg"><img src="docs/previews/preview_cat_maid_logo.jpg" width="240" alt="Cat Maid"></a> |
| **Chillop Bunny & Chick** | Cozy & Cute | Retina Pastel Photo | <a href="docs/previews/preview_bunny_chick.jpg"><img src="docs/previews/preview_bunny_chick.jpg" width="240" alt="Bunny & Chick"></a> |
| **Lo-Fi Headphones** | Lo-Fi / Chillop | Retina Art Photo | <a href="docs/previews/preview_lofi_headphones.jpg"><img src="docs/previews/preview_lofi_headphones.jpg" width="240" alt="Lo-Fi Headphones"></a> |
| **Totoro Starry Night** | Studio Ghibli / Anime | 4K UHD 60 FPS Video Loop | <a href="docs/previews/preview_totoro.jpg"><img src="docs/previews/preview_totoro.jpg" width="240" alt="Totoro Starry Night"></a> |
| **Bocchi The Rock (Train)** | Anime & Cozy | 4K UHD 24 FPS Video Loop | <a href="docs/previews/preview_bocchi.jpg"><img src="docs/previews/preview_bocchi.jpg" width="240" alt="Bocchi The Rock"></a> |
| **Outrun Sunset Skyline** | Synthwave / Retro City | 4.6K Ultra-HD Retina Photo | <a href="docs/previews/preview_outrun_sunset.jpg"><img src="docs/previews/preview_outrun_sunset.jpg" width="240" alt="Outrun Sunset"></a> |
| **Sakura Katana Blade** | Anime & Action | 4K UHD 60 FPS Video Loop | <a href="docs/previews/preview_sakura_blade.jpg"><img src="docs/previews/preview_sakura_blade.jpg" width="240" alt="Sakura Blade"></a> |
| **Berserk Manga Eclipse** | Dark Anime / Manga | 1080p 60 FPS Video Loop | <a href="docs/previews/preview_berserk.jpg"><img src="docs/previews/preview_berserk.jpg" width="240" alt="Berserk Eclipse"></a> |
| **Celestial Light Veil** | Monochrome Chiaroscuro | 1080p 60 FPS Video Loop | <a href="docs/previews/preview_celestial_veil.jpg"><img src="docs/previews/preview_celestial_veil.jpg" width="240" alt="Celestial Veil"></a> |
| **Sailor Moon Window** | Retro 90s Aesthetic | 1080p Animated Loop | <a href="docs/previews/preview_sailor_moon.jpg"><img src="docs/previews/preview_sailor_moon.jpg" width="240" alt="Sailor Moon Window"></a> |
| **Monochrome Ocean Waves** | Minimalist Nature | Retina Ultra-HD Photo | <a href="docs/previews/preview_waves_monochrome.jpg"><img src="docs/previews/preview_waves_monochrome.jpg" width="240" alt="Monochrome Waves"></a> |
| **Spy x Family (Yor Forger)** | Anime Action | 1080p 60 FPS Video Loop | <a href="docs/previews/preview_yor_forger.jpg"><img src="docs/previews/preview_yor_forger.jpg" width="240" alt="Yor Forger"></a> |
| **Darling in the Franxx (Zero Two)** | Anime Dynamic | 1080p 60 FPS Video Loop | <a href="docs/previews/preview_zero_two.jpg"><img src="docs/previews/preview_zero_two.jpg" width="240" alt="Zero Two"></a> |

---

## 7. Performance Benchmarks: MaC-Wallspace vs. Alternatives

*Tested on a 13-inch MacBook Pro (Intel Core i5, 8GB RAM, macOS 13.7.8 Ventura):*

| Metric | Wallspace / Electron Apps | Dynamic Wallpaper (App Store) | **MaC-Wallspace (Native)** |
| :--- | :--- | :--- | :--- |
| **App Bundle Size** | ~250 MB – 450 MB | ~85 MB | **< 1 MB (541 KB)** ⚡ |
| **Idle Memory (RAM)** | 480 MB – 720 MB | 140 MB – 220 MB | **~25 MB – 35 MB** 🏆 |
| **CPU Utilization (Intel)** | 25% – 65% | 8% – 18% | **< 1.5%** 🚀 |
| **Hardware Decoding** | Inconsistent / Software Fallback | Metal 3 Required | **Apple VideoToolbox (H.264/HEVC)** |
| **Battery Life Impact** | Severe (Fans on, throttles in 1h) | Moderate | **Negligible (Auto-Pauses on Battery)** |
| **Desktop Icon Clicking** | Often blocks clicks or lags | Sometimes occludes | **100% Native (`ignoresMouseEvents`)** |
| **Older macOS Support** | Drops macOS 11 / 12 | Requires macOS 13+ | **macOS 11.0 Big Sur through 15.0+** |

---

## 8. Intelligent Battery & Thermal Governors (Zero Battery Drain)

One of the biggest flaws with third-party wallpaper engines (especially Chromium/Electron-based apps) is that they devour battery life, causing older MacBooks to run hot, spin fans loudly, and drain completely in under 90 minutes.

**MaC-Wallspace is engineered from the ground up for zero unneeded battery draw:**

```
      Power Status Change (MagSafe / USB-C Disconnected)
                             │
                             ▼
         IOPSNotificationCreateRunLoopSource (0ms event)
                             │
                             ▼
            PowerGovernor.evaluatePowerState()
                             │
            ┌────────────────┴────────────────┐
            ▼                                 ▼
   [On Battery: Default]             [Plugged in: AC Adapter]
   • AVQueuePlayer.pause()           • AVQueuePlayer.play()
   • VideoToolbox decode halted      • VideoToolbox HW Decode (<1.5% CPU)
   • 0.0% CPU / 0.0W GPU             • 60 FPS Smooth Looping
   • Freezes on crisp frame
```

### Key Battery & Power Protections:

1. 🔋 **Instant Hardware Disconnect Detection (`IOPSNotificationCreateRunLoopSource`)**:  
   Rather than polling in a loop, MaC-Wallspace hooks directly into macOS IOKit hardware power events. The exact microsecond you unplug your MacBook from its charger, the video engine pauses and stops drawing power.
2. 🪫 **0.0% CPU When Paused or Using Photos**:  
   When playback is paused (or when using static photo wallpapers), video decoding is completely halted. The app uses **0.0% CPU** and **0 MB/s disk I/O**, leaving the CPU cores in their deepest sleep states (C-states).
3. 🛑 **Emergency Low Battery Cap (≤ 20%)**:  
   If you choose to run live wallpapers on battery, the governor enforces an automatic safety freeze when battery falls to 20% (configurable), ensuring your Mac never dies unexpectedly during important work.
4. 🎮 **Instant Fullscreen & Space Occlusion Detection**:  
   Listens to `NSWorkspace.didActivateApplicationNotification` and `activeSpaceDidChangeNotification`. The moment you switch to a fullscreen browser, YouTube video, IDE, or game, wallpaper decoding pauses instantly to surrender 100% of your GPU and battery to the foreground app.
5. 💤 **Display Sleep & Screen Lock Instant Freeze**:  
   Listens to `screensDidSleepNotification` and `willSleepNotification`. Freezes rendering instantly when the display turns off or the MacBook lid is closed.
6. ⚡ **Dedicated Hardware ASIC Decoding**:  
   Video frames are decoded directly on Apple Silicon Media Engines or Intel QuickSync hardware ASICs via `VideoToolbox`. No software CPU rendering or shader emulation is ever used.
7. 🎯 **Customizable Target Frame Rates**:  
   Choose between **24 FPS (Ultra-Battery Saver)**, **30 FPS (Recommended for Older Intel Macs)**, or **60 FPS (Silky Smooth)** in the Performance tab to match your battery priorities.

---

## 9. Installation & Quick Start

### Download Pre-Built Releases
1. Download the latest release `.dmg` from the [**Releases Page**](https://github.com/Sam-bot-dev/MaC-Wallspace/releases).
2. Open `Mac-Wallspace-v1.1.0.dmg`.
3. Drag **Mac Wallspace** into your `Applications` folder.

### How to Open on First Launch (macOS Gatekeeper Bypass)
Because MaC Wallspace is a community open-source project without a paid corporate Apple Developer ID, macOS requires you to approve it on the very first launch:
1. Open **Finder** and go to your **Applications** folder.
2. **Right-Click** (or hold `Control` and click) **Mac Wallspace**.
3. Click **Open** from the popup menu.
4. When the macOS security prompt appears, click **Open** again (you press "Open" twice).
*(You only ever have to do this once. After the first time, you can double-click it normally forever).*

### How to Uninstall
You can uninstall easily at any time:
- **Inside the App**: Open **Settings** (click menu bar icon → *Open Wallspace Gallery & Settings* → *Settings* tab) and click **Uninstall & Quit**.
- **Manually**: 
  1. Click the menu bar icon and select **Quit MaC Wallspace** (or `Cmd + Q`).
  2. Drag `/Applications/Mac Wallspace.app` to the Trash.
  3. (Optional clean up) Run `rm -rf ~/Library/Application\ Support/MacWallspace` in Terminal.

### Build from Source
Requirements: macOS 11.0+, Swift 5.8+ (Command Line Tools).

```bash
# Clone the repository
git clone https://github.com/Sam-bot-dev/MaC-Wallspace.git
cd MaC-Wallspace

# Build the standalone macOS .app bundle
make app

# Package release DMG and ZIP
make release

# Run the app immediately
make run
```

---

## 10. Menu Bar Controls & Shortcuts

Click the **MaC-Wallspace** icon (`photo.artframe`) in the top macOS status bar for instant access:

- `Cmd + P` — ⏯ **Pause / Resume** Live Wallpaper
- `Cmd + N` — ⏭ **Next Wallpaper in Playlist**
- `Cmd + Shift + N` — ⏮ **Previous Wallpaper in Playlist**
- 🗂 **Playlists Submenu** — Quick one-click switching between active playlists
- `Cmd + M` — 🔇 **Mute / Unmute** Audio
- `Cmd + ,` — 🖼 **Open Gallery, Playlists & Settings Window**
- `Cmd + I` — 📂 **Import Custom Video or Photo...**
- `Cmd + Q` — 🚪 **Quit MaC-Wallspace**

---

## 11. Repository Structure

```
MaC-Wallspace/
├── Package.swift                     # Swift Package Manager manifest
├── Makefile                          # Quick build, run, package, and add commands
├── scripts/
│   ├── build_app.sh                  # Compiles native binary and creates .app bundle
│   ├── create_dmg.sh                 # Packages release DMG with Applications symlink
│   └── add_wallpaper.sh              # CLI tool to import custom video wallpapers
├── Resources/
│   ├── Info.plist                    # App metadata (LSUIElement = true for menu bar daemon)
│   └── MacWallspace.entitlements     # App security & sandbox permissions
├── Sources/
│   └── MacWallspace/
│       ├── main.swift                # App entry point
│       ├── AppDelegate.swift         # Lifecycle, MenuBar setup, background bootstrap
│       ├── Engine/
│       │   ├── DesktopWindowManager.swift  # Borderless window placed behind Finder icons
│       │   ├── VideoPlayerView.swift       # AVPlayerLayer / AVPlayerLooper hardware decode
│       │   ├── PowerGovernor.swift         # IOKit battery sensor & sleep auto-pause
│       │   ├── FullscreenDetector.swift    # Occlusion & fullscreen app auto-pause
│       │   └── DisplayMonitor.swift        # Multi-monitor detection & dynamic bounds
│       ├── Catalog/
│       │   ├── WallpaperItem.swift         # Wallpaper model with metadata
│       │   ├── WallpaperStore.swift        # Catalog persistence & thumbnail generator
│       │   ├── CuratedCatalog.swift        # Pre-configured online gallery collection
│       │   └── WallpaperDownloader.swift   # Asynchronous background downloader
│       ├── UI/
│       │   ├── MenuBarController.swift     # NSStatusItem dropdown menu
│       │   ├── GalleryWindowController.swift # Native window hosting SwiftUI gallery
│       │   └── Views/
│       │       ├── MainGalleryView.swift   # Tabbed gallery & library manager
│       │       ├── WallpaperCardView.swift # Card view with live image thumbnails
│       │       ├── CustomImportView.swift  # Drag-and-drop custom video importer
│       │       ├── DisplaysConfigView.swift # Multi-screen visual arrangement
│       │       ├── PerformanceSettingsView.swift # Battery & framerate governors
│       │       └── SettingsView.swift      # Startup, audio, and cache controls
│       └── Utilities/
│           ├── SampleVideoGenerator.swift  # Built-in offline dynamic loop generator
│           ├── LaunchAtLogin.swift         # LaunchAgent startup helper
│           └── SystemInfo.swift            # Hardware architecture & profiling
├── .github/
│   └── workflows/
│       └── release.yml               # Automated GitHub Actions build pipeline
├── .gitignore
└── README.md
```

---

## 12. License

Distributed under the **MIT License**. Created with ❤️ for Mac users everywhere.
