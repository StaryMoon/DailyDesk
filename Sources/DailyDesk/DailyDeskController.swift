import AppKit

final class DailyDeskController: NSObject, NSApplicationDelegate {
    private var window: DeskWindow!
    private let root = GlassView()
    private let visual = NSVisualEffectView()
    private let header = NSTextField(labelWithString: "Daily Desk")
    private let dateLabel = NSTextField(labelWithString: "")
    private let ring = RingView()
    private let progressLabel = NSTextField(labelWithString: "")
    private let scrollView = NSScrollView()
    private let scrollDocument = FlippedView()
    private let stack = NSStackView()
    private let addBar = AddBarView()
    private let input = FocusTextField()
    private let priorityPicker = PriorityPickerView()
    private var state = AppState()
    private var config = AppConfig.defaults
    private var currentDateKey = todayString()
    private var settingsWindowController: SettingsWindowController?
    private var appearanceTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        installMenus()
        ensureSupportDirectory()
        config = loadConfig()
        _ = generateDailyTasks(config: config)
        state = loadState(defaultPinned: config.defaultPinned)
        currentDateKey = todayString()
        buildWindow()
        rebuild()
        scheduleNextAppearance()
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if let window = window {
            state.windowFrame = NSStringFromRect(window.frame)
        }
        saveState(state)
        return .terminateNow
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        config = loadConfig()
        _ = generateDailyTasks(config: config)
        state = loadState(defaultPinned: config.defaultPinned)
        rebuild()
        applyPinState(bringToFront: true)
        return true
    }

    func applicationDidResignActive(_ notification: Notification) {
        guard window != nil, !state.pinned else { return }
        parkOnDesktop()
    }

    func applicationDidChangeScreenParameters(_ notification: Notification) {
        layoutRoot()
    }

    private func buildWindow() {
        let defaultFrame = NSRect(x: 42, y: 520, width: 390, height: 430)
        let frame = state.windowFrame.map { NSRectFromString($0) } ?? defaultFrame
        window = DeskWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.title = "DailyDesk"
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.isMovableByWindowBackground = true
        window.onInteraction = { [weak self] in self?.wakeForInteraction() }
        window.contentView = root
        applyPinState(bringToFront: false)
        if state.pinned {
            window.orderFrontRegardless()
        } else {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        }

        root.wantsLayer = true
        visual.material = .hudWindow
        visual.blendingMode = .behindWindow
        visual.state = .active
        visual.alphaValue = 0.26
        visual.wantsLayer = true
        visual.layer?.cornerRadius = 24
        visual.layer?.masksToBounds = true
        root.addSubview(visual)

        header.stringValue = "Today"
        header.font = NSFont.systemFont(ofSize: 22, weight: .semibold)
        header.textColor = NSColor.white.withAlphaComponent(0.92)
        root.addSubview(header)

        dateLabel.stringValue = compactDateString()
        dateLabel.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        dateLabel.textColor = NSColor.white.withAlphaComponent(0.54)
        dateLabel.alignment = .right
        root.addSubview(dateLabel)

        root.addSubview(ring)
        progressLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 10.5, weight: .medium)
        progressLabel.textColor = NSColor.white.withAlphaComponent(0.66)
        progressLabel.alignment = .center
        root.addSubview(progressLabel)

        let close = IconButton(symbol: "xmark", action: #selector(closeTapped), target: self)
        close.identifier = NSUserInterfaceItemIdentifier("close")
        root.addSubview(close)
        let pin = IconButton(symbol: state.pinned ? "pin.fill" : "pin", action: #selector(pinTapped), target: self)
        pin.identifier = NSUserInterfaceItemIdentifier("pin")
        root.addSubview(pin)
        let refresh = IconButton(symbol: "arrow.triangle.2.circlepath", action: #selector(refreshTapped), target: self)
        refresh.identifier = NSUserInterfaceItemIdentifier("refresh")
        root.addSubview(refresh)
        let settings = IconButton(symbol: "gearshape", action: #selector(settingsTapped), target: self)
        settings.identifier = NSUserInterfaceItemIdentifier("settings")
        root.addSubview(settings)

        stack.orientation = .vertical
        stack.spacing = taskStackSpacing
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = true
        scrollDocument.addSubview(stack)
        scrollView.documentView = scrollDocument
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        root.addSubview(scrollView)

        addBar.onClick = { [weak self] in self?.focusInput() }
        root.addSubview(addBar)

        input.placeholderString = "添加今天的事"
        input.placeholderAttributedString = NSAttributedString(
            string: "添加今天的事",
            attributes: [.foregroundColor: NSColor.white.withAlphaComponent(0.34)]
        )
        input.font = NSFont.systemFont(ofSize: 13.5, weight: .regular)
        input.textColor = NSColor.white.withAlphaComponent(0.90)
        input.backgroundColor = .clear
        input.drawsBackground = false
        input.isBordered = false
        input.isEditable = true
        input.isSelectable = true
        input.focusRingType = .none
        input.target = self
        input.action = #selector(addFromInput)
        input.onFocus = { [weak self] in self?.focusInput() }
        input.menu = editContextMenu()
        root.addSubview(input)

        priorityPicker.selectedPriority = .amber
        root.addSubview(priorityPicker)

        let add = IconButton(symbol: "plus", action: #selector(addFromInput), target: self)
        add.identifier = NSUserInterfaceItemIdentifier("add")
        add.contentTintColor = NSColor(calibratedRed: 0.42, green: 0.88, blue: 0.80, alpha: 0.95)
        root.addSubview(add)
    }

    private func installMenus() {
        let mainMenu = NSMenu()

        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu(title: appName)
        appItem.submenu = appMenu
        appMenu.addItem(withTitle: "Preferences...", action: #selector(settingsTapped), keyEquivalent: ",")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit DailyDesk", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        let editItem = NSMenuItem()
        mainMenu.addItem(editItem)
        let editMenu = NSMenu(title: "Edit")
        editItem.submenu = editMenu
        addEditItems(to: editMenu)

        NSApp.mainMenu = mainMenu
    }

    private func editContextMenu() -> NSMenu {
        let menu = NSMenu(title: "Edit")
        addEditItems(to: menu)
        return menu
    }

    private func addEditItems(to menu: NSMenu) {
        menu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        let redo = NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(redo)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        menu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        menu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
    }

    private func tasks() -> [Task] {
        state.tasksByDate[currentDateKey] ?? []
    }

    private func setTasks(_ tasks: [Task]) {
        state.tasksByDate[currentDateKey] = tasks
        saveState(state)
    }

    private func rebuild() {
        state = loadState(defaultPinned: config.defaultPinned)
        currentDateKey = todayString()
        let ordered = tasks().sorted {
            if $0.completed != $1.completed { return !$0.completed }
            let rank: [Priority: Int] = [.red: 0, .amber: 1, .teal: 2]
            return (rank[$0.priority] ?? 3, $0.createdAt) < (rank[$1.priority] ?? 3, $1.createdAt)
        }

        stack.arrangedSubviews.forEach { view in
            stack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        for task in ordered {
            let row = TaskRowView(task: task, showsOpenButton: openURL(for: task) != nil)
            row.onToggle = { [weak self] id in self?.toggle(id) }
            row.onOpen = { [weak self] id in self?.openTask(id) }
            row.heightAnchor.constraint(equalToConstant: taskRowHeight).isActive = true
            stack.addArrangedSubview(row)
        }

        let done = ordered.filter { $0.completed }.count
        let total = max(ordered.count, 1)
        ring.progress = CGFloat(done) / CGFloat(total)
        progressLabel.stringValue = "\(done)/\(ordered.count)"
        dateLabel.stringValue = compactDateString()
        adjustWindowHeight(forTaskCount: ordered.count)
        layoutRoot()
    }

    private func taskListHeight(for count: Int) -> CGFloat {
        let rows = max(count, 1)
        return CGFloat(rows) * taskRowHeight + CGFloat(max(rows - 1, 0)) * taskStackSpacing
    }

    private func desiredWindowHeight(forTaskCount count: Int) -> CGFloat {
        max(minWindowHeight, taskListChromeHeight + taskListHeight(for: count))
    }

    private func adjustWindowHeight(forTaskCount count: Int) {
        guard let screen = window.screen ?? NSScreen.main else { return }
        let visible = screen.visibleFrame
        let maxHeight = max(minWindowHeight, visible.height - 32)
        let desiredHeight = min(desiredWindowHeight(forTaskCount: count), maxHeight)
        var frame = window.frame
        guard abs(frame.height - desiredHeight) > 1 else { return }

        let top = min(frame.maxY, visible.maxY - 12)
        frame.size.height = desiredHeight
        frame.origin.y = max(visible.minY + 12, top - desiredHeight)
        frame.origin.x = min(max(frame.origin.x, visible.minX + 12), visible.maxX - frame.width - 12)
        window.setFrame(frame, display: false, animate: false)
    }

    private func scheduleNextAppearance() {
        appearanceTimer?.invalidate()
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = max(0, min(23, config.dailyHour))
        components.minute = max(0, min(59, config.dailyMinute))
        components.second = 0
        var next = Calendar.current.date(from: components) ?? Date().addingTimeInterval(60 * 60)
        if next <= Date() {
            next = Calendar.current.date(byAdding: .day, value: 1, to: next) ?? Date().addingTimeInterval(24 * 60 * 60)
        }
        appearanceTimer = Timer(fireAt: next, interval: 0, target: self, selector: #selector(dailyAppearanceTimerFired), userInfo: nil, repeats: false)
        if let appearanceTimer {
            RunLoop.main.add(appearanceTimer, forMode: .common)
        }
    }

    @objc private func dailyAppearanceTimerFired() {
        _ = generateDailyTasks(force: false, config: config)
        state = loadState(defaultPinned: config.defaultPinned)
        rebuild()
        applyPinState(bringToFront: true)
        scheduleNextAppearance()
    }

    private func layoutRoot() {
        guard let content = window.contentView else { return }
        let bounds = content.bounds
        visual.frame = bounds
        let inset: CGFloat = 18
        header.frame = NSRect(x: inset, y: bounds.height - 49, width: 130, height: 30)
        dateLabel.frame = NSRect(x: bounds.width - 178, y: bounds.height - 43, width: 110, height: 22)
        ring.frame = NSRect(x: bounds.width - 62, y: bounds.height - 57, width: 40, height: 40)
        progressLabel.frame = ring.frame.insetBy(dx: 6, dy: 12)

        for view in root.subviews {
            guard let id = view.identifier?.rawValue else { continue }
            switch id {
            case "close": view.frame = NSRect(x: bounds.width - 34, y: bounds.height - 104, width: 24, height: 24)
            case "pin": view.frame = NSRect(x: bounds.width - 34, y: bounds.height - 134, width: 24, height: 24)
            case "refresh": view.frame = NSRect(x: bounds.width - 34, y: bounds.height - 164, width: 24, height: 24)
            case "settings": view.frame = NSRect(x: bounds.width - 34, y: bounds.height - 194, width: 24, height: 24)
            case "add": view.frame = NSRect(x: bounds.width - 47, y: 22, width: 28, height: 28)
            default: break
            }
        }

        addBar.frame = NSRect(x: inset, y: 16, width: bounds.width - inset * 2, height: 40)
        input.frame = NSRect(x: inset + 14, y: 25, width: bounds.width - 180, height: 22)
        priorityPicker.frame = NSRect(x: bounds.width - 136, y: 22, width: 86, height: 28)
        let taskArea = NSRect(x: inset, y: 70, width: bounds.width - 54, height: max(0, bounds.height - taskListChromeHeight))
        let contentHeight = taskListHeight(for: stack.arrangedSubviews.count)
        let documentHeight = max(taskArea.height, contentHeight)
        scrollView.frame = taskArea
        scrollDocument.frame = NSRect(x: 0, y: 0, width: taskArea.width, height: documentHeight)
        stack.frame = NSRect(x: 0, y: 0, width: taskArea.width, height: contentHeight)
        scrollView.contentView.scroll(to: .zero)
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }

    private func focusInput() {
        wakeForInteraction()
        window.makeFirstResponder(input)
        if let editor = window.fieldEditor(true, for: input) as? NSTextView {
            editor.selectedRange = NSRange(location: input.stringValue.utf16.count, length: 0)
        }
    }

    private func wakeForInteraction() {
        if !state.pinned {
            window.level = .normal
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    @objc private func addFromInput() {
        let title = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let priority = priorityPicker.selectedPriority
        var newTasks = tasks()
        newTasks.append(Task(id: UUID().uuidString, title: title, priority: priority, completed: false, generatedKey: nil, createdAt: Date().timeIntervalSince1970))
        setTasks(newTasks)
        input.stringValue = ""
        rebuild()
        focusInput()
    }

    private func toggle(_ id: String) {
        var newTasks = tasks()
        guard let idx = newTasks.firstIndex(where: { $0.id == id }) else { return }
        newTasks[idx].completed.toggle()
        setTasks(newTasks)
        rebuild()
    }

    private func openTask(_ id: String) {
        guard let task = tasks().first(where: { $0.id == id }),
              let url = openURL(for: task)
        else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private func openURL(for task: Task) -> URL? {
        let template = template(for: task)
        let action = template?.openAction ?? fallbackAction(for: task.title)
        let target = template?.customTarget ?? ""
        switch action {
        case .none:
            return nil
        case .aiBriefing:
            return URL(fileURLWithPath: expandedPath(config.links.aiBriefingPath))
        case .bilibiliMath:
            return URL(string: config.links.bilibiliMathURL)
        case .bilibiliEnglish:
            return URL(string: config.links.bilibiliEnglishURL)
        case .github:
            return URL(string: config.links.githubURL)
        case .customURL:
            return URL(string: target)
        case .filePath:
            return URL(fileURLWithPath: expandedPath(target))
        }
    }

    private func template(for task: Task) -> TaskTemplate? {
        guard let key = task.generatedKey else { return nil }
        return config.templates.first { key.contains($0.id) }
    }

    private func fallbackAction(for title: String) -> OpenAction {
        if title.contains("AI 技术日报") { return .aiBriefing }
        if title.contains("GitHub") { return .github }
        if title.contains("英语") { return .bilibiliEnglish }
        if title.contains("B站") { return .bilibiliMath }
        return .none
    }

    @objc private func closeTapped() {
        state.windowFrame = NSStringFromRect(window.frame)
        saveState(state)
        NSApp.terminate(nil)
    }

    @objc private func pinTapped() {
        state.pinned.toggle()
        saveState(state)
        applyPinState(bringToFront: true)
        rebuildIconButtons()
    }

    @objc private func settingsTapped() {
        wakeForInteraction()
        let controller = SettingsWindowController(config: config) { [weak self] newConfig in
            guard let self else { return }
            self.config = newConfig
            saveConfig(newConfig)
            self.state.pinned = newConfig.defaultPinned
            saveState(self.state)
            _ = generateDailyTasks(force: true, config: newConfig)
            self.applyPinState(bringToFront: true)
            self.rebuildIconButtons()
            self.rebuild()
            self.scheduleNextAppearance()
        }
        settingsWindowController = controller
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
    }

    private func applyPinState(bringToFront: Bool) {
        window.level = state.pinned ? .floating : .normal
        window.hidesOnDeactivate = false
        window.collectionBehavior = state.pinned
            ? [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            : [.canJoinAllSpaces, .fullScreenAuxiliary]
        if bringToFront {
            if state.pinned {
                window.orderFrontRegardless()
            } else {
                NSApp.activate(ignoringOtherApps: true)
                window.makeKeyAndOrderFront(nil)
            }
        }
    }

    private func parkOnDesktop() {
        window.level = desktopParkingLevel
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.orderFront(nil)
    }

    private func rebuildIconButtons() {
        for view in root.subviews where view.identifier?.rawValue == "pin" {
            if let button = view as? NSButton {
                button.image = NSImage(systemSymbolName: state.pinned ? "pin.fill" : "pin", accessibilityDescription: nil)
            }
        }
    }

    @objc private func refreshTapped() {
        _ = generateDailyTasks(force: false, config: config)
        rebuild()
    }
}
