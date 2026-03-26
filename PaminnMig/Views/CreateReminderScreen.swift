import SwiftUI
import SwiftData

struct CreateReminderScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var editingReminder: Reminder?

    @State private var title = ""
    @State private var notes = ""
    @State private var categoryText = ""
    @State private var type: ReminderType = .standard
    @State private var dueDate: Date?
    @State private var dueTime: Date?
    @State private var recurrence = RecurrenceRule()
    @State private var locationTrigger: LocationTrigger?
    @State private var isCritical = false
    @State private var priority = 0
    @State private var showAdvanced = false
    @State private var showRecurrencePicker = false
    @State private var showDeleteConfirm = false
    @FocusState private var titleFocused: Bool

    private var isEditing: Bool { editingReminder != nil }

    @Query(sort: \Reminder.title) private var allReminders: [Reminder]
    private var categories: [String] {
        Array(Set(allReminders.compactMap(\.category))).sorted()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom header
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(width: 36, height: 36)
                }

                Spacer()

                Text(isEditing ? "Redigera" : "Ny påminnelse")
                    .font(.system(size: 17, weight: .semibold))

                Spacer()

                Button { save() } label: {
                    Text("Spara")
                        .font(.system(size: 15, weight: .semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AppTheme.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            ScrollView {
                VStack(spacing: 8) {
                    titleField
                    notesField

                    if type == .standard {
                        dateTimePicker
                            .padding(.top, 4)
                    }

                    advancedToggle
                        .padding(.top, 4)

                    if showAdvanced {
                        typeSelector
                            .padding(.top, 4)

                        if type == .standard {
                            recurrenceRow
                        }
                        if type == .locationBased {
                            LocationPicker(locationTrigger: $locationTrigger)
                        }
                        optionsSection
                            .padding(.top, 4)
                        categoryField
                            .padding(.top, 4)
                    }

                    if isEditing {
                        deleteButton
                            .padding(.top, 20)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
        .background(AppTheme.backgroundColor)
        .onAppear { loadEditing() }
        .sheet(isPresented: $showRecurrencePicker) {
            RecurrencePicker(recurrence: $recurrence)
                .presentationDetents([.large])
        }
        .confirmationDialog("Ta bort?", isPresented: $showDeleteConfirm) {
            Button("Ta bort", role: .destructive) { deleteAndDismiss() }
            Button("Avbryt", role: .cancel) {}
        } message: {
            Text("Vill du ta bort denna påminnelse?")
        }
    }

    // MARK: - Fields

    private var titleField: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell")
                .font(.system(size: 18))
                .foregroundColor(AppTheme.textSecondary)
            TextField("Vad vill du bli påmind om?", text: $title)
                .font(.system(size: 18, weight: .semibold))
                .textInputAutocapitalization(.sentences)
                .focused($titleFocused)
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.subtleBorder))
    }

    private var notesField: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 18))
                .foregroundColor(AppTheme.textSecondary)
                .padding(.top, 2)
            TextField("Anteckningar (valfritt)", text: $notes, axis: .vertical)
                .font(.system(size: 15))
                .lineLimit(1...3)
                .textInputAutocapitalization(.sentences)
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.subtleBorder))
    }

    private var dateTimePicker: some View {
        VStack(spacing: 0) {
            Button {
                if dueDate == nil { dueDate = Date() }
                else { dueDate = nil; dueTime = nil }
            } label: {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(AppTheme.primaryColor)
                    Text(dueDate.map { formatDate($0) } ?? "Välj datum")
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    if dueDate != nil {
                        Button { dueDate = nil; dueTime = nil } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
                .padding(16)
            }

            if dueDate != nil {
                Divider().padding(.horizontal, 16)
                DatePicker(
                    "Datum",
                    selection: Binding(get: { dueDate ?? Date() }, set: { dueDate = $0 }),
                    displayedComponents: [.date]
                )
                .datePickerStyle(.compact)
                .environment(\.locale, Locale(identifier: "sv"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                Divider().padding(.horizontal, 16)

                DatePicker(
                    "Tid",
                    selection: Binding(
                        get: { dueTime ?? Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())! },
                        set: { dueTime = $0 }
                    ),
                    displayedComponents: [.hourAndMinute]
                )
                .datePickerStyle(.compact)
                .environment(\.locale, Locale(identifier: "sv"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.subtleBorder))
    }

    private var advancedToggle: some View {
        Button { withAnimation { showAdvanced.toggle() } } label: {
            HStack(spacing: 6) {
                Image(systemName: showAdvanced ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                Text("Avancerat")
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(AppTheme.accentColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var typeSelector: some View {
        Picker("Typ", selection: $type) {
            Label("Tid", systemImage: "clock").tag(ReminderType.standard)
            Label("Plats", systemImage: "location").tag(ReminderType.locationBased)
        }
        .pickerStyle(.segmented)
        .onChange(of: type) { _, newType in
            if newType != .standard {
                dueDate = nil
                dueTime = nil
                recurrence = RecurrenceRule()
            }
        }
    }

    private var recurrenceRow: some View {
        Button { showRecurrencePicker = true } label: {
            HStack {
                Image(systemName: "repeat")
                    .foregroundColor(AppTheme.primaryColor)
                Text(recurrence.displayString)
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.subtleBorder))
        }
    }

    private var optionsSection: some View {
        VStack(spacing: 0) {
            Toggle(isOn: $isCritical) {
                HStack {
                    Image(systemName: "exclamationmark.shield")
                        .foregroundColor(AppTheme.criticalColor)
                    VStack(alignment: .leading) {
                        Text("Kritisk")
                        Text("Bryter igenom tyst läge")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
            .tint(AppTheme.criticalColor)
            .onChange(of: isCritical) { _, v in if v { priority = 2 } }
            .padding(16)

            Divider().padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "flag")
                        .foregroundColor(priority > 0 ? AppTheme.warningColor : AppTheme.textSecondary)
                    Text("Prioritet")
                }
                Picker("Prioritet", selection: $priority) {
                    Text("Normal").tag(0)
                    Text("Hög").tag(1)
                    Text("Kritisk").tag(2)
                }
                .pickerStyle(.segmented)
            }
            .padding(16)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.subtleBorder))
    }

    private var categoryField: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "tag")
                    .font(.system(size: 18))
                    .foregroundColor(AppTheme.textSecondary)
                TextField("Kategori (valfritt)", text: $categoryText)
                    .font(.system(size: 15))
                    .textInputAutocapitalization(.sentences)
                if !categoryText.isEmpty {
                    Button { categoryText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.subtleBorder))

            if !categories.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(categories, id: \.self) { cat in
                        Button { categoryText = cat } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 12))
                                Text(cat)
                                    .font(.system(size: 14))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(categoryText == cat ? AppTheme.primaryColor.opacity(0.1) : Color(hex: 0xF0F1F5))
                            .foregroundColor(categoryText == cat ? AppTheme.primaryColor : AppTheme.textPrimary)
                            .clipShape(Capsule())
                            .overlay(
                                categoryText == cat ?
                                Capsule().stroke(AppTheme.primaryColor, lineWidth: 1.5) : nil
                            )
                        }
                    }
                }

                Text("Tryck för att välja")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }

    private var deleteButton: some View {
        Button { showDeleteConfirm = true } label: {
            HStack {
                Image(systemName: "trash")
                Text("Ta bort påminnelse")
            }
            .foregroundColor(.red)
        }
    }

    // MARK: - Actions

    private func loadEditing() {
        guard let r = editingReminder else {
            titleFocused = true
            return
        }
        title = r.title
        notes = r.notes ?? ""
        categoryText = r.category ?? ""
        type = r.type
        dueDate = r.dueDate
        dueTime = r.dueDate
        recurrence = r.recurrence
        locationTrigger = r.locationTrigger
        isCritical = r.isCritical
        priority = r.priority
        showAdvanced = true
    }

    private func save() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        var fullDueDate: Date?
        if let d = dueDate {
            let cal = Calendar.current
            let time = dueTime ?? cal.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!
            fullDueDate = cal.date(bySettingHour: cal.component(.hour, from: time),
                                    minute: cal.component(.minute, from: time),
                                    second: 0, of: d)
        }

        let cat = categoryText.trimmingCharacters(in: .whitespaces).isEmpty ? nil : categoryText.trimmingCharacters(in: .whitespaces)

        if let r = editingReminder {
            r.title = title.trimmingCharacters(in: .whitespaces)
            r.notes = notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces)
            r.dueDate = fullDueDate
            r.type = type
            r.recurrence = recurrence
            r.locationTrigger = type == .locationBased ? locationTrigger : nil
            r.isCritical = isCritical
            r.category = cat
            r.priority = priority

            NotificationService.shared.cancelNotification(for: r.id)
            LocationService.shared.unregisterGeofence(for: r.id)

            if !r.isCompleted {
                if r.type == .standard, r.dueDate != nil {
                    NotificationService.shared.scheduleNotification(for: r)
                } else if r.type == .locationBased {
                    LocationService.shared.registerGeofence(for: r)
                }
            }
        } else {
            let reminder = Reminder(
                title: title.trimmingCharacters(in: .whitespaces),
                notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces),
                dueDate: fullDueDate,
                type: type,
                recurrence: recurrence,
                locationTrigger: type == .locationBased ? locationTrigger : nil,
                isCritical: isCritical,
                category: cat,
                priority: priority
            )
            modelContext.insert(reminder)

            if type == .standard, fullDueDate != nil {
                NotificationService.shared.scheduleNotification(for: reminder)
            }
            if type == .locationBased {
                LocationService.shared.registerGeofence(for: reminder)
            }
        }

        try? modelContext.save()
        // saved
        dismiss()
    }

    private func deleteAndDismiss() {
        guard let r = editingReminder else { return }
        NotificationService.shared.cancelNotification(for: r.id)
        LocationService.shared.unregisterGeofence(for: r.id)
        modelContext.delete(r)
        try? modelContext.save()
        // saved
        dismiss()
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
