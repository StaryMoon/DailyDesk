import AppKit
import Foundation

func runCLI() {
    let args = CommandLine.arguments
    if args.contains("--generate") {
        let config = loadConfig()
        let added = generateDailyTasks(force: args.contains("--force"), config: config)
        print("generated=\(added)")
        exit(0)
    }
    if args.contains("--pin") || args.contains("--unpin") {
        let config = loadConfig()
        var state = loadState(defaultPinned: config.defaultPinned)
        state.pinned = args.contains("--pin")
        saveState(state)
        print("pinned=\(state.pinned)")
        exit(0)
    }
    if args.contains("--show-config") {
        print(configURL.path)
        exit(0)
    }
}

runCLI()
let app = NSApplication.shared
let delegate = DailyDeskController()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()

