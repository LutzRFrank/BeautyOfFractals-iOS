//
//  BeautyOfFractalsApp_iOS_Port.swift
//  BeautOfFractals
//
//  Created by Lutz-R. Frank on 16.06.2026.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

@main
struct MandelbrotExplorerApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        #if os(macOS)
        .defaultSize(width: 1440, height: 900)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandMenu("Fractal") {
                Button("Export 2560 × 1600 PNG") {
                    NotificationCenter.default.post(
                        name: .exportDefaultFractal,
                        object: nil
                    )
                }
                .keyboardShortcut("s", modifiers: .command)
                
                Divider()
                
                Button("Zoom In") {
                    NotificationCenter.default.post(
                        name: .zoomInFractal,
                        object: nil
                    )
                }
                .keyboardShortcut("+", modifiers: [])
                
                Button("Zoom Out") {
                    NotificationCenter.default.post(
                        name: .zoomOutFractal,
                        object: nil
                    )
                }
                .keyboardShortcut("-", modifiers: [])
                
                Button("Reset View") {
                    NotificationCenter.default.post(
                        name: .resetFractal,
                        object: nil
                    )
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
        #endif
    }
}

#if os(macOS)
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

#endif

extension Notification.Name {
    static let exportDefaultFractal = Notification.Name("exportDefaultFractal")
    static let zoomInFractal = Notification.Name("zoomInFractal")
    static let zoomOutFractal = Notification.Name("zoomOutFractal")
    static let resetFractal = Notification.Name("resetFractal")
}

struct FractalActions {
    let snap: () -> Void
    let zoomIn: () -> Void
    let zoomOut: () -> Void
    let reset: () -> Void
}

private struct FractalActionsKey: FocusedValueKey {
    typealias Value = FractalActions
}

extension FocusedValues {
    var fractalActions: FractalActions? {
        get { self[FractalActionsKey.self] }
        set { self[FractalActionsKey.self] = newValue }
    }
}
