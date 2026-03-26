import SwiftUI
import SwiftData

struct ReminderCard: View {
    let reminder: Reminder
    var onComplete: (() -> Void)?
    var onTap: (() -> Void)?
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    @State private var offset: CGFloat = 0
    @State private var showingSnooze = false
    @State private var showingDeleteConfirm = false
    @Environment(\.modelContext) private var modelContext

    private let actionWidth: CGFloat = 72
    private var totalReveal: CGFloat { actionWidth * 2 }

    private var isOverdue: Bool {
        guard let due = reminder.dueDate, !reminder.isCompleted else { return false }
        return due < Date()
    }

    var body: some View {
        cardContent
            .offset(x: offset)
            .background(alignment: .trailing) {
                HStack(spacing: 0) {
                    Button {
                        withAnimation(.spring(duration: 0.25)) { offset = 0 }
                        onEdit?()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "pencil")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Redigera")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(width: actionWidth)
                        .frame(maxHeight: .infinity)
                        .background(AppTheme.accentColor)
                    }

                    Button {
                        withAnimation(.spring(duration: 0.25)) { offset = 0 }
                        showingDeleteConfirm = true
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Radera")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(width: actionWidth)
                        .frame(maxHeight: .infinity)
                        .background(AppTheme.criticalColor)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = min(0, max(-totalReveal, value.translation.width))
                    }
                    .onEnded { value in
                        withAnimation(.spring(duration: 0.3, bounce: 0.15)) {
                            if value.predictedEndTranslation.width < -80 || offset < -totalReveal / 2 {
                                offset = -totalReveal
                            } else {
                                offset = 0
                            }
                        }
                    }
            )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 20)
        .padding(.vertical, 5)
        .confirmationDialog("Radera påminnelse", isPresented: $showingDeleteConfirm) {
            Button("Radera", role: .destructive) { onDelete?() }
            Button("Avbryt", role: .cancel) {}
        } message: {
            Text("Vill du radera \"\(reminder.title)\"?")
        }
        .sheet(isPresented: $showingSnooze) {
            SnoozeSheet(reminder: reminder)
                .presentationDetents([.medium, .large])
        }
    }

    private var cardContent: some View {
        HStack(alignment: .top, spacing: 14) {
            // Checkbox
            Button {
                if offset < 0 {
                    withAnimation { offset = 0 }
                } else {
                    onComplete?()
                }
            } label: {
                checkbox
            }
            .padding(.top, 2)

            // Content
            VStack(alignment: .leading, spacing: 3) {
                Text(reminder.title)
                    .font(.system(size: 16, weight: .medium))
                    .tracking(-0.3)
                    .strikethrough(reminder.isCompleted)
                    .foregroundColor(reminder.isCompleted ? AppTheme.textSecondary : AppTheme.textPrimary)

                if let notes = reminder.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(1)
                }

                if let cat = reminder.category {
                    HStack(spacing: 3) {
                        Image(systemName: "tag")
                            .font(.system(size: 12))
                        Text(cat)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.top, 2)
                }
            }

            Spacer()

            // Snooze button
            if !reminder.isCompleted {
                Button { showingSnooze = true } label: {
                    Image(systemName: "moon.zzz")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.textSecondary.opacity(0.5))
                        .padding(6)
                }
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 12)
        .padding(.vertical, 14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    isOverdue ? AppTheme.criticalColor.opacity(0.24) :
                        reminder.isCritical ? AppTheme.criticalColor.opacity(0.16) :
                        AppTheme.subtleBorder,
                    lineWidth: 1
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if offset < 0 {
                withAnimation { offset = 0 }
            } else {
                onTap?()
            }
        }
    }

    @ViewBuilder
    private var checkbox: some View {
        if reminder.isCompleted {
            RoundedRectangle(cornerRadius: 8)
                .fill(AppTheme.successColor)
                .frame(width: 24, height: 24)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                )
        } else {
            let color = reminder.isCritical ? AppTheme.criticalColor :
                        reminder.priority > 0 ? AppTheme.warningColor : AppTheme.accentColor
            RoundedRectangle(cornerRadius: 8)
                .stroke(color, lineWidth: 2)
                .fill(color.opacity(0.04))
                .frame(width: 24, height: 24)
                .overlay {
                    if reminder.isCritical {
                        Image(systemName: "exclamationmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(color)
                    }
                }
        }
    }
}

// MARK: - Snooze Sheet

struct SnoozeSheet: View {
    let reminder: Reminder
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showDatePicker = false
    @State private var pickedDate = Date()
    @State private var pickedTime = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sheetHandle
            Text("Snooze")
                .font(.system(size: 22, weight: .bold))
                .tracking(-0.5)
                .padding(.top, 20)
            Text(reminder.title)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)
                .lineLimit(1)
                .padding(.top, 4)
                .padding(.bottom, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(SnoozeOption.smartOptions()) { opt in
                        Button {
                            snooze(until: opt.snoozeTime)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "clock")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppTheme.accentColor)
                                Text(opt.label)
                                    .font(.system(size: 15))
                                    .foregroundColor(AppTheme.textPrimary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                        }
                    }

                    Button {
                        showDatePicker = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.accentColor)
                            Text("Välj datum och tid...")
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .sheet(isPresented: $showDatePicker) {
            VStack {
                DatePicker("Datum", selection: $pickedDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .environment(\.locale, Locale(identifier: "sv"))
                Button("Snooze") {
                    snooze(until: pickedDate)
                    showDatePicker = false
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accentColor)
            }
            .padding()
            .presentationDetents([.medium])
        }
    }

    private func snooze(until date: Date) {
        reminder.snoozedUntil = date
        try? modelContext.save()

        let temp = reminder.duplicate(dueDate: date)
        NotificationService.shared.scheduleNotification(for: temp)
        dismiss()
    }

    private var sheetHandle: some View {
        Capsule()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 36, height: 4)
            .frame(maxWidth: .infinity)
            .padding(.top, 16)
    }
}
