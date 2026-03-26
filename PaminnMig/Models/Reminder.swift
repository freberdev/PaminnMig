import Foundation
import SwiftData

// MARK: - Enums

enum ReminderType: Int, Codable {
    case standard = 0
    case locationBased = 1
}

enum RecurrenceType: Int, Codable, CaseIterable {
    case none = 0
    case daily
    case weekdays
    case weekends
    case weekly
    case biweekly
    case monthly
    case lastDayOfMonth
    case yearly
    case custom
}

// MARK: - Recurrence Rule

struct RecurrenceRule: Codable, Equatable {
    var type: RecurrenceType = .none
    var daysOfWeek: [Int]?
    var interval: Int?
    var dayOfMonth: Int?
    var hourInterval: Int?
    var startTimeMinutes: Int?
    var maxDailyOccurrences: Int?
    var endDate: Date?

    var displayString: String {
        let endStr = endDate.map { d in
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return " t.o.m. \(f.string(from: d))"
        } ?? ""

        switch type {
        case .none: return "Ingen upprepning"
        case .daily: return "Varje dag\(endStr)"
        case .weekdays: return "Varje vardag\(endStr)"
        case .weekends: return "Varje helgdag\(endStr)"
        case .weekly: return "Varje vecka\(endStr)"
        case .biweekly: return "Varannan vecka\(endStr)"
        case .monthly:
            if let d = dayOfMonth { return "Den \(d):e varje månad\(endStr)" }
            return "Varje månad\(endStr)"
        case .lastDayOfMonth: return "Sista dagen i månaden\(endStr)"
        case .yearly: return "Varje år\(endStr)"
        case .custom:
            var parts: [String] = []
            if let hi = hourInterval, hi > 0 {
                let hourStr = hi == 1 ? "varje timme" : "var \(hi):e timme"
                var timeParts = [hourStr]
                if let stm = startTimeMinutes {
                    let h = String(format: "%02d", stm / 60)
                    let m = String(format: "%02d", stm % 60)
                    timeParts.append("från \(h):\(m)")
                }
                if let max = maxDailyOccurrences {
                    timeParts.append("\(max) ggr/dag")
                }
                parts.append(timeParts.joined(separator: ", "))
            }
            if let days = daysOfWeek, !days.isEmpty {
                let dayNames = ["", "mån", "tis", "ons", "tor", "fre", "lör", "sön"]
                let dayStr = days.map { dayNames[$0] }.joined(separator: ", ")
                let intStr = (interval ?? 1) > 1 ? "var \(interval!):e vecka" : "varje vecka"
                parts.append("\(intStr) (\(dayStr))")
            }
            if !parts.isEmpty { return "\(parts.joined(separator: ", "))\(endStr)" }
            return "Anpassad\(endStr)"
        }
    }

    func getNextOccurrence(from: Date) -> Date? {
        if let end = endDate, from > end { return nil }
        let result = computeNextOccurrence(from: from)
        if let r = result, let end = endDate {
            let cal = Calendar.current
            let endOfDay = cal.date(bySettingHour: 23, minute: 59, second: 59, of: end)!
            if r > endOfDay { return nil }
        }
        return result
    }

    private func computeNextOccurrence(from: Date) -> Date? {
        let cal = Calendar.current
        switch type {
        case .none: return nil
        case .daily: return cal.date(byAdding: .day, value: 1, to: from)
        case .weekdays:
            var next = cal.date(byAdding: .day, value: 1, to: from)!
            while cal.component(.weekday, from: next).toISOWeekday > 5 { next = cal.date(byAdding: .day, value: 1, to: next)! }
            return next
        case .weekends:
            var next = cal.date(byAdding: .day, value: 1, to: from)!
            while cal.component(.weekday, from: next).toISOWeekday < 6 { next = cal.date(byAdding: .day, value: 1, to: next)! }
            return next
        case .weekly: return cal.date(byAdding: .day, value: 7, to: from)
        case .biweekly: return cal.date(byAdding: .day, value: 14, to: from)
        case .monthly:
            let targetDay = dayOfMonth ?? cal.component(.day, from: from)
            guard let nextMonth = cal.date(byAdding: .month, value: 1, to: cal.startOfMonth(for: from)) else { return nil }
            let lastDay = cal.range(of: .day, in: .month, for: nextMonth)?.count ?? 28
            var comps = cal.dateComponents([.year, .month], from: nextMonth)
            comps.day = min(targetDay, lastDay)
            comps.hour = cal.component(.hour, from: from)
            comps.minute = cal.component(.minute, from: from)
            return cal.date(from: comps)
        case .lastDayOfMonth:
            guard let nextMonth = cal.date(byAdding: .month, value: 1, to: cal.startOfMonth(for: from)) else { return nil }
            let lastDay = cal.range(of: .day, in: .month, for: nextMonth)?.count ?? 28
            var comps = cal.dateComponents([.year, .month], from: nextMonth)
            comps.day = lastDay
            comps.hour = cal.component(.hour, from: from)
            comps.minute = cal.component(.minute, from: from)
            return cal.date(from: comps)
        case .yearly: return cal.date(byAdding: .year, value: 1, to: from)
        case .custom:
            if let hi = hourInterval, hi > 0 {
                let startH = (startTimeMinutes ?? (cal.component(.hour, from: from) * 60 + cal.component(.minute, from: from))) / 60
                let startM = (startTimeMinutes ?? (cal.component(.hour, from: from) * 60 + cal.component(.minute, from: from))) % 60
                for d in 0..<365 {
                    guard let day = cal.date(byAdding: .day, value: d, to: from) else { continue }
                    let wd = cal.component(.weekday, from: day).toISOWeekday
                    if let days = daysOfWeek, !days.isEmpty, !days.contains(wd) { continue }
                    var slot = cal.date(bySettingHour: startH, minute: startM, second: 0, of: day)!
                    var count = 0
                    while cal.component(.day, from: slot) == cal.component(.day, from: day) {
                        if let max = maxDailyOccurrences, count >= max { break }
                        if slot > from { return slot }
                        slot = cal.date(byAdding: .hour, value: hi, to: slot)!
                        count += 1
                    }
                }
                return nil
            }
            if let days = daysOfWeek, !days.isEmpty {
                let step = interval ?? 1
                var next = cal.date(byAdding: .day, value: 1, to: from)!
                var weeksAhead = 0
                for i in 0..<365 {
                    let wd = cal.component(.weekday, from: next).toISOWeekday
                    if wd == cal.component(.weekday, from: from).toISOWeekday && i > 0 { weeksAhead += 1 }
                    if days.contains(wd) { if step <= 1 || weeksAhead % step == 0 { return next } }
                    next = cal.date(byAdding: .day, value: 1, to: next)!
                }
            }
            return nil
        }
    }
}

// MARK: - Location Trigger

struct LocationTrigger: Codable, Equatable {
    var latitude: Double
    var longitude: Double
    var radiusMeters: Double = 200
    var placeName: String?
}

// MARK: - Reminder Model

@Model
final class Reminder {
    @Attribute(.unique) var id: String
    var title: String
    var notes: String?
    var createdAt: Date
    var dueDate: Date?
    var isCompleted: Bool
    var completedAt: Date?
    var typeRaw: Int
    var recurrenceData: Data
    var locationTriggerData: Data?
    var isCritical: Bool
    var snoozedUntil: Date?
    var category: String?
    var priority: Int

    var type: ReminderType {
        get { ReminderType(rawValue: typeRaw) ?? .standard }
        set { typeRaw = newValue.rawValue }
    }

    var recurrence: RecurrenceRule {
        get { (try? JSONDecoder().decode(RecurrenceRule.self, from: recurrenceData)) ?? RecurrenceRule() }
        set { recurrenceData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var locationTrigger: LocationTrigger? {
        get { guard let data = locationTriggerData else { return nil }; return try? JSONDecoder().decode(LocationTrigger.self, from: data) }
        set { locationTriggerData = newValue.flatMap { try? JSONEncoder().encode($0) } }
    }

    init(
        id: String = UUID().uuidString, title: String, notes: String? = nil, createdAt: Date = Date(),
        dueDate: Date? = nil, isCompleted: Bool = false, completedAt: Date? = nil,
        type: ReminderType = .standard, recurrence: RecurrenceRule = RecurrenceRule(),
        locationTrigger: LocationTrigger? = nil,
        isCritical: Bool = false, snoozedUntil: Date? = nil, category: String? = nil, priority: Int = 0
    ) {
        self.id = id; self.title = title; self.notes = notes; self.createdAt = createdAt
        self.dueDate = dueDate; self.isCompleted = isCompleted; self.completedAt = completedAt
        self.typeRaw = type.rawValue
        self.recurrenceData = (try? JSONEncoder().encode(recurrence)) ?? Data()
        self.locationTriggerData = locationTrigger.flatMap { try? JSONEncoder().encode($0) }
        self.isCritical = isCritical; self.snoozedUntil = snoozedUntil
        self.category = category; self.priority = priority
    }

    func duplicate(id: String? = nil, dueDate: Date? = nil, isCompleted: Bool? = nil,
                   completedAt: Date?? = nil, snoozedUntil: Date?? = nil) -> Reminder {
        Reminder(id: id ?? UUID().uuidString, title: title, notes: notes, createdAt: createdAt,
                 dueDate: dueDate ?? self.dueDate, isCompleted: isCompleted ?? self.isCompleted,
                 completedAt: completedAt ?? self.completedAt, type: type, recurrence: recurrence,
                 locationTrigger: locationTrigger,
                 isCritical: isCritical, snoozedUntil: snoozedUntil ?? self.snoozedUntil,
                 category: category, priority: priority)
    }
}

// MARK: - Helpers

extension Int {
    var toISOWeekday: Int { self == 1 ? 7 : self - 1 }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date))!
    }
}