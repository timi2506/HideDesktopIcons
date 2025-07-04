//
//  HideDesktopIconsApp.swift
//  HideDesktopIcons
//
//  Created by Tim on 29.06.25.
//

import SwiftUI

@main
struct HideDesktopIconsApp: App {
    init() {
        NSWindow.swizzleCanBecomeKey()
    }
    @State var enabled: Bool = false
    @Environment(\.openWindow) var openWindow
    @AppStorage("cancelDismiss") var cancelDismiss = false
    @State var previousValue = false
    var body: some Scene {
        MenuBarExtra(content: {
            ContentView(enabled: $enabled)
                .onChange(of: enabled) { newValue in
                    if previousValue != newValue {
                        dismissAllPopups()
                        cancelDismiss = true
                        openWindow.callAsFunction(id: "popup", value: newValue)
                    }
                    previousValue = newValue
                }
        }) {
            Image(enabled ? "desktop.shown" : "desktop.hidden")
        }
        .menuBarExtraStyle(.window)
        WindowGroup(id: "popup", for: Bool.self) {
            PopupView(bool: $0)
                .background(
                    WindowAccessor(callback: { w in
                        w?.styleMask = .borderless
                        w?.backgroundColor = .clear
                        if let w {
                            guard let screen = w.screen ?? NSScreen.main else { return }
                            
                            let screenFrame = screen.visibleFrame
                            let windowSize = w.frame.size
                            
                            let newOrigin = CGPoint(
                                x: screenFrame.origin.x + screenFrame.size.width - windowSize.width,
                                y: screenFrame.origin.y
                            )
                            
                            w.setFrameOrigin(newOrigin)
                        }
                    })
                )
        }
        .handlesExternalEvents(matching: [])
        .commandsRemoved()
    }
    func dismissAllPopups() {
        for window in NSApplication.shared.windows {
            if let id = window.identifier, id.rawValue.contains("popup") {
                print("Window contains Popup will be closed")
                guard let screen = window.screen ?? NSScreen.main else { return }
                
                let screenFrame = screen.visibleFrame
                let windowSize = window.frame.size
                
                let newOrigin = CGPoint(
                    x: screenFrame.origin.x,
                    y: screenFrame.origin.y + screenFrame.height - windowSize.height
                )
                
                window.setFrameOrigin(newOrigin)
                window.close()
            }
        }
    }
}

extension View {
    func windowAccess(_ onReceive: @escaping (NSWindow?) -> Void) -> some View {
        self.background(
            WindowAccessor(callback: onReceive)
        )
    }
}

struct WindowAccessor: NSViewRepresentable {
    var callback: (NSWindow?) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            callback(view.window)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

import AppKit
import ObjectiveC.runtime

extension NSWindow {
    @objc func swizzled_canBecomeKey() -> Bool {
        return true
    }

    static func swizzleCanBecomeKey() {
        let originalSelector = #selector(getter: NSWindow.canBecomeKey)
        let swizzledSelector = #selector(swizzled_canBecomeKey)

        guard
            let originalMethod = class_getInstanceMethod(NSWindow.self, originalSelector),
            let swizzledMethod = class_getInstanceMethod(NSWindow.self, swizzledSelector)
        else { return }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}
