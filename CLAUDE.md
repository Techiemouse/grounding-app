# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Grounding Sun is a minimalist SwiftUI app (iOS + macOS) that delivers a single, consistent daily affirmation through notifications and a calm interface — designed to support grounding and emotional presence. The app assigns one affirmation per day, persists it in UserDefaults, and allows users to schedule daily reminder notifications.

## Building and Testing

**Open the project:**
```bash
open "Grounding Sun/Grounding Sun.xcodeproj"
```

**Build and run:**
- Use Xcode's standard build (⌘B) and run (⌘R) commands
- Targets: iOS 17.5+, macOS 14.3+
- Multi-platform: `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx"` — use `#if os(iOS)` for platform-specific code (e.g. `UIApplication`)

**Testing:**
- Unit tests: `Grounding SunTests/Grounding_SunTests.swift` — run with ⌘U
- UI tests: `Grounding SunUITests/`
- Tests use isolated `UserDefaults(suiteName:)` and a `TestAPIClient` mock to avoid shared state

## Architecture

### File Structure

```
Grounding Sun/
├── Grounding_SunApp.swift        # App entry point, environment injection, migration
├── ContentView.swift             # Main UI + settings sheet
├── AffirmationStore.swift        # Affirmation model + AffirmationRepository
├── NotificationManager.swift     # Local notification scheduling
├── Theme/
│   ├── AppTheme.swift            # Color definitions (light/dark, Equatable)
│   └── ThemeManager.swift        # Time-based auto theme + manual override
├── Services/
│   ├── APIClient.swift           # Protocol defining data contract
│   ├── APIModels.swift           # AffirmationDTO
│   ├── MockAPIClient.swift       # Hardcoded affirmation data (37 affirmations)
│   └── ProductionAPIClient.swift # Stub for future backend (throws .notImplemented)
└── Models/                       # Currently empty (Exercise model was removed)
```

### Core Components

**AffirmationStore.swift** — Data layer
- `Affirmation`: Model with `id` and `text` (Identifiable, Codable, Hashable)
- `AffirmationRepository` (`@MainActor ObservableObject`): Fetches from APIClient, caches to UserDefaults, assigns affirmations by date
  - Dependency injection: accepts `APIClient` and `UserDefaults` in init (defaults to `MockAPIClient` and `.standard`)
  - Persists assignments by date key (yyyy-MM-dd) in `"assigned_affirmations_by_date"`
  - Caches fetched affirmations in `"cached_affirmations"` — falls back to cache on API failure
  - Uses `os.Logger` for error logging

**NotificationManager.swift** — Notification handling
- `@MainActor` observable object managing UNUserNotificationCenter
- Schedules notifications for multiple days ahead (default: `defaultDaysAhead = 14`)
- Notification identifiers: `"daily_affirmation_{offset}"`
- Notification title constant: `notificationTitle = "Grounding Sun"`
- Uses `os.Logger` — no silent `try?`, all errors are logged

**ContentView.swift** — UI layer (two parts)
- **Main screen:** App title, centered affirmation card (serif font, fade animation), "New Quote" capsule button, gear icon overlay for settings
- **Settings sheet** (`.presentationDetents([.medium])`): Light/Dark segmented picker, daily reminder toggle + time picker, notification denied message with Settings link (iOS only via `#if os(iOS)`)
- `@AppStorage("dailyReminderEnabled")` persists reminder toggle
- Reminder time saved as hour/minute integers in UserDefaults (`dailyReminderHour`, `dailyReminderMinute`)
- `schedulingTask` state cancels previous notification scheduling tasks before starting new ones (prevents race conditions)
- Accessibility: labels and hints on all interactive elements

**Theme/AppTheme.swift** — Color definitions
- `enum AppTheme: Equatable` with `.light` and `.dark` cases
- Light: warm peach-to-gold gradient, dark brown text for accessibility
- Dark: navy-to-plum gradient, white text
- Properties: `gradientColors`, `cardBackground`, `textPrimary`, `textSecondary`, `buttonBackground`, `buttonText`

**Theme/ThemeManager.swift** — Theme controller
- `ThemeMode` enum: `.light`, `.dark` (no auto option in UI)
- Auto-switching based on time of day runs silently via 60-second timer (default on first launch)
- `dayHourRange = 6...18` — static constant for light hours
- Manual selection via `setManualTheme()` disables auto-switching
- Persists: `"autoThemeEnabled"` (Bool), `"manualTheme"` (String)

**Services/** — API abstraction
- `APIClient` protocol: `fetchAffirmations() async throws -> [AffirmationDTO]`
- `MockAPIClient`: Returns 37 hardcoded affirmations with 0.5s simulated delay
- `ProductionAPIClient`: Stub that throws `APIError.notImplemented` (base URL: `api.groundingsun.com`)
- `APIError`: `notImplemented`, `networkError(Error)`, `decodingError(Error)` — conforms to `LocalizedError`

### Key Patterns

**Date-based persistence:** Affirmations are stored by date string (yyyy-MM-dd) in UserDefaults, not by assignment order. Same date always returns the same affirmation unless explicitly rerolled.

**Notification scheduling:** When reminders are enabled, the app schedules 14 days of notifications at once. Each notification gets the affirmation pre-assigned for that date. Reroll or settings changes cancel and reschedule all pending notifications. Previous scheduling tasks are cancelled before new ones start.

**Theme auto-switching:** On first launch, theme follows time of day (light 6am–6pm, dark otherwise). When user manually picks Light or Dark in settings, auto-switching is disabled and their choice persists. Timer checks every 60 seconds but only acts if auto is still enabled.

**Animation:** Affirmation text uses `.id(affirmation.id)` + `.transition(.opacity)` + `withAnimation(.easeInOut(duration: 0.6))` for smooth crossfade on load and reroll.

**Dependency injection:** `AffirmationRepository` accepts `APIClient` and `UserDefaults` in its initializer, making it fully testable with isolated state.

## Testing

Unit tests cover 4 areas (18 tests total):
- **AffirmationRepositoryTests** (8 tests): fetch, cache, fallback on error, assignment consistency, persistence across instances, fallback when empty, reroll, reroll persistence
- **ThemeManagerTests** (3 tests): auto theme by time, manual override, restore to auto
- **AffirmationModelTests** (2 tests): Codable round-trip, Hashable/Set deduplication
- **AppThemeTests** (4 tests): gradient colors, equatable, light vs dark text contrast

Tests use `TestAPIClient` (controllable mock) and `UserDefaults(suiteName:)` for isolation.

## Development Notes

- Multi-platform (iOS + macOS) — guard platform-specific APIs with `#if os(iOS)`
- UserDefaults for all persistence (no Core Data or external database)
- Notifications are local only, no backend service
- `os.Logger` used for error logging (subsystem: `com.groundingsun`)
- Migration flag `"migration_v1_complete"` in `Grounding_SunApp.init()` clears old affirmation IDs on first run
- The Models/ directory is empty — Exercise feature was removed as dead code (can be restored from git history)
- ProductionAPIClient is a stub — swap MockAPIClient when backend is ready
