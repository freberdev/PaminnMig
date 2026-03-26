import SwiftUI
import SwiftData

struct HomeScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Reminder.dueDate) private var allReminders: [Reminder]
    @State private var selectedTab = 0
    @State private var showingCreateSheet = false
    @State private var editingReminder: Reminder?
    @State private var detailReminder: Reminder?
    @State private var filterCategory: String?
    @State private var showingCategoryFilter = false
    @State private var showingSettings = false

    private var filteredReminders: [Reminder] {
        guard let cat = filterCategory else { return allReminders }
        return allReminders.filter { $0.category == cat }
    }

    private var activeReminders: [Reminder] { filteredReminders.filter { !$0.isCompleted } }
    private var completedReminders: [Reminder] { filteredReminders.filter { $0.isCompleted } }

    private var overdueReminders: [Reminder] {
        let now = Date()
        return activeReminders.filter { r in
            guard let due = r.dueDate, due < now else { return false }
            if let snoozed = r.snoozedUntil, snoozed > now { return false }
            return true
        }
    }

    private var todayReminders: [Reminder] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        let now = Date()
        let overdueIds = Set(overdueReminders.map(\.id))
        return activeReminders.filter { r in
            guard let due = r.dueDate, due >= start, due < end, !overdueIds.contains(r.id) else { return false }
            if let snoozed = r.snoozedUntil, snoozed > now { return false }
            return true
        }
    }

    private var categories: [String] {
        Array(Set(allReminders.compactMap(\.category))).sorted()
    }

    private var todayCount: Int {
        overdueReminders.count + todayReminders.count
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView
            tabSelector
                .padding(.top, 4)
            TabView(selection: $selectedTab) {
                todayTab.tag(0)
                allTab.tag(1)
                completedTab.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(AppTheme.backgroundColor)
        .overlay(alignment: .bottomTrailing) { fabButton }
        .sheet(isPresented: $showingCreateSheet) {
            CreateReminderScreen()
        }
        .sheet(item: $editingReminder) { reminder in
            CreateReminderScreen(editingReminder: reminder)
        }
        .sheet(item: $detailReminder) { reminder in
            DetailSheet(reminder: reminder) {
                editingReminder = reminder
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsScreen()
            }
        }
        .sheet(isPresented: $showingCategoryFilter) {
            CategoryFilterSheet(
                categories: categories,
                selectedCategory: $filterCategory,
                onDeleteCategory: deleteCategory
            )
            .presentationDetents([.medium])
        }
        .onAppear {
            LocationService.shared.registerAllGeofences(modelContext: modelContext)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openCreateReminder)) { _ in
            showingCreateSheet = true
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Påminn mig!")
                    .font(.system(size: 32, weight: .heavy))
                    .tracking(-1)
                Text(todayCount > 0
                     ? "\(todayCount) idag  ·  \(activeReminders.count) totalt"
                     : "\(activeReminders.count) påminnelser")
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
            if !categories.isEmpty {
                headerButton(
                    icon: "tag",
                    isActive: filterCategory != nil,
                    action: { showingCategoryFilter = true }
                )
            }
            headerButton(
                icon: "slider.horizontal.3",
                action: { showingSettings = true }
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    private func headerButton(icon: String, isActive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .frame(width: 42, height: 42)
                .background(isActive ? AppTheme.accentColor.opacity(0.08) : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isActive ? AppTheme.accentColor : AppTheme.subtleBorder, lineWidth: 1)
                )
        }
        .foregroundColor(isActive ? AppTheme.accentColor : AppTheme.textPrimary)
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            tabButton("Idag", index: 0)
            tabButton("Alla", index: 1)
            tabButton("Klara", index: 2)
        }
        .padding(4)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.subtleBorder))
        .padding(.horizontal, 24)
    }

    private func tabButton(_ label: String, index: Int) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) { selectedTab = index }
        } label: {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .tracking(-0.2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selectedTab == index ? AppTheme.primaryColor : Color.clear)
                .foregroundColor(selectedTab == index ? .white : AppTheme.textSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Tabs

    private var todayTab: some View {
        Group {
            if overdueReminders.isEmpty && todayReminders.isEmpty {
                emptyState(icon: "checkmark.seal", title: "Tomt idag", subtitle: "Inga påminnelser att ta hand om")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if !overdueReminders.isEmpty {
                            sectionLabel("FÖRSENADE", color: AppTheme.criticalColor)
                            ForEach(overdueReminders, id: \.id) { r in
                                ReminderCard(reminder: r, onComplete: { complete(r) }, onTap: { detailReminder = r }, onEdit: { editingReminder = r }, onDelete: { delete(r) })
                            }
                        }
                        if !todayReminders.isEmpty {
                            sectionLabel("IDAG", color: AppTheme.accentColor)
                            ForEach(todayReminders, id: \.id) { r in
                                ReminderCard(reminder: r, onComplete: { complete(r) }, onTap: { detailReminder = r }, onEdit: { editingReminder = r }, onDelete: { delete(r) })
                            }
                        }
                    }
                    .padding(.bottom, 100)
                    .padding(.top, 4)
                }
            }
        }
    }

    private var allTab: some View {
        Group {
            if activeReminders.isEmpty {
                emptyState(icon: "bell", title: "Inga påminnelser", subtitle: "Tryck + för att skapa din första")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        let standard = activeReminders.filter { $0.type == .standard }
                        let location = activeReminders.filter { $0.type == .locationBased }

                        if !standard.isEmpty {
                            sectionLabel("TIDSBASERADE", color: AppTheme.accentColor)
                            ForEach(standard, id: \.id) { r in
                                ReminderCard(reminder: r, onComplete: { complete(r) }, onTap: { detailReminder = r }, onEdit: { editingReminder = r }, onDelete: { delete(r) })
                            }
                        }
                        if !location.isEmpty {
                            sectionLabel("PLATSBASERADE", color: AppTheme.warningColor)
                            ForEach(location, id: \.id) { r in
                                ReminderCard(reminder: r, onComplete: { complete(r) }, onTap: { detailReminder = r }, onEdit: { editingReminder = r }, onDelete: { delete(r) })
                            }
                        }
                    }
                    .padding(.bottom, 100)
                    .padding(.top, 4)
                }
            }
        }
    }

    private var completedTab: some View {
        Group {
            if completedReminders.isEmpty {
                emptyState(icon: "checkmark.circle", title: "Inga avklarade", subtitle: "Klara påminnelser hamnar här")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(completedReminders, id: \.id) { r in
                            ReminderCard(reminder: r, onTap: { detailReminder = r }, onEdit: { editingReminder = r }, onDelete: { delete(r) })
                        }
                    }
                    .padding(.bottom, 100)
                    .padding(.top, 4)
                }
            }
        }
    }

    // MARK: - Common Components

    private func sectionLabel(_ label: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.8)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 28)
        .padding(.top, 18)
        .padding(.bottom, 8)
    }

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.accentColor.opacity(0.06))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 36))
                        .foregroundColor(AppTheme.accentColor.opacity(0.6))
                )
            Text(title)
                .font(.system(size: 18, weight: .bold))
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)
            Spacer()
        }
        .padding(.bottom, 60)
    }

    private var fabButton: some View {
        Button { showingCreateSheet = true } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 58, height: 58)
                .background(
                    LinearGradient(
                        colors: [Color(hex: 0xFF6B35), Color(hex: 0xFF8F5E)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: AppTheme.accentColor.opacity(0.3), radius: 20, y: 8)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }

    // MARK: - Actions

    private func complete(_ reminder: Reminder) {
        if reminder.recurrence.type != .none {
            if let nextDate = reminder.recurrence.getNextOccurrence(from: reminder.dueDate ?? Date()) {
                if reminder.recurrence.endDate == nil || nextDate < reminder.recurrence.endDate! {
                    let next = reminder.duplicate(dueDate: nextDate, isCompleted: false, completedAt: .some(nil), snoozedUntil: .some(nil))
                    modelContext.insert(next)
                    if next.type == .standard {
                        NotificationService.shared.scheduleNotification(for: next)
                    } else if next.type == .locationBased {
                        LocationService.shared.registerGeofence(for: next)
                    }
                }
            }
        }

        reminder.isCompleted = true
        reminder.completedAt = Date()
        NotificationService.shared.cancelNotification(for: reminder.id)
        LocationService.shared.unregisterGeofence(for: reminder.id)
        try? modelContext.save()
    }

    private func delete(_ reminder: Reminder) {
        NotificationService.shared.cancelNotification(for: reminder.id)
        LocationService.shared.unregisterGeofence(for: reminder.id)
        modelContext.delete(reminder)
        try? modelContext.save()
    }

    private func deleteCategory(_ category: String) {
        for r in allReminders where r.category == category {
            r.category = nil
        }
        if filterCategory == category { filterCategory = nil }
        try? modelContext.save()
    }
}
