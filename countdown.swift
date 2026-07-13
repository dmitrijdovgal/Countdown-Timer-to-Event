// countdown.swift
import Foundation

let EVENTS_FILE = "events.json"
var events: [[String: Any]] = []

func loadEvents() {
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: EVENTS_FILE)),
          let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
        events = []
        return
    }
    events = json
}

func saveEvents() {
    guard let data = try? JSONSerialization.data(withJSONObject: events, options: .prettyPrinted) else { return }
    try? data.write(to: URL(fileURLWithPath: EVENTS_FILE))
}

func parseDate(_ dateStr: String) -> Date? {
    let formatters = [
        DateFormatter.dateFormat(fromTemplate: "yyyy-MM-dd", options: 0, locale: nil)!,
        "dd/MM/yyyy",
        "MM/dd/yyyy",
        "dd.MM.yyyy"
    ]
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    for fmt in formatters {
        formatter.dateFormat = fmt
        if let d = formatter.date(from: dateStr) {
            return d
        }
    }
    return nil
}

func findEvent(_ name: String) -> [String: Any]? {
    return events.first { ($0["name"] as? String)?.lowercased() == name.lowercased() }
}

func addEvent(_ name: String, _ dateStr: String, _ timeStr: String) -> Bool {
    guard parseDate(dateStr) != nil else { return false }
    let time = timeStr.isEmpty ? "00:00" : timeStr
    events.append(["name": name, "date": dateStr, "time": time])
    saveEvents()
    return true
}

func deleteEvent(_ name: String) -> Bool {
    if let idx = events.firstIndex(where: { ($0["name"] as? String)?.lowercased() == name.lowercased() }) {
        events.remove(at: idx)
        saveEvents()
        return true
    }
    return false
}

func formatCountdown(_ seconds: Double) -> String {
    if seconds < 0 { return "Event has passed!" }
    var secs = Int(seconds)
    let years = Int(Double(secs) / (365.25 * 24 * 3600))
    secs -= Int(Double(years) * 365.25 * 24 * 3600)
    let months = Int(Double(secs) / (30.44 * 24 * 3600))
    secs -= Int(Double(months) * 30.44 * 24 * 3600)
    let days = secs / (24 * 3600)
    secs -= days * 24 * 3600
    let hours = secs / 3600
    secs -= hours * 3600
    let minutes = secs / 60
    let seconds = secs % 60
    var parts: [String] = []
    if years > 0 { parts.append("\(years) year\(years > 1 ? "s" : "")") }
    if months > 0 { parts.append("\(months) month\(months > 1 ? "s" : "")") }
    if days > 0 { parts.append("\(days) day\(days > 1 ? "s" : "")") }
    if hours > 0 { parts.append("\(hours) hour\(hours > 1 ? "s" : "")") }
    if minutes > 0 { parts.append("\(minutes) minute\(minutes > 1 ? "s" : "")") }
    if seconds > 0 { parts.append("\(seconds) second\(seconds > 1 ? "s" : "")") }
    return parts.isEmpty ? "0 seconds" : parts.joined(separator: ", ")
}

func countdown(_ event: [String: Any], formatStyle: String, live: Bool) {
    guard let dateStr = event["date"] as? String,
          let timeStr = event["time"] as? String,
          let date = parseDate(dateStr) else { return }
    let timeParts = timeStr.split(separator: ":").map { Int($0) ?? 0 }
    let h = timeParts.count > 0 ? timeParts[0] : 0
    let m = timeParts.count > 1 ? timeParts[1] : 0
    let target = Calendar.current.date(bySettingHour: h, minute: m, second: 0, of: date)!
    let now = Date()
    let diff = target.timeIntervalSince(now)
    if diff <= 0 {
        print("⏰ \(event["name"] as? String ?? "Event") is in the past!")
        return
    }
    if live {
        while diff > 0 {
            print("\r⏳ \(event["name"] as? String ?? "Event"): \(formatCountdown(diff))    ", terminator: "")
            fflush(stdout)
            Thread.sleep(forTimeInterval: 1)
            let newNow = Date()
            let newDiff = target.timeIntervalSince(newNow)
            if newDiff <= 0 {
                print("\r🎉 \(event["name"] as? String ?? "Event") has arrived!    ")
                break
            }
        }
    } else {
        if formatStyle == "compact" {
            let totalSec = Int(diff)
            let days = totalSec / 86400
            let hours = (totalSec % 86400) / 3600
            let minutes = (totalSec % 3600) / 60
            let seconds = totalSec % 60
            print("⏳ \(event["name"] as? String ?? "Event"): \(String(format: "%02d:%02d:%02d:%02d", days, hours, minutes, seconds))")
        } else if formatStyle == "short" {
            print("⏳ \(event["name"] as? String ?? "Event"): \(Int(diff)) seconds")
        } else {
            print("⏳ \(event["name"] as? String ?? "Event"): \(formatCountdown(diff))")
        }
    }
}

func listEvents() {
    if events.isEmpty {
        print("No events saved.")
        return
    }
    for e in events {
        guard let name = e["name"] as? String,
              let dateStr = e["date"] as? String,
              let timeStr = e["time"] as? String else { continue }
        let timeParts = timeStr.split(separator: ":").map { Int($0) ?? 0 }
        let h = timeParts.count > 0 ? timeParts[0] : 0
        let m = timeParts.count > 1 ? timeParts[1] : 0
        let date = parseDate(dateStr)
        let target = date.map { Calendar.current.date(bySettingHour: h, minute: m, second: 0, of: $0) }
        let status = target.map { $0! > Date() ? "⏳ pending" : "✅ passed" } ?? "unknown"
        print("  \(name): \(dateStr) \(timeStr) - \(status)")
    }
}

func interactive() {
    loadEvents()
    print("=== Countdown Timer ===")
    while true {
        print("\n1. Set new event")
        print("2. Show countdown")
        print("3. Live countdown")
        print("4. List events")
        print("5. Delete event")
        print("6. Save events")
        print("7. Load events")
        print("8. Exit")
        print("Choose: ", terminator: "")
        guard let choice = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else { continue }
        switch choice {
        case "1":
            print("Event name: ", terminator: "")
            guard let name = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
                print("Name required.")
                continue
            }
            if findEvent(name) != nil {
                print("Event already exists.")
                continue
            }
            print("Event date (YYYY-MM-DD): ", terminator: "")
            guard let dateStr = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else { continue }
            if parseDate(dateStr) == nil {
                print("Invalid date.")
                continue
            }
            print("Event time (HH:MM, optional): ", terminator: "")
            let timeStr = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "00:00"
            if addEvent(name, dateStr, timeStr) {
                print("Event saved.")
            }
        case "2":
            print("Event name: ", terminator: "")
            guard let name = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else { continue }
            guard let event = findEvent(name) else {
                print("Event not found.")
                continue
            }
            countdown(event, formatStyle: "full", live: false)
        case "3":
            print("Event name: ", terminator: "")
            guard let name = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else { continue }
            guard let event = findEvent(name) else {
                print("Event not found.")
                continue
            }
            countdown(event, formatStyle: "full", live: true)
        case "4": listEvents()
        case "5":
            print("Event name to delete: ", terminator: "")
            guard let name = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else { continue }
            if deleteEvent(name) {
                print("Event deleted.")
            } else {
                print("Event not found.")
            }
        case "6": saveEvents(); print("Events saved.")
        case "7": loadEvents(); print("Events loaded.")
        case "8": print("Goodbye!"); return
        default: print("Invalid choice.")
        }
    }
}

func cli() {
    let args = CommandLine.arguments.dropFirst()
    var params: [String: String] = [:]
    var i = 0
    let argArray = Array(args)
    while i < argArray.count {
        let arg = argArray[i]
        if arg.hasPrefix("--") {
            let key = String(arg.dropFirst(2))
            if i + 1 < argArray.count && !argArray[i+1].hasPrefix("--") {
                params[key] = argArray[i+1]
                i += 2
            } else {
                params[key] = "true"
                i += 1
            }
        } else {
            i += 1
        }
    }
    loadEvents()
    if params["list"] != nil {
        listEvents()
        return
    }
    if let deleteName = params["delete"] {
        if deleteEvent(deleteName) {
            print("Event deleted.")
        } else {
            print("Event not found.")
        }
        return
    }
    if let eventName = params["event"], let dateStr = params["date"] {
        if let event = findEvent(eventName) {
            let formatStyle = params["format"] ?? "full"
            let live = params["live"] != nil
            countdown(event, formatStyle: formatStyle, live: live)
        } else {
            print("Event not found.")
        }
    } else {
        print("Usage: swift countdown.swift --event NAME --date DATE [--time TIME] [--format full|compact|short] [--live]")
    }
}

if CommandLine.arguments.count > 1 {
    cli()
} else {
    interactive()
}
