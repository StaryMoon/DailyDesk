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
let taskListChromeHeight: CGFloat = 154

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

struct DayRecord: Codable, Equatable {
    var completedCount: Int
    var totalCount: Int
    var coinsEarned: Int
    var awardedTaskIDs: [String]
    var lastUpdated: TimeInterval

    init(
        completedCount: Int = 0,
        totalCount: Int = 0,
        coinsEarned: Int = 0,
        awardedTaskIDs: [String] = [],
        lastUpdated: TimeInterval = 0
    ) {
        self.completedCount = completedCount
        self.totalCount = totalCount
        self.coinsEarned = coinsEarned
        self.awardedTaskIDs = awardedTaskIDs
        self.lastUpdated = lastUpdated
    }

    private enum CodingKeys: String, CodingKey {
        case completedCount
        case totalCount
        case coinsEarned
        case awardedTaskIDs
        case lastUpdated
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        completedCount = try container.decodeIfPresent(Int.self, forKey: .completedCount) ?? 0
        totalCount = try container.decodeIfPresent(Int.self, forKey: .totalCount) ?? 0
        coinsEarned = try container.decodeIfPresent(Int.self, forKey: .coinsEarned) ?? 0
        awardedTaskIDs = try container.decodeIfPresent([String].self, forKey: .awardedTaskIDs) ?? []
        lastUpdated = try container.decodeIfPresent(TimeInterval.self, forKey: .lastUpdated) ?? 0
    }
}

struct AppState: Codable {
    var tasksByDate: [String: [Task]] = [:]
    var windowFrame: String?
    var pinned: Bool = true
    var dailyRecords: [String: DayRecord] = [:]
    var coinBalance: Int = 0
    var totalCoinsEarned: Int = 0
    var ownedShopItemIDs: [String] = []
    var equippedShopItemID: String?

    init(
        tasksByDate: [String: [Task]] = [:],
        windowFrame: String? = nil,
        pinned: Bool = true,
        dailyRecords: [String: DayRecord] = [:],
        coinBalance: Int = 0,
        totalCoinsEarned: Int = 0,
        ownedShopItemIDs: [String] = [],
        equippedShopItemID: String? = nil
    ) {
        self.tasksByDate = tasksByDate
        self.windowFrame = windowFrame
        self.pinned = pinned
        self.dailyRecords = dailyRecords
        self.coinBalance = coinBalance
        self.totalCoinsEarned = totalCoinsEarned
        self.ownedShopItemIDs = ownedShopItemIDs
        self.equippedShopItemID = equippedShopItemID
    }

    private enum CodingKeys: String, CodingKey {
        case tasksByDate
        case windowFrame
        case pinned
        case dailyRecords
        case coinBalance
        case totalCoinsEarned
        case ownedShopItemIDs
        case equippedShopItemID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tasksByDate = try container.decodeIfPresent([String: [Task]].self, forKey: .tasksByDate) ?? [:]
        windowFrame = try container.decodeIfPresent(String.self, forKey: .windowFrame)
        pinned = try container.decodeIfPresent(Bool.self, forKey: .pinned) ?? true
        dailyRecords = try container.decodeIfPresent([String: DayRecord].self, forKey: .dailyRecords) ?? [:]
        coinBalance = try container.decodeIfPresent(Int.self, forKey: .coinBalance) ?? 0
        totalCoinsEarned = try container.decodeIfPresent(Int.self, forKey: .totalCoinsEarned) ?? 0
        ownedShopItemIDs = try container.decodeIfPresent([String].self, forKey: .ownedShopItemIDs) ?? []
        equippedShopItemID = try container.decodeIfPresent(String.self, forKey: .equippedShopItemID)
    }
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
                id: "daily-fitness",
                title: "健身",
                priority: .teal,
                recurrence: .daily,
                weekdays: [],
                openAction: .none,
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

struct ShopItem {
    let id: String
    let title: String
    let subtitle: String
    let cost: Int
    let symbolName: String
}

let shopCatalog: [ShopItem] = [
    ShopItem(id: "ribbon", title: "月光蝴蝶结", subtitle: "桌宠头顶的小小仪式感", cost: 60, symbolName: "gift.fill"),
    ShopItem(id: "scarf", title: "薄荷围巾", subtitle: "完成日常后一起去散步", cost: 120, symbolName: "circle.hexagongrid.fill"),
    ShopItem(id: "star", title: "星星项圈", subtitle: "让桌宠看起来更精神", cost: 180, symbolName: "star.fill"),
    ShopItem(id: "crown", title: "研究员小王冠", subtitle: "全清很多天以后再戴它", cost: 320, symbolName: "crown.fill")
]

func shopItem(with id: String?) -> ShopItem? {
    guard let id else { return nil }
    return shopCatalog.first { $0.id == id }
}

func rewardCoins(priority: Priority, completedIndex: Int, total: Int) -> Int {
    let base: Int
    switch priority {
    case .red: base = 22
    case .amber: base = 15
    case .teal: base = 10
    }
    let progress = Double(completedIndex) / Double(max(total, 1))
    let curve = Int((pow(progress, 2.05) * 28).rounded())
    let finishBonus = completedIndex == total ? 36 : 0
    return base + curve + finishBonus
}
