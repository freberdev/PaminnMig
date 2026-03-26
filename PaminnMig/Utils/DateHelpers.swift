import Foundation

enum DateHelpers {
    static func formatRelativeDate(_ date: Date) -> String {
        let cal = Calendar.current
        let now = Date()
        let today = cal.startOfDay(for: now)
        let tomorrow = cal.date(byAdding: .day, value: 1, to: today)!
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        let dateOnly = cal.startOfDay(for: date)

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.locale = Locale(identifier: "sv")

        let time = timeFormatter.string(from: date)

        if dateOnly == today {
            return "Idag \(time)"
        } else if dateOnly == tomorrow {
            return "Imorgon \(time)"
        } else if dateOnly == yesterday {
            return "Igår \(time)"
        } else if date.timeIntervalSince(now) < 7 * 24 * 3600 && date > now {
            return "\(weekdayName(cal.component(.weekday, from: date).toISOWeekday)) \(time)"
        } else {
            let f = DateFormatter()
            f.dateFormat = "d MMM yyyy HH:mm"
            f.locale = Locale(identifier: "sv")
            return f.string(from: date)
        }
    }

    static func formatShortDate(_ date: Date) -> String {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let dateOnly = cal.startOfDay(for: date)

        if dateOnly == today { return "Idag" }
        if dateOnly == cal.date(byAdding: .day, value: 1, to: today)! { return "Imorgon" }

        let f = DateFormatter()
        f.dateFormat = "d MMM"
        f.locale = Locale(identifier: "sv")
        return f.string(from: date)
    }

    private static func weekdayName(_ weekday: Int) -> String {
        let names = ["", "Måndag", "Tisdag", "Onsdag", "Torsdag", "Fredag", "Lördag", "Söndag"]
        return names[weekday]
    }

    static func timeUntil(_ date: Date) -> String {
        let diff = date.timeIntervalSince(Date())
        if diff < 0 {
            let abs = -diff
            if abs < 3600 { return "\(Int(abs / 60)) min sedan" }
            if abs < 86400 { return "\(Int(abs / 3600)) tim sedan" }
            return "\(Int(abs / 86400)) dagar sedan"
        }
        if diff < 3600 { return "om \(Int(diff / 60)) min" }
        if diff < 86400 { return "om \(Int(diff / 3600)) tim" }
        return "om \(Int(diff / 86400)) dagar"
    }
}
