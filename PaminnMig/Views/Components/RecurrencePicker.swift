import SwiftUI

struct RecurrencePicker: View {
    @Binding var recurrence: RecurrenceRule
    @Environment(\.dismiss) private var dismiss

    @State private var type: RecurrenceType = .none
    @State private var selectedDays: Set<Int> = []
    @State private var interval = 1
    @State private var dayOfMonth = 1
    @State private var hourInterval = 4
    @State private var maxDaily: Int?
    @State private var endDate: Date?
    @State private var customMode: CustomMode = .hourly

    enum CustomMode { case hourly, weekly }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    presetsList
                    if type == .custom {
                        Divider().padding(.vertical, 8)
                        customSection
                    }
                    if type == .monthly {
                        Divider().padding(.vertical, 8)
                        monthlyOptions
                    }
                    if type != .none {
                        Divider().padding(.vertical, 8)
                        endDatePicker
                    }
                    Button { confirm() } label: {
                        Text("Klar")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.accentColor)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.top, 16)
                }
                .padding(16)
            }
            .navigationTitle("Upprepning")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { loadExisting() }
    }

    private var presetsList: some View {
        let presets: [(RecurrenceType, String, String)] = [
            (.none, "Ingen upprepning", "xmark"),
            (.daily, "Varje dag", "sun.max"),
            (.weekdays, "Varje vardag", "briefcase"),
            (.weekends, "Varje helgdag", "moon.stars"),
            (.weekly, "Varje vecka", "calendar"),
            (.biweekly, "Varannan vecka", "calendar.badge.plus"),
            (.monthly, "Varje månad", "calendar.circle"),
            (.lastDayOfMonth, "Sista dagen i månaden", "calendar.day.timeline.left"),
            (.yearly, "Varje år", "gift"),
            (.custom, "Anpassad...", "slider.horizontal.3"),
        ]

        return ForEach(presets, id: \.0) { preset in
            Button { type = preset.0 } label: {
                HStack(spacing: 12) {
                    Image(systemName: preset.2)
                        .foregroundColor(type == preset.0 ? AppTheme.primaryColor : AppTheme.textSecondary)
                        .frame(width: 24)
                    Text(preset.1)
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    if type == preset.0 {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.primaryColor)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var customSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Läge", selection: $customMode) {
                Label("Timmar", systemImage: "clock").tag(CustomMode.hourly)
                Label("Veckodagar", systemImage: "calendar").tag(CustomMode.weekly)
            }
            .pickerStyle(.segmented)

            if customMode == .hourly {
                hourlyOptions
            } else {
                weeklyOptions
            }
        }
    }

    private var hourlyOptions: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "repeat")
                    .foregroundColor(AppTheme.accentColor)
                Text("Var")
                TextField("4", value: $hourInterval, format: .number)
                    .keyboardType(.numberPad)
                    .frame(width: 55)
                    .multilineTextAlignment(.center)
                    .padding(6)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.subtleBorder))
                Text(":e timme")
            }

            HStack {
                Image(systemName: "bell")
                    .foregroundColor(AppTheme.accentColor)
                Text("Max")
                TextField("∞", value: $maxDaily, format: .number)
                    .keyboardType(.numberPad)
                    .frame(width: 50)
                    .multilineTextAlignment(.center)
                    .padding(6)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.subtleBorder))
                Text("gånger per dag")
            }

            Button {
                if selectedDays.isEmpty {
                    selectedDays = [1, 2, 3, 4, 5]
                } else {
                    selectedDays.removeAll()
                }
            } label: {
                HStack {
                    Image(systemName: selectedDays.isEmpty ? "square" : "checkmark.square.fill")
                        .foregroundColor(selectedDays.isEmpty ? AppTheme.textSecondary : AppTheme.primaryColor)
                    Text("Begränsa till vissa dagar")
                        .foregroundColor(selectedDays.isEmpty ? AppTheme.textSecondary : AppTheme.textPrimary)
                }
            }

            if !selectedDays.isEmpty {
                daySelector
            }
        }
    }

    private var weeklyOptions: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Välj dagar")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
            daySelector

            HStack {
                Image(systemName: "repeat")
                    .foregroundColor(AppTheme.accentColor)
                Text("Var")
                TextField("1", value: $interval, format: .number)
                    .keyboardType(.numberPad)
                    .frame(width: 55)
                    .multilineTextAlignment(.center)
                    .padding(6)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.subtleBorder))
                Text(":e vecka")
            }
        }
    }

    private var daySelector: some View {
        let labels = ["Mån", "Tis", "Ons", "Tor", "Fre", "Lör", "Sön"]
        return HStack {
            ForEach(0..<7, id: \.self) { i in
                let dayNum = i + 1
                let selected = selectedDays.contains(dayNum)
                Button {
                    if selected { selectedDays.remove(dayNum) }
                    else { selectedDays.insert(dayNum) }
                } label: {
                    Text(labels[i])
                        .font(.system(size: 13, weight: .medium))
                        .frame(width: 42, height: 42)
                        .background(selected ? AppTheme.primaryColor : Color.gray.opacity(0.1))
                        .foregroundColor(selected ? .white : AppTheme.textPrimary)
                        .clipShape(Circle())
                }
            }
        }
    }

    private var monthlyOptions: some View {
        HStack {
            Text("Den")
            TextField("1", value: $dayOfMonth, format: .number)
                .keyboardType(.numberPad)
                .frame(width: 60)
                .multilineTextAlignment(.center)
                .padding(6)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.subtleBorder))
            Text(":e varje månad")
        }
    }

    private var endDatePicker: some View {
        HStack {
            Image(systemName: "calendar.badge.minus")
                .foregroundColor(endDate != nil ? AppTheme.warningColor : AppTheme.textSecondary)
            if let end = endDate {
                let f = { () -> String in
                    let df = DateFormatter()
                    df.dateFormat = "yyyy-MM-dd"
                    return df.string(from: end)
                }()
                Text("Slutar \(f)")
                Spacer()
                Button { endDate = nil } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.textSecondary)
                }
            } else {
                Button("Lägg till slutdatum...") {
                    endDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())
                }
                .foregroundColor(AppTheme.textSecondary)
                Spacer()
            }
        }
    }

    private func loadExisting() {
        type = recurrence.type
        if let days = recurrence.daysOfWeek { selectedDays = Set(days) }
        interval = recurrence.interval ?? 1
        dayOfMonth = recurrence.dayOfMonth ?? 1
        hourInterval = recurrence.hourInterval ?? 4
        maxDaily = recurrence.maxDailyOccurrences
        endDate = recurrence.endDate
        if recurrence.type == .custom {
            if recurrence.hourInterval != nil && recurrence.hourInterval! > 0 {
                customMode = .hourly
            } else {
                customMode = .weekly
            }
        }
    }

    private func confirm() {
        let isHourly = type == .custom && customMode == .hourly
        let isWeekly = type == .custom && customMode == .weekly

        recurrence = RecurrenceRule(
            type: type,
            daysOfWeek: type == .custom && !selectedDays.isEmpty ? selectedDays.sorted() : nil,
            interval: isWeekly ? interval : nil,
            dayOfMonth: type == .monthly ? dayOfMonth : nil,
            hourInterval: isHourly && hourInterval > 0 ? hourInterval : nil,
            maxDailyOccurrences: isHourly && hourInterval > 0 ? maxDaily : nil,
            endDate: type != .none ? endDate : nil
        )
        dismiss()
    }
}
