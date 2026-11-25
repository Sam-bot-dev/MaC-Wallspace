import Cocoa
import SwiftUI

public final class CoverflowWindowController: NSWindowController {
    public static let shared = CoverflowWindowController()
    
    public var onLeftArrow: (() -> Void)?
    public var onRightArrow: (() -> Void)?
    public var onReturn: (() -> Void)?
    public var onEscape: (() -> Void)?
    
    private var eventMonitor: Any?
    
    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 940, height: 580),
            styleMask: [.titled, .closable, .fullSizeContentView, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Wallpaper Switcher (Coverflow)"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isReleasedWhenClosed = false
        window.backgroundColor = NSColor(red: 0.05, green: 0.06, blue: 0.09, alpha: 1.0)
        window.contentView = NSHostingView(rootView: CoverflowSwitcherView())
        
        super.init(window: window)
        setupEventMonitor()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupEventMonitor() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, let window = self.window, window.isKeyWindow else {
                return event
            }
            
            switch event.keyCode {
            case 123: // Left Arrow
                self.onLeftArrow?()
                return nil
            case 124: // Right Arrow
                self.onRightArrow?()
                return nil
            case 36, 76: // Return / Enter
                self.onReturn?()
                return nil
            case 53: // Escape
                self.onEscape?()
                return nil
            default:
                return event
            }
        }
    }
    
    public func show() {
        guard let window = self.window else { return }
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    public func toggle() {
        if let window = self.window, window.isVisible {
            window.orderOut(nil)
        } else {
            show()
        }
    }
    
    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
