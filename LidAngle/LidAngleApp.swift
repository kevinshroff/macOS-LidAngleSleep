//
//  LidAngleApp.swift
//  LidAngle
//
//  Created by Deepak Kumar on 11/09/25.
//

import SwiftUI
import Cocoa

@main
struct LidAngleApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No main window; keep app headless with only a status item
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private let sensor = HIDLidAngleSensor()
    private lazy var contextMenu: NSMenu = {
        let menu = NSMenu()
        let quit = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        return menu
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon if possible at runtime
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "—°"
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        statusItem.menu = nil // no menu or extra features

        // Start periodic updates
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateAngle()
        }
        if let timer { RunLoop.main.add(timer, forMode: .common) }
        updateAngle()
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
    }

    private func updateAngle() {
        let angle = sensor.lidAngle()
        if let button = statusItem.button {
            if let angle {
                button.title = String(format: "%.0f°", angle)
            } else {
                button.title = "—°"
            }
        }
    }

    // MARK: - Menu handling (right-click only)
    @objc private func statusItemClicked(_ sender: Any?) {
        guard let event = NSApp.currentEvent else { return }
        let isRightClick = (event.type == .rightMouseUp || event.type == .rightMouseDown) || event.modifierFlags.contains(.control)
        if isRightClick {
            if let button = statusItem.button {
                let point = NSPoint(x: 0, y: button.bounds.height - 2)
                contextMenu.popUp(positioning: nil, at: point, in: button)
            }
        } else {
            // Ensure highlight is cleared when doing nothing on left click
            statusItem.button?.highlight(false)
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
