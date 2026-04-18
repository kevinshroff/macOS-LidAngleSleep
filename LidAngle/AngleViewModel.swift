//
//  AngleViewModel.swift
//  LidAngle
//
//  Polls the lid angle sensor and publishes the current value for the menu bar.
//  When “sleep when below threshold” is on, triggers system sleep whenever angle is
//  at or below the threshold (every poll). That way if the Mac wakes accidentally
//  (e.g. uncalibrated sensor, phantom keypress) while the lid is still closed, we
//  put it back to sleep on the next poll.
//

import Foundation

@MainActor
final class AngleViewModel: ObservableObject {
    @Published var angleText: String = "—°"
    private let sensor = HIDLidAngleSensor()
    private var timer: Timer?

    init() {
        startPolling()
    }

    deinit {
        timer?.invalidate()
    }

    /// Polling interval — kept conservative to limit CPU wakeups and battery use.
    private static let pollInterval: TimeInterval = 5.0

    private func startPolling() {
        timer?.invalidate()
        let t = Timer.scheduledTimer(withTimeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        t.tolerance = Self.pollInterval * 0.4
        RunLoop.main.add(t, forMode: .common)
        timer = t
        tick()
    }

    private func tick() {
        let value = sensor.lidAngle()
        if let value {
            angleText = String(format: "%.0f°", value)
            checkSleepThreshold(angle: value)
        } else {
            angleText = "—°"
        }
    }

    private func checkSleepThreshold(angle: Double) {
        let defaults = UserDefaults.standard
        let sleepEnabled = defaults.bool(forKey: LidAngleStorageKeys.sleepWhenEnabled)
        guard sleepEnabled else { return }
        let threshold = defaults.integer(forKey: LidAngleStorageKeys.sleepThreshold)
        let limit = threshold <= 0 ? 30.0 : Double(threshold)
        if angle <= limit {
            SystemSleep.trigger()
        }
    }
}

enum SystemSleep {
    /// Puts the Mac to sleep using `pmset sleepnow`.
    static func trigger() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["sleepnow"]
        try? process.run()
        process.waitUntilExit()
    }
}
