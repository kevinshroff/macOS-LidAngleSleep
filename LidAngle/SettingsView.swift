//
//  SettingsView.swift
//  LidAngle
//
//  Settings for lid-angle sleep threshold and launch at login.
//

import SwiftUI
import ServiceManagement

enum LidAngleStorageKeys {
    static let sleepWhenEnabled = "sleepWhenLidAngleEnabled"
    static let sleepThreshold = "sleepWhenLidAngleThreshold"
}

struct SettingsView: View {
    @AppStorage(LidAngleStorageKeys.sleepWhenEnabled) private var sleepWhenEnabled = false
    @AppStorage(LidAngleStorageKeys.sleepThreshold) private var sleepThreshold: Int = 30
    @State private var launchAtLoginEnabled = false

    private let thresholdRange = 5...200

    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: $launchAtLoginEnabled)
            } footer: {
                Text("Start LidAngle automatically when you log in.")
            }
            .onChange(of: launchAtLoginEnabled) { _, newValue in
                if newValue {
                    try? SMAppService.mainApp.register()
                } else {
                    try? SMAppService.mainApp.unregister()
                }
            }
            .onAppear {
                launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
            }

            Section {
                Toggle("Put Mac to sleep when lid is at or below threshold", isOn: $sleepWhenEnabled)
            } footer: {
                Text("When the lid angle is equal to or below the value below, the Mac will be put to sleep.")
            }

            Section("Threshold (degrees)") {
                HStack {
                    Slider(
                        value: Binding(
                            get: { Double(sleepThreshold) },
                            set: { sleepThreshold = Int($0.rounded()) }
                        ),
                        in: Double(thresholdRange.lowerBound)...Double(thresholdRange.upperBound),
                        step: 5
                    )
                    Text("\(sleepThreshold)°")
                        .frame(width: 36, alignment: .trailing)
                        .monospacedDigit()
                }
                .disabled(!sleepWhenEnabled)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 380, minHeight: 200)
    }
}

#Preview {
    SettingsView()
}
