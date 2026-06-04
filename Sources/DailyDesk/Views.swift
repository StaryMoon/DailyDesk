import AppKit

final class GlassView: NSView {
    override var wantsUpdateLayer: Bool { true }

    override func updateLayer() {
        layer?.cornerRadius = 24
        layer?.masksToBounds = false
        layer?.backgroundColor = NSColor(calibratedWhite: 0.03, alpha: 0.11).cgColor
        layer?.borderColor = NSColor.white.withAlphaComponent(0.20).cgColor
        layer?.borderWidth = 0.8
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 0.26
        layer?.shadowOffset = CGSize(width: 0, height: -12)
        layer?.shadowRadius = 36
    }
}

final class CardView: NSView {
    var priority: Priority = .teal
    var completed = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let bounds = bounds.insetBy(dx: 0.5, dy: 0.5)
        let path = NSBezierPath(roundedRect: bounds, xRadius: 13, yRadius: 13)
        let top = completed
            ? NSColor(calibratedWhite: 0.10, alpha: 0.34)
            : NSColor(calibratedWhite: 0.11, alpha: 0.82)
        let bottom = completed
            ? NSColor(calibratedWhite: 0.025, alpha: 0.38)
            : NSColor(calibratedWhite: 0.018, alpha: 0.84)
        NSGradient(starting: top, ending: bottom)?.draw(in: path, angle: -90)

        NSColor.white.withAlphaComponent(completed ? 0.06 : 0.13).setStroke()
        path.lineWidth = 0.8
        path.stroke()

        let highlight = NSBezierPath()
        highlight.move(to: CGPoint(x: bounds.minX + 14, y: bounds.maxY - 1))
        highlight.line(to: CGPoint(x: bounds.maxX - 14, y: bounds.maxY - 1))
        NSColor.white.withAlphaComponent(completed ? 0.03 : 0.11).setStroke()
        highlight.lineWidth = 0.7
        highlight.stroke()

        let accentRect = NSRect(x: bounds.minX + 7, y: bounds.minY + 10, width: 3.5, height: bounds.height - 20)
        let accentPath = NSBezierPath(roundedRect: accentRect, xRadius: 2, yRadius: 2)
        (completed ? NSColor.white.withAlphaComponent(0.14) : priority.accent.withAlphaComponent(0.86)).setFill()
        accentPath.fill()
    }
}

final class RingView: NSView {
    var progress: CGFloat = 0 { didSet { needsDisplay = true } }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 4, dy: 4)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        let base = NSBezierPath()
        base.appendArc(withCenter: center, radius: radius, startAngle: 0, endAngle: 360)
        NSColor.white.withAlphaComponent(0.12).setStroke()
        base.lineWidth = 4.5
        base.stroke()

        let arc = NSBezierPath()
        arc.appendArc(withCenter: center, radius: radius, startAngle: 90, endAngle: 90 - 360 * progress, clockwise: true)
        NSColor(calibratedRed: 0.42, green: 0.88, blue: 0.80, alpha: 0.96).setStroke()
        arc.lineWidth = 4.5
        arc.lineCapStyle = .round
        arc.stroke()
    }
}

final class PetView: NSView {
    var equippedItemID: String?
    var completionProgress: CGFloat = 0
    var totalCoins: Int = 0

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let rect = bounds.insetBy(dx: 6, dy: 6)
        let bodyRect = NSRect(x: rect.midX - 18, y: rect.midY - 16, width: 36, height: 34)
        let body = NSBezierPath(roundedRect: bodyRect, xRadius: 18, yRadius: 18)
        NSColor(calibratedRed: 0.88, green: 0.94, blue: 1.00, alpha: 0.92).setFill()
        body.fill()
        NSColor.white.withAlphaComponent(0.36).setStroke()
        body.lineWidth = 1
        body.stroke()

        let leftEar = NSBezierPath()
        leftEar.move(to: CGPoint(x: bodyRect.minX + 6, y: bodyRect.maxY - 4))
        leftEar.line(to: CGPoint(x: bodyRect.minX + 13, y: bodyRect.maxY + 10))
        leftEar.line(to: CGPoint(x: bodyRect.minX + 18, y: bodyRect.maxY - 1))
        leftEar.close()
        let rightEar = NSBezierPath()
        rightEar.move(to: CGPoint(x: bodyRect.maxX - 6, y: bodyRect.maxY - 4))
        rightEar.line(to: CGPoint(x: bodyRect.maxX - 13, y: bodyRect.maxY + 10))
        rightEar.line(to: CGPoint(x: bodyRect.maxX - 18, y: bodyRect.maxY - 1))
        rightEar.close()
        NSColor(calibratedRed: 0.78, green: 0.88, blue: 1.00, alpha: 0.92).setFill()
        leftEar.fill()
        rightEar.fill()

        NSColor(calibratedWhite: 0.05, alpha: 0.86).setFill()
        NSBezierPath(ovalIn: NSRect(x: bodyRect.minX + 10, y: bodyRect.midY + 2, width: 4, height: 5)).fill()
        NSBezierPath(ovalIn: NSRect(x: bodyRect.maxX - 14, y: bodyRect.midY + 2, width: 4, height: 5)).fill()

        let smile = NSBezierPath()
        smile.move(to: CGPoint(x: bodyRect.midX - 6, y: bodyRect.midY - 6))
        smile.curve(
            to: CGPoint(x: bodyRect.midX + 6, y: bodyRect.midY - 6),
            controlPoint1: CGPoint(x: bodyRect.midX - 3, y: bodyRect.midY - 10),
            controlPoint2: CGPoint(x: bodyRect.midX + 3, y: bodyRect.midY - 10)
        )
        NSColor(calibratedWhite: 0.05, alpha: 0.72).setStroke()
        smile.lineWidth = 1.3
        smile.stroke()

        let sparkleAlpha = max(0.20, min(0.95, completionProgress))
        NSColor(calibratedRed: 0.42, green: 0.88, blue: 0.80, alpha: sparkleAlpha).setFill()
        NSBezierPath(ovalIn: NSRect(x: bodyRect.maxX - 3, y: bodyRect.maxY - 2, width: 8, height: 8)).fill()

        drawAccessory(in: bodyRect)

        let level = max(1, totalCoins / 120 + 1)
        let text = "Lv \(level)" as NSString
        text.draw(
            in: NSRect(x: bounds.midX - 22, y: 0, width: 44, height: 14),
            withAttributes: [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .semibold),
                .foregroundColor: NSColor.white.withAlphaComponent(0.66),
                .paragraphStyle: centeredParagraph()
            ]
        )
    }

    private func drawAccessory(in bodyRect: NSRect) {
        guard let equippedItemID else { return }
        switch equippedItemID {
        case "ribbon":
            NSColor(calibratedRed: 0.96, green: 0.38, blue: 0.60, alpha: 0.95).setFill()
            NSBezierPath(ovalIn: NSRect(x: bodyRect.midX - 13, y: bodyRect.maxY + 1, width: 12, height: 8)).fill()
            NSBezierPath(ovalIn: NSRect(x: bodyRect.midX + 1, y: bodyRect.maxY + 1, width: 12, height: 8)).fill()
            NSBezierPath(ovalIn: NSRect(x: bodyRect.midX - 3, y: bodyRect.maxY + 2, width: 6, height: 6)).fill()
        case "scarf":
            NSColor(calibratedRed: 0.42, green: 0.88, blue: 0.80, alpha: 0.94).setFill()
            NSBezierPath(roundedRect: NSRect(x: bodyRect.minX + 8, y: bodyRect.minY + 5, width: 20, height: 5), xRadius: 2.5, yRadius: 2.5).fill()
        case "star":
            let star = "*" as NSString
            star.draw(in: NSRect(x: bodyRect.midX - 6, y: bodyRect.minY + 2, width: 12, height: 12), withAttributes: [
                .font: NSFont.systemFont(ofSize: 11, weight: .bold),
                .foregroundColor: NSColor(calibratedRed: 0.98, green: 0.78, blue: 0.36, alpha: 0.96)
            ])
        case "crown":
            NSColor(calibratedRed: 0.98, green: 0.78, blue: 0.36, alpha: 0.96).setFill()
            let crown = NSBezierPath()
            crown.move(to: CGPoint(x: bodyRect.midX - 13, y: bodyRect.maxY + 1))
            crown.line(to: CGPoint(x: bodyRect.midX - 8, y: bodyRect.maxY + 12))
            crown.line(to: CGPoint(x: bodyRect.midX, y: bodyRect.maxY + 4))
            crown.line(to: CGPoint(x: bodyRect.midX + 8, y: bodyRect.maxY + 12))
            crown.line(to: CGPoint(x: bodyRect.midX + 13, y: bodyRect.maxY + 1))
            crown.close()
            crown.fill()
        default:
            break
        }
    }
}

final class DayCellView: NSView {
    var dateKey = ""
    var record = DayRecord()

    override func draw(_ dirtyRect: NSRect) {
        let progress = record.totalCount == 0 ? 0 : CGFloat(record.completedCount) / CGFloat(record.totalCount)
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 8, yRadius: 8)
        let color = NSColor(calibratedRed: 0.42, green: 0.88, blue: 0.80, alpha: 0.12 + 0.46 * progress)
        color.setFill()
        path.fill()
        NSColor.white.withAlphaComponent(0.12 + 0.20 * progress).setStroke()
        path.lineWidth = 0.8
        path.stroke()

        let day = String(dateKey.suffix(2)) as NSString
        day.draw(in: NSRect(x: 7, y: bounds.height - 19, width: bounds.width - 14, height: 14), withAttributes: [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: NSColor.white.withAlphaComponent(0.86)
        ])
        let summary = "\(record.completedCount)/\(record.totalCount)" as NSString
        summary.draw(in: NSRect(x: 7, y: 18, width: bounds.width - 14, height: 14), withAttributes: [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .medium),
            .foregroundColor: NSColor.white.withAlphaComponent(0.62)
        ])
        if record.coinsEarned > 0 {
            let coins = "+\(record.coinsEarned)" as NSString
            coins.draw(in: NSRect(x: 7, y: 5, width: bounds.width - 14, height: 12), withAttributes: [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 8.5, weight: .medium),
                .foregroundColor: NSColor(calibratedRed: 0.98, green: 0.78, blue: 0.36, alpha: 0.92)
            ])
        }
    }
}

final class ShopActionButton: NSButton {
    let itemID: String

    init(itemID: String, title: String, target: AnyObject?, action: Selector) {
        self.itemID = itemID
        super.init(frame: .zero)
        self.title = title
        self.target = target
        self.action = action
        bezelStyle = .rounded
        font = NSFont.systemFont(ofSize: 12, weight: .semibold)
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

func centeredParagraph() -> NSParagraphStyle {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    return paragraph
}

final class IconButton: NSButton {
    init(symbol: String, action: Selector, target: AnyObject?) {
        super.init(frame: .zero)
        self.target = target
        self.action = action
        bezelStyle = .regularSquare
        isBordered = false
        imagePosition = .imageOnly
        contentTintColor = NSColor.white.withAlphaComponent(0.72)
        if let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil) {
            self.image = image
        } else {
            title = symbol
            font = NSFont.systemFont(ofSize: 12, weight: .medium)
        }
        wantsLayer = true
        layer?.cornerRadius = 10
        layer?.backgroundColor = NSColor.white.withAlphaComponent(0.045).cgColor
        layer?.borderColor = NSColor.white.withAlphaComponent(0.08).cgColor
        layer?.borderWidth = 0.7
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class AddBarView: NSView {
    var onClick: (() -> Void)?

    override var wantsUpdateLayer: Bool { true }

    override func updateLayer() {
        layer?.cornerRadius = 17
        layer?.masksToBounds = false
        layer?.backgroundColor = NSColor(calibratedWhite: 0.035, alpha: 0.66).cgColor
        layer?.borderColor = NSColor.white.withAlphaComponent(0.13).cgColor
        layer?.borderWidth = 0.8
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 0.16
        layer?.shadowOffset = CGSize(width: 0, height: -5)
        layer?.shadowRadius = 16
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        onClick?()
    }
}

final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}

final class DeskWindow: NSWindow {
    var onInteraction: (() -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func sendEvent(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown, .rightMouseDown, .otherMouseDown, .keyDown:
            onInteraction?()
        default:
            break
        }
        super.sendEvent(event)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if handleTextEditingShortcut(event) {
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    private func handleTextEditingShortcut(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard flags.contains(.command),
              flags.subtracting([.command, .shift]).isEmpty,
              let key = event.charactersIgnoringModifiers?.lowercased(),
              let editor = activeTextEditor()
        else {
            return false
        }

        switch key {
        case "a": editor.selectAll(nil)
        case "c": editor.copy(nil)
        case "v": editor.paste(nil)
        case "x": editor.cut(nil)
        case "z":
            if flags.contains(.shift) {
                editor.undoManager?.redo()
            } else {
                editor.undoManager?.undo()
            }
        default:
            return false
        }
        return true
    }

    private func activeTextEditor() -> NSTextView? {
        if let editor = firstResponder as? NSTextView {
            return editor
        }
        return fieldEditor(false, for: nil) as? NSTextView
    }
}

final class FocusTextField: NSTextField {
    var onFocus: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        onFocus?()
        super.mouseDown(with: event)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard flags.contains(.command),
              flags.subtracting([.command, .shift]).isEmpty,
              let key = event.charactersIgnoringModifiers?.lowercased(),
              let editor = currentEditor() as? NSTextView
        else {
            return super.performKeyEquivalent(with: event)
        }

        switch key {
        case "a": editor.selectAll(nil)
        case "c": editor.copy(nil)
        case "v": editor.paste(nil)
        case "x": editor.cut(nil)
        default: return super.performKeyEquivalent(with: event)
        }
        return true
    }
}

final class PriorityOptionButton: NSButton {
    let priority: Priority

    init(priority: Priority) {
        self.priority = priority
        super.init(frame: .zero)
        isBordered = false
        imagePosition = .imageOnly
        toolTip = priority.tooltip
        wantsLayer = true
        layer?.cornerRadius = 9
        layer?.borderWidth = 0
        if let image = NSImage(systemSymbolName: priority.symbolName, accessibilityDescription: priority.tooltip) {
            self.image = image
        }
        update(selected: false)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    func update(selected: Bool) {
        contentTintColor = selected ? priority.accent : NSColor.white.withAlphaComponent(0.46)
        layer?.backgroundColor = selected ? priority.dimAccent.cgColor : NSColor.clear.cgColor
        layer?.borderColor = selected ? priority.accent.withAlphaComponent(0.30).cgColor : NSColor.clear.cgColor
        layer?.borderWidth = selected ? 0.8 : 0
    }
}

final class PriorityPickerView: NSView {
    var selectedPriority: Priority = .amber {
        didSet { updateButtons() }
    }

    private let priorities: [Priority] = [.red, .amber, .teal]
    private var buttons: [PriorityOptionButton] = []

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 13
        layer?.backgroundColor = NSColor.white.withAlphaComponent(0.045).cgColor
        layer?.borderColor = NSColor.white.withAlphaComponent(0.08).cgColor
        layer?.borderWidth = 0.7

        for priority in priorities {
            let button = PriorityOptionButton(priority: priority)
            button.target = self
            button.action = #selector(selectPriority(_:))
            buttons.append(button)
            addSubview(button)
        }
        updateButtons()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layout() {
        super.layout()
        let width = bounds.width / CGFloat(max(buttons.count, 1))
        for (idx, button) in buttons.enumerated() {
            button.frame = NSRect(
                x: CGFloat(idx) * width + 3,
                y: 3,
                width: width - 6,
                height: bounds.height - 6
            )
        }
    }

    @objc private func selectPriority(_ sender: PriorityOptionButton) {
        selectedPriority = sender.priority
    }

    private func updateButtons() {
        for button in buttons {
            button.update(selected: button.priority == selectedPriority)
        }
    }
}

final class TaskRowView: NSView {
    let taskID: String
    private let card = CardView()
    private let checkButton = NSButton()
    private let titleLabel = NSTextField(labelWithString: "")
    private let openButton: IconButton
    var onToggle: ((String) -> Void)?
    var onOpen: ((String) -> Void)?

    init(task: Task, showsOpenButton: Bool) {
        taskID = task.id
        openButton = IconButton(symbol: "arrow.up.right", action: #selector(openTapped), target: nil)
        super.init(frame: .zero)
        wantsLayer = true

        card.priority = task.priority
        card.completed = task.completed
        addSubview(card)

        checkButton.isBordered = false
        checkButton.imagePosition = .imageOnly
        checkButton.contentTintColor = task.completed ? NSColor(calibratedRed: 0.20, green: 0.88, blue: 0.68, alpha: 1) : NSColor.white.withAlphaComponent(0.58)
        checkButton.image = NSImage(systemSymbolName: task.completed ? "checkmark.circle.fill" : "circle", accessibilityDescription: nil)
        checkButton.target = self
        checkButton.action = #selector(toggleTapped)
        card.addSubview(checkButton)

        titleLabel.stringValue = task.title
        titleLabel.font = NSFont.systemFont(ofSize: 13.5, weight: .medium)
        titleLabel.textColor = task.completed ? NSColor.white.withAlphaComponent(0.36) : NSColor.white.withAlphaComponent(0.90)
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.maximumNumberOfLines = 1
        if task.completed {
            titleLabel.attributedStringValue = NSAttributedString(
                string: task.title,
                attributes: [
                    .font: titleLabel.font ?? NSFont.systemFont(ofSize: 13.5),
                    .foregroundColor: NSColor.white.withAlphaComponent(0.36),
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue
                ]
            )
        }
        card.addSubview(titleLabel)

        openButton.target = self
        openButton.action = #selector(openTapped)
        openButton.isHidden = !showsOpenButton
        card.addSubview(openButton)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layout() {
        super.layout()
        card.frame = bounds
        checkButton.frame = NSRect(x: 15, y: (bounds.height - 20) / 2, width: 20, height: 20)
        openButton.frame = NSRect(x: bounds.width - 36, y: (bounds.height - 24) / 2, width: 24, height: 24)
        let rightInset: CGFloat = openButton.isHidden ? 16 : 42
        titleLabel.frame = NSRect(x: 45, y: (bounds.height - 20) / 2 - 1, width: bounds.width - 45 - rightInset, height: 20)
    }

    @objc private func toggleTapped() {
        onToggle?(taskID)
    }

    @objc private func openTapped() {
        onOpen?(taskID)
    }
}
