//
//  ScheduleView.swift
//  WaterTracker
//
//  Created by Jackson  on 10/09/2025.
//

import SwiftUI
import UserNotifications
import RevenueCatUI

struct ScheduleView: View {
    @StateObject private var notifications = NotificationsManager.shared
    @StateObject private var rc = RevenueCatMonitor.shared
    @State private var isPresentingAdd: Bool = false
    @State private var newTime: Date = .init()
    @State private var reminders: [Reminder] = []
    @State private var loading: Bool = false
    @State private var isShowingPaywall: Bool = false

    struct Reminder: Identifiable, Hashable {
        let id: String
        var hour: Int
        var minute: Int

        var date: Date {
            var comps = DateComponents()
            comps.hour = hour
            comps.minute = minute
            return Calendar.current.date(from: comps) ?? Date()
        }

        var timeString: String {
            date.formatted(date: .omitted, time: .shortened)
        }
    }

    var body: some View {
        Group {
            switch notifications.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                content
            case .denied:
                deniedView
            case .notDetermined:
                requestView
            @unknown default:
                requestView
            }
        }
        .navigationTitle(String(localized: "Water Reminders"))
        .task { await loadReminders() }
        .onReceive(notifications.$authorizationStatus) { _ in
            Task { await loadReminders() }
        }
        .sheet(isPresented: $isPresentingAdd) { addReminderSheet }
        .sheet(isPresented: $isShowingPaywall) { PaywallView() }
    }

    private var content: some View {
        VStack(spacing: 20) {
            headerCard
            if loading {
                ProgressView()
            }
            if reminders.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(reminders) { reminder in
                            reminderRow(reminder)
                        }
//                        .onDeleteDisabled(true)
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
            }
            addButton
                .padding(.horizontal)
        }
    }

    private var requestView: some View {
        VStack(spacing: 24) {
            headerCard
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 54))
                .foregroundStyle(.blue)
            Text(String(localized: "Stay on track with friendly reminders"))
                .multilineTextAlignment(.center)
                .font(.title3.weight(.semibold))
                .padding(.horizontal)
            PrimaryButton(
                title: String(localized: "Enable Notifications"),
                systemImage: "bell.fill",
                colors: [.blue, .cyan]
            ) {
                Task { let _ = await notifications.requestAuthorization() }
            }
            .padding(.horizontal)
            Spacer()
        }
    }

    private var deniedView: some View {
        VStack(spacing: 24) {
            headerCard
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 54))
                .foregroundStyle(.red)
            Text(String(localized: "Notifications are turned off"))
                .font(.title3.weight(.semibold))
            Text(String(localized: "Turn on notifications in Settings to receive water reminders."))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            PrimaryButton(
                title: String(localized: "Open Settings"),
                systemImage: "gear",
                colors: [.blue, .cyan]
            ) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .padding(.horizontal)
            Spacer()
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundStyle(.white)
                Text(String(localized: "Hydration Schedule"))
                    .foregroundStyle(.white)
                    .font(.headline)
                Spacer()
            }
            Text(String(localized: "Add times to get a nudge to drink water throughout your day."))
                .foregroundStyle(.white.opacity(0.9))
                .font(.subheadline)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal)
        .padding(.top)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text(String(localized: "No reminders yet"))
                .font(.headline)
            Text(String(localized: "Tap Add Reminder to choose your first time."))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 16)
    }

    private func reminderRow(_ reminder: Reminder) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: "bell.fill")
                    .foregroundStyle(.blue)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.timeString)
                    .font(.title3.weight(.semibold))
                Text(String(localized: "Daily"))
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
            Spacer()
            Menu {
                Button(role: .destructive) {
                    deleteReminder(reminder)
                } label: {
                    Label(String(localized: "Delete"), systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.blue.opacity(0.15))
        )
    }

    private var addButton: some View {
        PrimaryButton(
            title: String(localized: "Add Reminder"),
            systemImage: "plus",
            colors: [.blue, .cyan]
        ) {
            Task { await handleAddTapped() }
        }
    }

    private var addReminderSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                DatePicker(String(localized: "Time"), selection: $newTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .environment(\ .locale, Locale(identifier: Locale.current.identifier))
                    .padding(.top)
                PrimaryButton(
                    title: String(localized: "Save"),
                    systemImage: "checkmark.circle.fill",
                    colors: [.blue, .cyan],
                    isDisabled: !canSchedule
                ) {
                    Task { await addReminder() }
                }
                .padding(.top)
                Spacer()
            }
            .padding()
            .navigationTitle(String(localized: "New Reminder"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { isPresentingAdd = false }
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    private func handleAddTapped() async {
        // If user is not subscribed and already has >= 1 reminder, show paywall
        if rc.userHasFullAccess == false {
            let current = await notifications.listPendingReminders()
            if current.count >= 1 {
                await MainActor.run { isShowingPaywall = true }
                return
            }
        }
        await MainActor.run {
            newTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
            isPresentingAdd = true
        }
    }

    private var canSchedule: Bool {
        switch notifications.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    private func addReminder() async {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: newTime)
        guard let hour = comps.hour, let minute = comps.minute else { return }
        do {
            let newId = UUID().uuidString
            let id = try await notifications.scheduleDailyReminder(id: newId, hour: hour, minute: minute)
            reminders.append(.init(id: id, hour: hour, minute: minute))
            reminders.sort(by: { $0.hour * 60 + $0.minute < $1.hour * 60 + $1.minute })
            isPresentingAdd = false
        } catch {
            // silently fail for now
        }
    }

    private func deleteReminder(_ reminder: Reminder) {
        notifications.cancelReminder(id: reminder.id)
        reminders.removeAll { $0.id == reminder.id }
    }

    private func loadReminders() async {
        loading = true
        let requests = await notifications.listPendingReminders()
        let calendar = Calendar.current
        var mapped: [Reminder] = []
        for r in requests {
            if let trigger = r.trigger as? UNCalendarNotificationTrigger,
               let hour = trigger.dateComponents.hour,
               let minute = trigger.dateComponents.minute,
               trigger.repeats {
                mapped.append(.init(id: r.identifier, hour: hour, minute: minute))
            }
        }
        mapped.sort(by: { $0.hour * 60 + $0.minute < $1.hour * 60 + $1.minute })
        await MainActor.run {
            self.reminders = mapped
            self.loading = false
        }
    }

    private func primaryButtonLabel(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
            Text(title)
                .fontWeight(.semibold)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .blue.opacity(0.25), radius: 10, x: 0, y: 6)
    }
}

extension ScheduleView {
    @ViewBuilder
    var paywallSheet: some View {
        PaywallView()
    }
}

#Preview {
    NavigationStack {
        ScheduleView()
    }
}
