import Foundation
import UserNotifications
import SwiftData

final class NotificationService {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()

    func initialize() {
        let completeAction = UNNotificationAction(
            identifier: "complete",
            title: "Klar",
            options: [.foreground]
        )
        let snooze15 = UNNotificationAction(identifier: "snooze_15", title: "15 min")
        let snooze60 = UNNotificationAction(identifier: "snooze_60", title: "1 timme")
        let snoozeTomorrow = UNNotificationAction(identifier: "snooze_tomorrow", title: "Imorgon")

        let reminderCategory = UNNotificationCategory(
            identifier: "reminder",
            actions: [completeAction, snooze15, snooze60, snoozeTomorrow],
            intentIdentifiers: []
        )
        let criticalCategory = UNNotificationCategory(
            identifier: "critical_reminder",
            actions: [completeAction, snooze15],
            intentIdentifiers: []
        )

        center.setNotificationCategories([reminderCategory, criticalCategory])
    }

    func requestPermissions() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound, .criticalAlert])
        } catch {
            return false
        }
    }

    func scheduleNotification(for reminder: Reminder) {
        guard !reminder.isCompleted else { return }

        let scheduleDate = reminder.snoozedUntil ?? reminder.dueDate
        guard let scheduleDate, scheduleDate > Date() else { return }

        // Check quiet hours (unless critical)
        var finalDate = scheduleDate
        if !reminder.isCritical {
            let qh = QuietHours.load()
            if qh.enabled {
                let cal = Calendar.current
                let schedMin = cal.component(.hour, from: scheduleDate) * 60 + cal.component(.minute, from: scheduleDate)
                let startMin = qh.startHour * 60 + qh.startMinute
                let endMin = qh.endHour * 60 + qh.endMinute

                let inQuietWindow: Bool
                if startMin < endMin {
                    inQuietWindow = schedMin >= startMin && schedMin < endMin
                } else {
                    inQuietWindow = schedMin >= startMin || schedMin < endMin
                }

                if inQuietWindow {
                    var comps = cal.dateComponents([.year, .month, .day], from: scheduleDate)
                    if schedMin >= startMin { comps.day! += 1 }
                    comps.hour = qh.endHour
                    comps.minute = qh.endMinute
                    finalDate = cal.date(from: comps) ?? scheduleDate
                }
            }
        }

        scheduleActual(reminder: reminder, at: finalDate)
    }

    private func scheduleActual(reminder: Reminder, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.notes ?? buildSubtitle(for: reminder)
        content.sound = .default
        content.categoryIdentifier = reminder.isCritical ? "critical_reminder" : "reminder"
        content.userInfo = ["reminderId": reminder.id]
        content.threadIdentifier = reminder.category ?? "default"

        if reminder.isCritical {
            content.interruptionLevel = .critical
        }

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

        let notificationId = notificationIdentifier(for: reminder.id)
        let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)

        center.add(request)
    }

    private func buildSubtitle(for reminder: Reminder) -> String {
        if reminder.recurrence.type != .none {
            return reminder.recurrence.displayString
        }
        if let place = reminder.locationTrigger?.placeName {
            return "Vid \(place)"
        }
        return ""
    }

    func cancelNotification(for reminderId: String) {
        center.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier(for: reminderId)])
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    func rescheduleAll(modelContext: ModelContext) {
        cancelAll()
        let descriptor = FetchDescriptor<Reminder>(predicate: #Predicate { !$0.isCompleted && $0.typeRaw == 0 })
        guard let reminders = try? modelContext.fetch(descriptor) else { return }
        for reminder in reminders {
            scheduleNotification(for: reminder)
        }
    }

    private func notificationIdentifier(for reminderId: String) -> String {
        "reminder_\(reminderId)"
    }

    // MARK: - Snooze handling

    func handleSnooze(reminderId: String, duration: TimeInterval, modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Reminder>(predicate: #Predicate<Reminder> { $0.id == reminderId })
        guard let reminder = try? modelContext.fetch(descriptor).first else { return }

        let snoozedUntil = Date().addingTimeInterval(duration)
        reminder.snoozedUntil = snoozedUntil
        try? modelContext.save()

        let temp = reminder.duplicate(dueDate: snoozedUntil)
        scheduleNotification(for: temp)
    }

    func handleComplete(reminderId: String, modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Reminder>(predicate: #Predicate<Reminder> { $0.id == reminderId })
        guard let reminder = try? modelContext.fetch(descriptor).first else { return }

        reminder.isCompleted = true
        reminder.completedAt = Date()
        cancelNotification(for: reminderId)
        try? modelContext.save()
    }
}
