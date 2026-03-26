import Foundation

struct QuietHours: Codable {
    var enabled: Bool = false
    var startHour: Int = 22
    var startMinute: Int = 0
    var endHour: Int = 7
    var endMinute: Int = 0

    var isActiveNow: Bool {
        guard enabled else { return false }
        let cal = Calendar.current
        let now = cal.dateComponents([.hour, .minute], from: Date())
        let nowMinutes = (now.hour ?? 0) * 60 + (now.minute ?? 0)
        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute

        if startMinutes < endMinutes {
            return nowMinutes >= startMinutes && nowMinutes < endMinutes
        } else {
            // Spans midnight
            return nowMinutes >= startMinutes || nowMinutes < endMinutes
        }
    }

    static let key = "quiet_hours"

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }

    static func load() -> QuietHours {
        guard let data = UserDefaults.standard.data(forKey: key),
              let qh = try? JSONDecoder().decode(QuietHours.self, from: data) else {
            return QuietHours()
        }
        return qh
    }
}
