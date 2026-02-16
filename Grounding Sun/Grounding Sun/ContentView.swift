//
//  ContentView.swift
//  Grounding Sun
//
//  Created by Diana on 12/01/2026.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var affirmationRepository: AffirmationRepository
    @StateObject private var notifications = NotificationManager()
    @Environment(\.openURL) private var openURL

    @AppStorage("dailyReminderEnabled") private var dailyEnabled: Bool = false
    @State private var dailyTime: Date =
        Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()

    @State private var today: Date = Date()
    @State private var todaysAffirmation: Affirmation = Affirmation(id: "loading", text: "Loading...")
    @State private var showSettings = false
    @State private var schedulingTask: Task<Void, Never>?

    private enum Keys {
        static let reminderHour = "dailyReminderHour"
        static let reminderMinute = "dailyReminderMinute"
    }

    private let animationDuration = 0.6
    private let themeUpdateInterval: TimeInterval = 60

    // MARK: - Helpers

    private func updateTodaysAffirmation() {
        withAnimation(.easeInOut(duration: animationDuration)) {
            todaysAffirmation = affirmationRepository.assignedAffirmation(for: today)
        }
    }

    private func loadSavedTime() {
        guard UserDefaults.standard.object(forKey: Keys.reminderHour) != nil else { return }
        let hour = UserDefaults.standard.integer(forKey: Keys.reminderHour)
        let minute = UserDefaults.standard.integer(forKey: Keys.reminderMinute)
        dailyTime = Calendar.current.date(
            bySettingHour: hour, minute: minute, second: 0, of: Date()
        ) ?? dailyTime
    }

    private func saveTime() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: dailyTime)
        UserDefaults.standard.set(comps.hour ?? 9, forKey: Keys.reminderHour)
        UserDefaults.standard.set(comps.minute ?? 0, forKey: Keys.reminderMinute)
    }

    private func scheduleNotifications() {
        schedulingTask?.cancel()
        schedulingTask = Task {
            await notifications.scheduleDailyNotifications(at: dailyTime)
        }
    }

    private var themeModeBinding: Binding<ThemeMode> {
        Binding(
            get: { themeManager.currentTheme == .dark ? .dark : .light },
            set: { mode in
                switch mode {
                case .light: themeManager.setManualTheme(.light)
                case .dark: themeManager.setManualTheme(.dark)
                }
            }
        )
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: themeManager.currentTheme.gradientColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Grounding Sun")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(themeManager.currentTheme.textSecondary)
                    .padding(.top, 16)

                Spacer()

                // Affirmation card
                Text(todaysAffirmation.text)
                    .font(.title3.weight(.medium))
                    .fontDesign(.serif)
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(themeManager.currentTheme.cardBackground)
                    )
                    .padding(.horizontal, 32)
                    .id(todaysAffirmation.id)
                    .transition(.opacity)
                    .accessibilityLabel(todaysAffirmation.text)
                    .accessibilityHint("Today's affirmation")

                // New Quote button
                Button {
                    withAnimation(.easeInOut(duration: animationDuration)) {
                        todaysAffirmation = affirmationRepository.reroll(for: Date())
                        today = Date()
                    }
                    if dailyEnabled {
                        scheduleNotifications()
                    }
                } label: {
                    Label("New Quote", systemImage: "arrow.trianglehead.2.clockwise")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(themeManager.currentTheme.buttonText)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(themeManager.currentTheme.buttonBackground)
                        )
                }
                .accessibilityHint("Generates a new affirmation for today")
                .padding(.top, 8)

                Spacer()
            }
        }
        .overlay(alignment: .topTrailing) {
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.title3)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
                    .padding(20)
            }
            .accessibilityLabel("Settings")
            .accessibilityHint("Adjust theme and notifications")
        }
        .sheet(isPresented: $showSettings) {
            settingsSheet
        }
        .task {
            notifications.setAffirmationRepository(affirmationRepository)
            await affirmationRepository.fetchAffirmations()
            await notifications.refreshAuthStatus()

            loadSavedTime()
            if dailyEnabled {
                scheduleNotifications()
            }
        }
        .onAppear {
            updateTodaysAffirmation()
        }
        .onChange(of: affirmationRepository.affirmations) { _, _ in
            updateTodaysAffirmation()
        }
        .onReceive(Timer.publish(every: themeUpdateInterval, on: .main, in: .common).autoconnect()) { _ in
            themeManager.updateBasedOnTime()
        }
    }

    // MARK: - Settings Sheet

    private var settingsSheet: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: themeManager.currentTheme.gradientColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Settings")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                    .padding(.top, 20)

                VStack(spacing: 16) {
                    // Theme picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Appearance")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(themeManager.currentTheme.textSecondary)

                        Picker("Appearance", selection: themeModeBinding) {
                            ForEach(ThemeMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Divider().overlay(Color.white.opacity(0.2))

                    // Daily reminder
                    Toggle("Daily reminder", isOn: $dailyEnabled)
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                        .tint(.white.opacity(0.6))
                        .onChange(of: dailyEnabled) { _, enabled in
                            if enabled {
                                scheduleNotifications()
                            } else {
                                schedulingTask?.cancel()
                                notifications.cancelScheduledDailyNotifications()
                            }
                        }
                        .accessibilityHint("Send a daily affirmation at your chosen time")

                    if dailyEnabled {
                        DatePicker("Time", selection: $dailyTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .tint(themeManager.currentTheme.buttonText)
                            .foregroundColor(themeManager.currentTheme.textPrimary)
                            .onChange(of: dailyTime) { _, _ in
                                saveTime()
                                scheduleNotifications()
                            }
                            .accessibilityHint("Choose what time to receive your daily affirmation")
                    }

                    // Notification denied
                    if notifications.authorizationStatus == .denied {
                        Divider().overlay(Color.white.opacity(0.2))

                        #if os(iOS)
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                openURL(url)
                            }
                        } label: {
                            Label("Notifications are off — tap to open Settings", systemImage: "bell.slash")
                                .font(.footnote)
                                .foregroundColor(themeManager.currentTheme.textSecondary)
                        }
                        .accessibilityLabel("Open Settings to enable notifications")
                        #else
                        Label("Notifications are off — enable in System Settings", systemImage: "bell.slash")
                            .font(.footnote)
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                        #endif
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(themeManager.currentTheme.cardBackground)
                )

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager())
        .environmentObject(AffirmationRepository())
}
