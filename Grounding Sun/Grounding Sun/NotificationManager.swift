//
//  NotificationManager.swift
//  Grounding Sun
//
//  Created by Diana on 20/01/2026.
//

import Foundation
import UserNotifications
import os

@MainActor
final class NotificationManager: ObservableObject {
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    static let defaultDaysAhead = 14
    static let notificationTitle = "Grounding Sun"

    private weak var affirmationRepository: AffirmationRepository?
    private let logger = Logger(subsystem: "com.groundingsun", category: "NotificationManager")

    func setAffirmationRepository(_ repository: AffirmationRepository) {
        self.affirmationRepository = repository
    }

    func refreshAuthStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func requestPermission() async {
        do {
            _ = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthStatus()
        } catch {
            logger.error("Failed to request notification permission: \(error.localizedDescription)")
            await refreshAuthStatus()
        }
    }

    /// Schedules notifications for the next N days at the chosen time.
    func scheduleDailyNotifications(at time: Date, daysAhead: Int = defaultDaysAhead) async {
        await ensureAuthorized()

        guard let repository = affirmationRepository else {
            logger.warning("Cannot schedule notifications: affirmation repository is unavailable")
            return
        }

        // Remove previous scheduled ones
        let ids = (0..<daysAhead).map { "daily_affirmation_\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)

        let calendar = Calendar.current
        let timeComps = calendar.dateComponents([.hour, .minute], from: time)

        for offset in 0..<daysAhead {
            guard let dayDate = calendar.date(byAdding: .day, value: offset, to: Date()) else { continue }
            let affirmation = repository.assignedAffirmation(for: dayDate)

            var comps = calendar.dateComponents([.year, .month, .day], from: dayDate)
            comps.hour = timeComps.hour
            comps.minute = timeComps.minute

            let content = UNMutableNotificationContent()
            content.title = Self.notificationTitle
            content.body = affirmation.text
            content.sound = .default
            content.userInfo = ["affirmationId": affirmation.id]

            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(
                identifier: "daily_affirmation_\(offset)",
                content: content,
                trigger: trigger
            )

            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                logger.error("Failed to schedule notification for day +\(offset): \(error.localizedDescription)")
            }
        }
    }

    func cancelScheduledDailyNotifications(daysAhead: Int = defaultDaysAhead) {
        let ids = (0..<daysAhead).map { "daily_affirmation_\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    private func ensureAuthorized() async {
        await refreshAuthStatus()
        if authorizationStatus == .notDetermined {
            await requestPermission()
        }
    }
}
