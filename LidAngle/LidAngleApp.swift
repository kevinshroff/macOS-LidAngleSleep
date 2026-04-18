//
//  LidAngleApp.swift
//  LidAngle
//
//  Created by Deepak Kumar on 11/09/25.
//

import SwiftUI
import AppKit

@main
struct LidAngleApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var angleModel = AngleViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarExtraContent()
        } label: {
            Text(angleModel.angleText)
                .font(.system(size: 13, design: .monospaced))
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
        }
    }
}

private final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

private struct MenuBarExtraContent: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button("Settings…") {
            openSettings()
        }
        .keyboardShortcut(",", modifiers: .command)

        Button("About LidAngle") {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.orderFrontStandardAboutPanel(nil)
        }

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
