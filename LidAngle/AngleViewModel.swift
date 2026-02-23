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
    private var useFastPolling = false

    init() {
        startPolling()
    }

    deinit {
        timer?.invalidate()
    }

    /// Normal polling interval — limits CPU wakeups and battery use.
    private static let pollInterval: TimeInterval = 3.0
    /// When sleep-by-angle is on and angle is near threshold, poll more often so we don’t miss a close.
    private static let pollIntervalNearThreshold: TimeInterval = 0.75
    /// How many degrees above threshold counts as “near” for faster polling.
    private static let nearThresholdMargin: Double = 15

    private func startPolling() {
        scheduleTimer(interval: Self.pollInterval)
        tick()
    }

    private func scheduleTimer(interval: TimeInterval) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        timer?.tolerance = interval * 0.4
        if let t = timer {
            RunLoop.main.add(t, forMode: .common)
        }
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
        let threshold = defaults.integer(forKey: LidAngleStorageKeys.sleepThreshold)
        let limit = threshold <= 0 ? 30.0 : Double(threshold)

        if !sleepEnabled {
            if useFastPolling {
                useFastPolling = false
                scheduleTimer(interval: Self.pollInterval)
            }
            return
        }

        let nearThreshold = angle > limit && angle <= limit + Self.nearThresholdMargin
        if nearThreshold != useFastPolling {
            useFastPolling = nearThreshold
            scheduleTimer(interval: nearThreshold ? Self.pollIntervalNearThreshold : Self.pollInterval)
        }

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
