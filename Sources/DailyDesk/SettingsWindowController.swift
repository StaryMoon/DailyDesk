import AppKit

final class SettingsWindowController: NSWindowController {
    private var config: AppConfig
    private let onSave: (AppConfig) -> Void

    private let hourField = NSTextField()
    private let minuteField = NSTextField()
    private let pinnedCheckbox = NSButton(checkboxWithTitle: "Open pinned above other windows", target: nil, action: nil)
    private let briefingField = NSTextField()
    private let mathURLField = NSTextField()
    private let englishURLField = NSTextField()
    private let githubURLField = NSTextField()
    private let templatesText = NSTextView()
    private let messageLabel = NSTextField(labelWithString: "")

    init(config: AppConfig, onSave: @escaping (AppConfig) -> Void) {
        self.config = config
        self.onSave = onSave
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 700),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "DailyDesk Settings"
        window.center()
        super.init(window: window)
        build()
        loadValues()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build() {
        guard let content = window?.contentView else { return }
        content.wantsLayer = true
        content.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        let scroll = NSScrollView(frame: content.bounds)
        scroll.autoresizingMask = [.width, .height]
        scroll.hasVerticalScroller = true
        content.addSubview(scroll)

        let stack = NSStackView(frame: NSRect(x: 0, y: 0, width: content.bounds.width - 28, height: 900))
        stack.orientation = .vertical
        stack.spacing = 14
        stack.edgeInsets = NSEdgeInsets(top: 22, left: 24, bottom: 24, right: 24)
        scroll.documentView = stack

        stack.addArrangedSubview(titleLabel("DailyDesk Settings"))
        stack.addArrangedSubview(descriptionLabel("Configure daily task templates, repeat rules, appearance time, pin behavior, and quick open targets. Settings are stored locally in ~/Library/Application Support/DailyDesk/config.json."))

        stack.addArrangedSubview(sectionLabel("Daily appearance"))
        let timeRow = NSStackView()
        timeRow.orientation = .horizontal
        timeRow.spacing = 8
        timeRow.addArrangedSubview(label("Hour"))
        hourField.frame.size.width = 50
        timeRow.addArrangedSubview(hourField)
        timeRow.addArrangedSubview(label("Minute"))
        minuteField.frame.size.width = 50
        timeRow.addArrangedSubview(minuteField)
        timeRow.addArrangedSubview(pinnedCheckbox)
        stack.addArrangedSubview(timeRow)

        stack.addArrangedSubview(sectionLabel("Quick open targets"))
        stack.addArrangedSubview(formRow("AI briefing file", field: briefingField, buttonTitle: "Choose...", action: #selector(chooseBriefingFile)))
        stack.addArrangedSubview(formRow("Bilibili math URL", field: mathURLField))
        stack.addArrangedSubview(formRow("Bilibili English URL", field: englishURLField))
        stack.addArrangedSubview(formRow("GitHub URL", field: githubURLField))

        stack.addArrangedSubview(sectionLabel("Task templates"))
        stack.addArrangedSubview(descriptionLabel("""
One task per line:
title | priority | recurrence | weekdays | open action | optional target

priority: urgent, important, light
recurrence: daily, weekly, prep-before-weekly
weekdays: 1=Mon ... 7=Sun, for example 1,6,7
open action: none, ai-briefing, bilibili-math, bilibili-english, github, custom-url, file-path
"""))

        let textScroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: 620, height: 250))
        textScroll.hasVerticalScroller = true
        templatesText.minSize = NSSize(width: 0, height: 250)
        templatesText.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        templatesText.isVerticallyResizable = true
        templatesText.isHorizontallyResizable = false
        templatesText.autoresizingMask = [.width]
        templatesText.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textScroll.documentView = templatesText
        stack.addArrangedSubview(textScroll)

        messageLabel.textColor = .secondaryLabelColor
        stack.addArrangedSubview(messageLabel)

        let buttons = NSStackView()
        buttons.orientation = .horizontal
        buttons.spacing = 10
        buttons.alignment = .trailing
        let reset = NSButton(title: "Reset Defaults", target: self, action: #selector(resetDefaults))
        let save = NSButton(title: "Save Settings", target: self, action: #selector(saveTapped))
        save.keyEquivalent = "\r"
        buttons.addArrangedSubview(reset)
        buttons.addArrangedSubview(save)
        stack.addArrangedSubview(buttons)
    }

    private func loadValues() {
        hourField.stringValue = "\(config.dailyHour)"
        minuteField.stringValue = String(format: "%02d", config.dailyMinute)
        pinnedCheckbox.state = config.defaultPinned ? .on : .off
        briefingField.stringValue = config.links.aiBriefingPath
        mathURLField.stringValue = config.links.bilibiliMathURL
        englishURLField.stringValue = config.links.bilibiliEnglishURL
        githubURLField.stringValue = config.links.githubURL
        templatesText.string = encodeTemplates(config.templates)
    }

    @objc private func chooseBriefingFile() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.beginSheetModal(for: window!) { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.briefingField.stringValue = displayPath(url.path)
        }
    }

    @objc private func resetDefaults() {
        config = .defaults
        loadValues()
        messageLabel.stringValue = "Defaults loaded. Click Save Settings to apply."
    }

    @objc private func saveTapped() {
        do {
            let templates = try decodeTemplates(templatesText.string)
            let hour = max(0, min(23, Int(hourField.stringValue) ?? 8))
            let minute = max(0, min(59, Int(minuteField.stringValue) ?? 0))
            let next = AppConfig(
                dailyHour: hour,
                dailyMinute: minute,
                defaultPinned: pinnedCheckbox.state == .on,
                templates: templates,
                links: QuickLinks(
                    aiBriefingPath: briefingField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
                    bilibiliMathURL: mathURLField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
                    bilibiliEnglishURL: englishURLField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
                    githubURL: githubURLField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            )
            config = next
            onSave(next)
            messageLabel.textColor = .secondaryLabelColor
            messageLabel.stringValue = "Saved. Today's generated tasks were refreshed without deleting manual tasks."
        } catch {
            messageLabel.textColor = .systemRed
            messageLabel.stringValue = error.localizedDescription
        }
    }

    private func encodeTemplates(_ templates: [TaskTemplate]) -> String {
        templates.map { template in
            let weekdays = template.weekdays.map(String.init).joined(separator: ",")
            return [
                template.title,
                template.priority.settingsName,
                template.recurrence.settingsName,
                weekdays,
                template.openAction.settingsName,
                template.customTarget
            ].joined(separator: " | ")
        }.joined(separator: "\n")
    }

    private func decodeTemplates(_ text: String) throws -> [TaskTemplate] {
        let lines = text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }

        return try lines.enumerated().map { idx, line in
            let parts = line.split(separator: "|", omittingEmptySubsequences: false)
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            guard parts.count >= 3, !parts[0].isEmpty else {
                throw NSError(domain: appID, code: 1, userInfo: [NSLocalizedDescriptionKey: "Line \(idx + 1) is invalid. Expected: title | priority | recurrence | weekdays | open action | target"])
            }
            let title = parts[0]
            let priority = Priority.fromSettingsName(parts[1])
            let recurrence = RecurrenceKind.fromSettingsName(parts[2])
            let weekdays = parts.count > 3
                ? parts[3].split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }.filter { (1...7).contains($0) }
                : []
            let action = parts.count > 4 ? OpenAction.fromSettingsName(parts[4]) : .none
            let target = parts.count > 5 ? parts[5] : ""
            return TaskTemplate(
                id: TaskTemplate.makeID(title: title, recurrence: recurrence),
                title: title,
                priority: priority,
                recurrence: recurrence,
                weekdays: weekdays,
                openAction: action,
                customTarget: target,
                enabled: true
            )
        }
    }

    private func titleLabel(_ text: String) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = NSFont.systemFont(ofSize: 22, weight: .semibold)
        return field
    }

    private func sectionLabel(_ text: String) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        return field
    }

    private func descriptionLabel(_ text: String) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        field.textColor = .secondaryLabelColor
        field.lineBreakMode = .byWordWrapping
        field.maximumNumberOfLines = 0
        return field
    }

    private func label(_ text: String) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        return field
    }

    private func formRow(_ title: String, field: NSTextField, buttonTitle: String? = nil, action: Selector? = nil) -> NSStackView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing = 8
        let titleLabel = label(title)
        titleLabel.frame.size.width = 130
        row.addArrangedSubview(titleLabel)
        field.frame.size.width = 390
        row.addArrangedSubview(field)
        if let buttonTitle, let action {
            row.addArrangedSubview(NSButton(title: buttonTitle, target: self, action: action))
        }
        return row
    }
}

