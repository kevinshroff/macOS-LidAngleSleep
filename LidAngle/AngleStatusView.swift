//
//  AngleStatusView.swift
//  LidAngle
//
//  Custom view for the menu bar so the status item shows even when the default button doesn’t.
//

import AppKit

final class AngleStatusView: NSView {
    private let textField: NSTextField
    var onRightClick: (() -> Void)?

    override var intrinsicContentSize: NSSize {
        NSSize(width: 44, height: 22)
    }

    init() {
        self.textField = NSTextField(labelWithString: "—°")
        super.init(frame: NSRect(x: 0, y: 0, width: 44, height: 22))
        textField.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        textField.textColor = .labelColor
        textField.backgroundColor = .clear
        textField.isBordered = false
        textField.isEditable = false
        textField.isSelectable = false
        textField.alignment = .center
        textField.frame = bounds
        textField.autoresizingMask = [.width, .height]
        addSubview(textField)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTitle(_ title: String) {
        textField.stringValue = title
    }

    override func rightMouseDown(with event: NSEvent) {
        onRightClick?()
    }

    override func mouseDown(with event: NSEvent) {
        // Left click: do nothing but allow right-click menu to work when opened via ctrl+click
        if event.modifierFlags.contains(.control) {
            onRightClick?()
        }
    }
}
