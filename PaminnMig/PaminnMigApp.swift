import SwiftUI
import SwiftData

@main
struct PaminnMigApp: App {
    @State private var showSplash = true

    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: Reminder.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        NotificationService.shared.initialize()

        Task {
            await NotificationService.shared.requestPermissions()
        }

        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                HomeScreen()
                    .environment(\.locale, Locale(identifier: "sv"))

                if showSplash {
                    SplashScreen()
                        .transition(.opacity)
                        .zIndex(1)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showSplash = false
                                }
                            }
                        }
                }
            }
        }
        .modelContainer(modelContainer)
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let openCreateReminder = Notification.Name("openCreateReminder")
}

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .badge, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let reminderId = userInfo["reminderId"] as? String else { return }

        guard let container = try? ModelContainer(for: Reminder.self) else { return }
        let context = ModelContext(container)

        switch response.actionIdentifier {
        case "complete":
            NotificationService.shared.handleComplete(reminderId: reminderId, modelContext: context)
        case "snooze_15":
            NotificationService.shared.handleSnooze(reminderId: reminderId, duration: 15 * 60, modelContext: context)
        case "snooze_60":
            NotificationService.shared.handleSnooze(reminderId: reminderId, duration: 3600, modelContext: context)
        case "snooze_tomorrow":
            let cal = Calendar.current
            let tomorrow = cal.date(bySettingHour: 9, minute: 0, second: 0,
                                     of: cal.date(byAdding: .day, value: 1, to: Date())!)!
            let duration = tomorrow.timeIntervalSince(Date())
            NotificationService.shared.handleSnooze(reminderId: reminderId, duration: duration, modelContext: context)
        default:
            break
        }
    }
}
