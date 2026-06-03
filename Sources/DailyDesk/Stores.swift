import Foundation

func todayString(_ date: Date = Date()) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
}

func compactDateString(_ date: Date = Date()) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "M月d日 EEE"
    return formatter.string(from: date)
}

func weekday(_ date: Date = Date()) -> Int {
    var calendar = Calendar(identifier: .gregorian)
    calendar.firstWeekday = 2
    return calendar.component(.weekday, from: date) == 1 ? 7 : calendar.component(.weekday, from: date) - 1
}

func addingDays(_ days: Int, to date: Date = Date()) -> Date {
    Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: date) ?? date
}

func expandedPath(_ path: String) -> String {
    NSString(string: path).expandingTildeInPath
}

func displayPath(_ path: String) -> String {
    NSString(string: path).abbreviatingWithTildeInPath
}

func ensureSupportDirectory() {
    try? FileManager.default.createDirectory(at: supportDir, withIntermediateDirectories: true)
}

func loadConfig() -> AppConfig {
    guard let data = try? Data(contentsOf: configURL),
          let config = try? JSONDecoder().decode(AppConfig.self, from: data)
    else {
        saveConfig(.defaults)
        return .defaults
    }
    return config
}

func saveConfig(_ config: AppConfig) {
    ensureSupportDirectory()
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    if let data = try? encoder.encode(config) {
        try? data.write(to: configURL, options: .atomic)
    }
}

func loadState(defaultPinned: Bool = true) -> AppState {
    guard let data = try? Data(contentsOf: stateURL),
          var state = try? JSONDecoder().decode(AppState.self, from: data)
    else {
        return AppState(tasksByDate: [:], windowFrame: nil, pinned: defaultPinned)
    }
    if state.tasksByDate.isEmpty && state.windowFrame == nil {
        state.pinned = defaultPinned
    }
    return state
}

func saveState(_ state: AppState) {
    ensureSupportDirectory()
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    if let data = try? encoder.encode(state) {
        try? data.write(to: stateURL, options: .atomic)
    }
}

func baseSpecs(for date: Date = Date(), config: AppConfig) -> [TaskSpec] {
    let todayWeekday = weekday(date)
    let tomorrow = addingDays(1, to: date)
    let tomorrowWeekday = weekday(tomorrow)
    var specs: [TaskSpec] = []

    for template in config.templates where template.enabled {
        switch template.recurrence {
        case .daily:
            specs.append(TaskSpec(
                generatedKey: "template:\(template.id)",
                title: template.title,
                priority: template.priority
            ))
        case .weekly:
            if template.weekdays.contains(todayWeekday) {
                specs.append(TaskSpec(
                    generatedKey: "template:\(template.id)",
                    title: template.title,
                    priority: template.priority
                ))
            }
        case .prepBeforeWeekly:
            if template.weekdays.contains(tomorrowWeekday) {
                specs.append(TaskSpec(
                    generatedKey: "template:\(template.id):\(todayString(tomorrow))",
                    title: template.title,
                    priority: template.priority
                ))
            }
        }
    }

    return specs
}

@discardableResult
func generateDailyTasks(force: Bool = false, date: Date = Date(), config: AppConfig = loadConfig()) -> Int {
    var state = loadState(defaultPinned: config.defaultPinned)
    let key = todayString(date)
    var tasks = state.tasksByDate[key] ?? []
    let existing = Set(tasks.compactMap { $0.generatedKey })
    var added = 0

    for spec in baseSpecs(for: date, config: config) {
        if !force && existing.contains(spec.generatedKey) { continue }
        if force, let idx = tasks.firstIndex(where: { $0.generatedKey == spec.generatedKey }) {
            tasks[idx].title = spec.title
            tasks[idx].priority = spec.priority
            continue
        }
        tasks.append(Task(
            id: UUID().uuidString,
            title: spec.title,
            priority: spec.priority,
            completed: false,
            generatedKey: spec.generatedKey,
            createdAt: Date().timeIntervalSince1970
        ))
        added += 1
    }

    state.tasksByDate[key] = tasks
    saveState(state)
    return added
}

