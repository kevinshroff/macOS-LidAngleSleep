//
//  HIDLidAngleSensor.swift
//  LidAngle
//
//  Minimal wrapper that talks directly to the Mac lid angle HID device
//  using IOHIDManager, based on reverse‑engineered parameters.
//

import Foundation
import IOKit.hid

final class HIDLidAngleSensor {
    private var manager: IOHIDManager
    private var device: IOHIDDevice?

    init() {
        // Create + open a HID manager
        manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))

        // Start with the known identifiers; we'll broaden if nothing is found
        let primaryMatch: [String: Any] = [
            kIOHIDVendorIDKey as String: 0x05AC,     // Apple
            kIOHIDProductIDKey as String: 0x8104,    // Product ID seen on many models
            kIOHIDDeviceUsagePageKey as String: 0x0020, // Sensor page
            kIOHIDDeviceUsageKey as String: 0x008A      // Orientation usage
        ]

        IOHIDManagerSetDeviceMatching(manager, primaryMatch as CFDictionary)
        self.device = findWorkingDevice()
        
        // If not found, relax matching (drop ProductID)
        if self.device == nil {
            let relaxedMatch: [String: Any] = [
                kIOHIDVendorIDKey as String: 0x05AC,
                kIOHIDDeviceUsagePageKey as String: 0x0020,
                kIOHIDDeviceUsageKey as String: 0x008A
            ]
            IOHIDManagerSetDeviceMatching(manager, relaxedMatch as CFDictionary)
            self.device = findWorkingDevice()
        }
        
        // If still not found, try usage-only match
        if self.device == nil {
            let broadMatch: [String: Any] = [
                kIOHIDDeviceUsagePageKey as String: 0x0020,
                kIOHIDDeviceUsageKey as String: 0x008A
            ]
            IOHIDManagerSetDeviceMatching(manager, broadMatch as CFDictionary)
            self.device = findWorkingDevice()
        }
        if let d = self.device {
            _ = IOHIDDeviceOpen(d, IOOptionBits(kIOHIDOptionsTypeNone))
        }
    }

    deinit {
        if let d = device {
            IOHIDDeviceClose(d, IOOptionBits(kIOHIDOptionsTypeNone))
        }
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    }

    var isAvailable: Bool { device != nil }

    func lidAngle() -> Double? {
        guard let d = device else { return nil }

        // Read via Feature report, ID 1. Expected layout: [report_id, angle_lo, angle_hi]
        var report = [UInt8](repeating: 0, count: 8)
        var length: CFIndex = report.count
        let result = IOHIDDeviceGetReport(d,
                                          kIOHIDReportTypeFeature,
                                          CFIndex(1),
                                          &report,
                                          &length)

        if result == kIOReturnSuccess, length >= 3 {
            let low = UInt16(report[1])
            let high = UInt16(report[2]) << 8
            let raw = high | low
            // Empirically this is already degrees on newer machines
            return Double(raw)
        }

        return nil
    }

    // MARK: - Discovery
    private func findWorkingDevice() -> IOHIDDevice? {
        guard let devices = IOHIDManagerCopyDevices(manager) else { return nil }

        let count = CFSetGetCount(devices)
        var values = Array<UnsafeRawPointer?>(repeating: nil, count: count)
        CFSetGetValues(devices, &values)

        for i in 0..<count {
            if let raw = values[i] {
                let dev = unsafeBitCast(raw, to: IOHIDDevice.self)
                if IOHIDDeviceOpen(dev, IOOptionBits(kIOHIDOptionsTypeNone)) == kIOReturnSuccess {
                    var test = [UInt8](repeating: 0, count: 8)
                    var len: CFIndex = test.count
                    let res = IOHIDDeviceGetReport(dev,
                                                   kIOHIDReportTypeFeature,
                                                   CFIndex(1),
                                                   &test,
                                                   &len)
                    IOHIDDeviceClose(dev, IOOptionBits(kIOHIDOptionsTypeNone))
                    if res == kIOReturnSuccess, len >= 3 {
                        return dev
                    }
                }
            }
        }
        return nil
    }
}
