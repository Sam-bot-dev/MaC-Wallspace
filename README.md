# MaC Wallspace 🖼️

An ultra-lightweight, hardware-accelerated native macOS live wallpaper application designed specifically for older Intel and Apple Silicon Macs.

## Overview

Many older Mac models (running macOS Big Sur, Monterey, or Ventura) are excluded from modern live wallpaper features, while third-party apps often consume excessive CPU, memory, and battery.

**MaC Wallspace** solves this by using native macOS AppKit and AVFoundation VideoToolbox hardware decoding, resulting in an application footprint of under 1MB, ~25MB RAM, and negligible CPU usage.

## Key Features

- **Native Desktop Integration**: Custom borderless desktop canvas positioned behind Finder icons (`ignoresMouseEvents = true`), keeping all desktop files and right-click menus interactive.
- **Hardware-Accelerated Decoding**: Direct VideoToolbox hardware video pipeline with zero heavy web wrappers or Electron runtimes.
- **Intelligent Battery Governor**: Automatically halts playback when running on battery power or when battery is below 20%.
- **Fullscreen Occlusion Detection**: Pauses video decoding when games or applications are running in full screen, freeing 100% GPU and CPU resources.
- **Sleep & Lock Detection**: Automatically pauses when screens sleep, system sleeps, or screen locks.
- **Multi-Display Support**: Detects all connected screens and dynamically adjusts across monitors.
- **Offline Ready**: Includes a built-in animated shader loop generator that works immediately without an internet connection.
- **Custom Imports**: Drag and drop any MP4, MOV, or animated GIF to set as your desktop wallpaper.
- **Menu Bar Daemon**: Runs quietly in the macOS menu bar with instant pause, next, mute, and configuration options.

## System Requirements

- **macOS Version**: macOS 11.0 (Big Sur) or newer (macOS 11, 12, 13, 14, 15)
- **Architecture**: Intel (`x86_64`) and Apple Silicon (`arm64`)

## Building from Source

```bash
# Clone the repository
git clone https://github.com/Sam-bot-dev/mac-wallspace.git
cd mac-wallspace

# Build the macOS .app bundle
make app

# Package DMG and release ZIP
make release
```

Built artifacts will be placed in the `dist/` directory.

## License

MIT
