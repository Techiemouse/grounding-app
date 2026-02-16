//
//  AppTheme.swift
//  Grounding Sun
//
//  Theme definitions and color schemes
//

import SwiftUI

enum AppTheme: Equatable {
    case light
    case dark

    var gradientColors: [Color] {
        switch self {
        case .light:
            // Soft peach → Warm gold
            return [Color(red: 0.95, green: 0.75, blue: 0.62), Color(red: 0.98, green: 0.88, blue: 0.55)]
        case .dark:
            // Deep navy → Muted plum
            return [Color(red: 0.08, green: 0.10, blue: 0.28), Color(red: 0.30, green: 0.15, blue: 0.32)]
        }
    }

    var cardBackground: Color {
        switch self {
        case .light:
            return Color.white.opacity(0.35)
        case .dark:
            return Color.white.opacity(0.1)
        }
    }

    var textPrimary: Color {
        switch self {
        case .light:
            // Deep warm brown
            return Color(red: 0.24, green: 0.17, blue: 0.12)
        case .dark:
            return .white
        }
    }

    var textSecondary: Color {
        switch self {
        case .light:
            // Slightly lighter warm brown
            return Color(red: 0.32, green: 0.24, blue: 0.18)
        case .dark:
            return Color.white.opacity(0.9)
        }
    }

    var buttonBackground: Color {
        switch self {
        case .light:
            return Color(red: 0.24, green: 0.17, blue: 0.12).opacity(0.15)
        case .dark:
            return Color.white.opacity(0.3)
        }
    }

    var buttonText: Color {
        switch self {
        case .light:
            return Color(red: 0.24, green: 0.17, blue: 0.12)
        case .dark:
            return .white
        }
    }
}
