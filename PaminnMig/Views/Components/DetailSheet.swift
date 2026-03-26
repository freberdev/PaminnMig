import SwiftUI

struct DetailSheet: View {
    let reminder: Reminder
    let onEdit: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var contentHeight: CGFloat = 200

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(reminder.title)
                .font(.system(size: 22, weight: .bold))
                .tracking(-0.5)
                .padding(.top, 8)

            if let notes = reminder.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineSpacing(4)
                    .padding(.top, 8)
            }

            VStack(spacing: 10) {
                if let due = reminder.dueDate {
                    detailRow(
                        icon: "clock",
                        text: DateHelpers.formatRelativeDate(due),
                        color: due < Date() && !reminder.isCompleted ? AppTheme.criticalColor : AppTheme.accentColor
                    )
                }

                if reminder.type == .locationBased, let loc = reminder.locationTrigger {
                    detailRow(icon: "location", text: loc.placeName ?? "Plats", color: AppTheme.warningColor)
                }

                if reminder.recurrence.type != .none {
                    detailRow(icon: "repeat", text: reminder.recurrence.displayString, color: AppTheme.accentColor)
                }

                if let cat = reminder.category {
                    detailRow(icon: "tag", text: cat, color: AppTheme.textSecondary)
                }

                if reminder.isCritical {
                    detailRow(icon: "exclamationmark.shield", text: "Kritisk", color: AppTheme.criticalColor)
                }

                if let snoozed = reminder.snoozedUntil, !reminder.isCompleted {
                    detailRow(icon: "moon.zzz", text: "Snoozad till \(DateHelpers.formatRelativeDate(snoozed))", color: AppTheme.warningColor)
                }

                if reminder.isCompleted, let completed = reminder.completedAt {
                    detailRow(icon: "checkmark.circle", text: "Klar \(DateHelpers.formatRelativeDate(completed))", color: AppTheme.successColor)
                }
            }
            .padding(.top, 16)

            Button {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onEdit() }
            } label: {
                HStack {
                    Image(systemName: "pencil")
                        .font(.system(size: 16))
                    Text("Redigera")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.accentColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.top, 20)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .background(
            GeometryReader { geo in
                Color.clear.onAppear {
                    contentHeight = geo.size.height + 40 // extra for drag indicator
                }
            }
        )
        .presentationDetents([.height(contentHeight)])
        .presentationDragIndicator(.visible)
    }

    private func detailRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(color)
            Spacer()
        }
    }
}
