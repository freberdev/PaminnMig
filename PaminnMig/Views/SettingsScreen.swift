import SwiftUI
import SwiftData

struct SettingsScreen: View {
    @Environment(\.modelContext) private var modelContext
    @State private var quietHours = QuietHours.load()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                quietHoursSection
                notificationSection
                aboutSection
            }
            .padding(20)
        }
        .background(AppTheme.backgroundColor)
        .navigationTitle("Inställningar")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Quiet Hours

    private var quietHoursSection: some View {
        VStack(spacing: 0) {
            Toggle(isOn: Binding(
                get: { quietHours.enabled },
                set: { v in quietHours.enabled = v; saveQuietHours() }
            )) {
                HStack {
                    Image(systemName: "moon")
                        .foregroundColor(AppTheme.primaryColor)
                    VStack(alignment: .leading) {
                        Text("Tyst tidsfönster")
                        Text("Inga notiser under nattid")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
            .tint(AppTheme.primaryColor)
            .padding(16)

            if quietHours.enabled {
                Divider().padding(.horizontal, 16)

                timePicker(
                    label: "Startar",
                    icon: "sunset",
                    hour: $quietHours.startHour,
                    minute: $quietHours.startMinute
                )

                timePicker(
                    label: "Slutar",
                    icon: "sunrise",
                    hour: $quietHours.endHour,
                    minute: $quietHours.endMinute
                )

                Text("Kritiska påminnelser bryter igenom tysta timmar")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.subtleBorder))
    }

    private func timePicker(label: String, icon: String, hour: Binding<Int>, minute: Binding<Int>) -> some View {
        let date = Binding<Date>(
            get: {
                Calendar.current.date(bySettingHour: hour.wrappedValue, minute: minute.wrappedValue, second: 0, of: Date())!
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                hour.wrappedValue = comps.hour ?? 0
                minute.wrappedValue = comps.minute ?? 0
                saveQuietHours()
            }
        )

        return HStack {
            Image(systemName: icon)
            Text(label)
            Spacer()
            DatePicker("", selection: date, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "sv"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Notification Settings

    private var notificationSection: some View {
        VStack(spacing: 0) {
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Image(systemName: "bell")
                        .foregroundColor(AppTheme.primaryColor)
                    VStack(alignment: .leading) {
                        Text("Notisbehörigheter")
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Öppna iOS-inställningar")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(16)
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.subtleBorder))
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "info.circle")
                VStack(alignment: .leading) {
                    Text("Påminn mig!")
                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0")")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
            }
            .padding(16)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.subtleBorder))
    }

    private func saveQuietHours() {
        quietHours.save()
        NotificationService.shared.rescheduleAll(modelContext: modelContext)
    }
}
