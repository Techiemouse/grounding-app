//
//  Grounding_SunApp.swift
//  Grounding Sun
//
//  Created by Diana on 12/01/2026.
//

import SwiftUI

@main
struct Grounding_SunApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var affirmationRepository = AffirmationRepository()

    init() {
        // Clear old affirmation assignments that use old IDs (a1, a2, etc.)
        // This ensures we start fresh with new MockAPI data
        if UserDefaults.standard.object(forKey: "migration_v1_complete") == nil {
            UserDefaults.standard.removeObject(forKey: "assigned_affirmations_by_date")
            UserDefaults.standard.set(true, forKey: "migration_v1_complete")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .environmentObject(affirmationRepository)
        }
    }
}
