import Foundation

struct SnoozeOption: Identifiable {
    let id = UUID()
    let label: String
    let duration: TimeInterval?
    let dateTimeBuilder: (() -> Date)?

    init(label: String, duration: TimeInterval) {
        self.label = label
        self.duration = duration
        self.dateTimeBuilder = nil
    }

    init(label: String, dateTimeBuilder: @escaping () -> Date) {
        self.label = label
        self.duration = nil
        self.dateTimeBuilder = dateTimeBuilder
    }

    var snoozeTime: Date {
        dateTimeBuilder?() ?? Date().addingTimeInterval(duration ?? 0)
    }

    static func smartOptions() -> [SnoozeOption] {
        let now = Date()
        let cal = Calendar.current
        let hour = cal.component(.hour, from: now)

        var options: [SnoozeOption] = [
            SnoozeOption(label: "15 minuter", duration: 15 * 60),
            SnoozeOption(label: "30 minuter", duration: 30 * 60),
            SnoozeOption(label: "1 timme", duration: 3600),
            SnoozeOption(label: "3 timmar", duration: 3 * 3600),
        ]

        if hour < 18 {
            options.append(SnoozeOption(label: "Senare idag (18:00)") {
                cal.date(bySettingHour: 18, minute: 0, second: 0, of: now)!
            })
        }

        if hour < 20 {
            options.append(SnoozeOption(label: "Ikväll (20:00)") {
                cal.date(bySettingHour: 20, minute: 0, second: 0, of: now)!
            })
        }

        options.append(SnoozeOption(label: "Imorgon bitti (08:00)") {
            let tomorrow = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: now))!
            return cal.date(bySettingHour: 8, minute: 0, second: 0, of: tomorrow)!
        })

        let weekday = cal.component(.weekday, from: now).toISOWeekday
        if weekday != 1 {
            let daysUntilMonday = (8 - weekday) % 7
            options.append(SnoozeOption(label: "Nästa måndag (08:00)") {
                let monday = cal.date(byAdding: .day, value: daysUntilMonday, to: cal.startOfDay(for: now))!
                return cal.date(bySettingHour: 8, minute: 0, second: 0, of: monday)!
            })
        }

        if weekday < 6 {
            let daysUntilSaturday = 6 - weekday
            options.append(SnoozeOption(label: "Helgen (lördag 10:00)") {
                let saturday = cal.date(byAdding: .day, value: daysUntilSaturday, to: cal.startOfDay(for: now))!
                return cal.date(bySettingHour: 10, minute: 0, second: 0, of: saturday)!
            })
        }

        return options
    }
}
