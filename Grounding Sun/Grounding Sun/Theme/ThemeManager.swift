//
//  ThemeManager.swift
//  Grounding Sun
//
//  Observable theme controller with time-based switching and manual override
//

import SwiftUI

enum ThemeMode: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
}

@MainActor
class ThemeManager: ObservableObject {
    /// Hours considered daytime for auto-theme (6 AM through 6 PM inclusive)
    static let dayHourRange = 6...18

    @Published var currentTheme: AppTheme
    @Published var autoThemeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoThemeEnabled, forKey: "autoThemeEnabled")
            if autoThemeEnabled {
                updateBasedOnTime()
            }
        }
    }

    private let userDefaults = UserDefaults.standard
    private let autoThemeKey = "autoThemeEnabled"
    private let manualThemeKey = "manualTheme"

    init() {
        // Load persisted auto theme preference
        let savedAutoTheme = userDefaults.object(forKey: autoThemeKey) as? Bool ?? true

        // Initialize properties first
        if savedAutoTheme {
            // Auto-theme enabled: set based on current time
            let hour = Calendar.current.component(.hour, from: Date())
            self.currentTheme = Self.dayHourRange.contains(hour) ? .light : .dark
            self.autoThemeEnabled = true
        } else {
            // Auto-theme disabled: load manual preference
            let savedTheme = userDefaults.string(forKey: manualThemeKey) ?? "light"
            self.currentTheme = savedTheme == "dark" ? .dark : .light
            self.autoThemeEnabled = false
        }
    }

    func updateBasedOnTime() {
        guard autoThemeEnabled else { return }

        let hour = Calendar.current.component(.hour, from: Date())
        let newTheme: AppTheme = Self.dayHourRange.contains(hour) ? .light : .dark

        if currentTheme != newTheme {
            currentTheme = newTheme
        }
    }

    func setManualTheme(_ theme: AppTheme) {
        autoThemeEnabled = false
        currentTheme = theme

        // Persist manual theme choice
        let themeString = theme == .dark ? "dark" : "light"
        userDefaults.set(themeString, forKey: manualThemeKey)
    }

    func enableAutoTheme() {
        autoThemeEnabled = true
        updateBasedOnTime()
    }
}
