import AppKit
import CoreGraphics
import Foundation

let appName = "DailyDesk"
let appID = "com.liuminghao.dailydesk"
let appHomeDirectory = ProcessInfo.processInfo.environment["DAILYDESK_HOME"]
    .map { URL(fileURLWithPath: $0, isDirectory: true) }
    ?? FileManager.default.homeDirectoryForCurrentUser
let supportDir = appHomeDirectory
    .appendingPathComponent("Library/Application Support/DailyDesk")
let stateURL = supportDir.appendingPathComponent("state.json")
let configURL = supportDir.appendingPathComponent("config.json")
let desktopParkingLevel = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)))
let taskRowHeight: CGFloat = 48
let taskStackSpacing: CGFloat = 8
let minWindowHeight: CGFloat = 430
let taskListChromeHeight: CGFloat = 132

enum Priority: String, Codable, CaseIterable {
    case red
    case amber
    case teal

    var accent: NSColor {
        switch self {
        case .red: return NSColor(calibratedRed: 0.96, green: 0.38, blue: 0.43, alpha: 1)
        case .amber: return NSColor(calibratedRed: 0.96, green: 0.72, blue: 0.43, alpha: 1)
        case .teal: return NSColor(calibratedRed: 0.42, green: 0.88, blue: 0.80, alpha: 1)
        }
    }

    var dimAccent: NSColor {
        accent.withAlphaComponent(0.18)
    }

    var symbolName: String {
        switch self {
        case .red: return "flame.fill"
        case .amber: return "diamond.fill"
        case .teal: return "sparkles"
        }
    }

    var tooltip: String {
        switch self {
        case .red: return "紧急"
        case .amber: return "重要"
        case .teal: return "轻量"
        }
    }

    var settingsName: String {
        switch self {
        case .red: return "urgent"
        case .amber: return "important"
        case .teal: return "light"
        }
    }

    static func fromSettingsName(_ value: String) -> Priority {
        switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "red", "urgent", "紧急": return .red
        case "teal", "light", "轻量": return .teal
        default: return .amber
        }
    }
}

enum RecurrenceKind: String, Codable, CaseIterable {
    case daily
    case weekly
    case prepBeforeWeekly

    var settingsName: String {
        switch self {
        case .daily: return "daily"
        case .weekly: return "weekly"
        case .prepBeforeWeekly: return "prep-before-weekly"
        }
    }

    static func fromSettingsName(_ value: String) -> RecurrenceKind {
        switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "weekly", "week", "每周": return .weekly
        case "prep", "prep-before-weekly", "before-weekly", "前一天": return .prepBeforeWeekly
        default: return .daily
        }
    }
}

enum OpenAction: String, Codable, CaseIterable {
    case none
    case aiBriefing
    case bilibiliMath
    case bilibiliEnglish
    case github
    case customURL
    case filePath

    var settingsName: String {
        switch self {
        case .none: return "none"
        case .aiBriefing: return "ai-briefing"
        case .bilibiliMath: return "bilibili-math"
        case .bilibiliEnglish: return "bilibili-english"
        case .github: return "github"
        case .customURL: return "custom-url"
        case .filePath: return "file-path"
        }
    }

    static func fromSettingsName(_ value: String) -> OpenAction {
        switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "ai", "briefing", "ai-briefing": return .aiBriefing
        case "bilibili", "bilibili-math", "math": return .bilibiliMath
        case "bilibili-english", "english": return .bilibiliEnglish
        case "github": return .github
        case "url", "custom-url", "link": return .customURL
        case "file", "file-path", "path": return .filePath
        default: return .none
        }
    }
}

struct Task: Codable, Equatable {
    var id: String
    var title: String
    var priority: Priority
    var completed: Bool
    var generatedKey: String?
    var createdAt: TimeInterval
}

struct AppState: Codable {
    var tasksByDate: [String: [Task]] = [:]
    var windowFrame: String?
    var pinned: Bool = true
}

struct QuickLinks: Codable, Equatable {
    var aiBriefingPath: String
    var bilibiliMathURL: String
    var bilibiliEnglishURL: String
    var githubURL: String

    static let defaults = QuickLinks(
        aiBriefingPath: "~/Downloads/AI_Researcher_Daily_Briefing.md",
        bilibiliMathURL: "https://www.bilibili.com",
        bilibiliEnglishURL: "https://www.bilibili.com",
        githubURL: "https://github.com"
    )
}

struct TaskTemplate: Codable, Equatable {
    var id: String
    var title: String
    var priority: Priority
    var recurrence: RecurrenceKind
    var weekdays: [Int]
    var openAction: OpenAction
    var customTarget: String
    var enabled: Bool

    static func makeID(title: String, recurrence: RecurrenceKind) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let normalized = title
            .lowercased()
            .unicodeScalars
            .map { allowed.contains($0) ? Character($0) : "-" }
        let collapsed = String(normalized)
            .split(separator: "-")
            .joined(separator: "-")
        return "\(recurrence.rawValue)-\(collapsed.isEmpty ? UUID().uuidString : collapsed)"
    }
}

struct AppConfig: Codable, Equatable {
    var dailyHour: Int
    var dailyMinute: Int
    var defaultPinned: Bool
    var templates: [TaskTemplate]
    var links: QuickLinks

    static let defaults = AppConfig(
        dailyHour: 8,
        dailyMinute: 0,
        defaultPinned: true,
        templates: [
            TaskTemplate(
                id: "daily-research",
                title: "科研 3h",
                priority: .red,
                recurrence: .daily,
                weekdays: [],
                openAction: .none,
                customTarget: "",
                enabled: true
            ),
            TaskTemplate(
                id: "daily-briefing",
                title: "AI 技术日报",
                priority: .amber,
                recurrence: .daily,
                weekdays: [],
                openAction: .aiBriefing,
                customTarget: "",
                enabled: true
            ),
            TaskTemplate(
                id: "daily-math",
                title: "B站 物理/数学课 20min",
                priority: .teal,
                recurrence: .daily,
                weekdays: [],
                openAction: .bilibiliMath,
                customTarget: "",
                enabled: true
            ),
            TaskTemplate(
                id: "daily-english",
                title: "B站 英语实景对话 20min",
                priority: .teal,
                recurrence: .daily,
                weekdays: [],
                openAction: .bilibiliEnglish,
                customTarget: "",
                enabled: true
            ),
            TaskTemplate(
                id: "daily-github",
                title: "GitHub PR / 项目宣传",
                priority: .amber,
                recurrence: .daily,
                weekdays: [],
                openAction: .github,
                customTarget: "",
                enabled: true
            ),
            TaskTemplate(
                id: "weekly-tutoring",
                title: "家教",
                priority: .red,
                recurrence: .weekly,
                weekdays: [1, 6, 7],
                openAction: .none,
                customTarget: "",
                enabled: true
            ),
            TaskTemplate(
                id: "weekly-tutoring-prep",
                title: "家教备课",
                priority: .amber,
                recurrence: .prepBeforeWeekly,
                weekdays: [1, 6, 7],
                openAction: .none,
                customTarget: "",
                enabled: true
            )
        ],
        links: .defaults
    )
}

struct TaskSpec {
    var generatedKey: String
    var title: String
    var priority: Priority
}
