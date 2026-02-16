//
//  Grounding_SunTests.swift
//  Grounding SunTests
//
//  Created by Diana on 12/01/2026.
//

import XCTest
@testable import Grounding_Sun

// MARK: - Test API Client

/// A synchronous mock that returns instantly with controlled data
class TestAPIClient: APIClient {
    var affirmationsToReturn: [AffirmationDTO] = []
    var shouldThrow: Error?

    func fetchAffirmations() async throws -> [AffirmationDTO] {
        if let error = shouldThrow { throw error }
        return affirmationsToReturn
    }
}

// MARK: - AffirmationRepository Tests

@MainActor
final class AffirmationRepositoryTests: XCTestCase {

    private var suiteName: String!
    private var testDefaults: UserDefaults!
    private var testAPI: TestAPIClient!

    override func setUp() {
        super.setUp()
        suiteName = "test.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: suiteName)!
        testAPI = TestAPIClient()
        testAPI.affirmationsToReturn = [
            AffirmationDTO(id: "t1", text: "Test affirmation one"),
            AffirmationDTO(id: "t2", text: "Test affirmation two"),
            AffirmationDTO(id: "t3", text: "Test affirmation three")
        ]
    }

    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        testDefaults = nil
        testAPI = nil
        super.tearDown()
    }

    private func makeRepository() -> AffirmationRepository {
        AffirmationRepository(apiClient: testAPI, cache: testDefaults)
    }

    // MARK: - Fetch Tests

    func testFetchLoadsAffirmationsFromAPI() async {
        let repo = makeRepository()
        await repo.fetchAffirmations()

        XCTAssertEqual(repo.affirmations.count, 3)
        XCTAssertEqual(repo.affirmations[0].id, "t1")
        XCTAssertEqual(repo.affirmations[0].text, "Test affirmation one")
        XCTAssertFalse(repo.isLoading)
        XCTAssertNil(repo.error)
    }

    func testFetchSetsErrorOnFailure() async {
        testAPI.shouldThrow = NSError(domain: "test", code: 1)
        let repo = makeRepository()
        await repo.fetchAffirmations()

        XCTAssertNotNil(repo.error)
        XCTAssertFalse(repo.isLoading)
    }

    func testFetchCachesAffirmations() async {
        let repo = makeRepository()
        await repo.fetchAffirmations()

        // Create a new repo with the same cache — it should load from cache
        let repo2 = AffirmationRepository(apiClient: TestAPIClient(), cache: testDefaults)
        XCTAssertEqual(repo2.affirmations.count, 3)
        XCTAssertEqual(repo2.affirmations[0].id, "t1")
    }

    func testFetchFallsBackToCacheOnError() async {
        // First fetch succeeds and caches
        let repo = makeRepository()
        await repo.fetchAffirmations()
        XCTAssertEqual(repo.affirmations.count, 3)

        // Second fetch fails — should keep cached data
        testAPI.shouldThrow = NSError(domain: "test", code: 1)
        let repo2 = AffirmationRepository(apiClient: testAPI, cache: testDefaults)
        await repo2.fetchAffirmations()

        XCTAssertEqual(repo2.affirmations.count, 3, "Should retain cached affirmations on error")
    }

    // MARK: - Assignment Tests

    func testAssignedAffirmationReturnsSameForSameDate() async {
        let repo = makeRepository()
        await repo.fetchAffirmations()

        let date = Date()
        let first = repo.assignedAffirmation(for: date)
        let second = repo.assignedAffirmation(for: date)

        XCTAssertEqual(first.id, second.id, "Same date should always return the same affirmation")
    }

    func testAssignedAffirmationPersistsAcrossInstances() async {
        let repo = makeRepository()
        await repo.fetchAffirmations()

        let date = Date()
        let assigned = repo.assignedAffirmation(for: date)

        // New repo instance with same cache
        let repo2 = AffirmationRepository(apiClient: testAPI, cache: testDefaults)
        await repo2.fetchAffirmations()
        let reassigned = repo2.assignedAffirmation(for: date)

        XCTAssertEqual(assigned.id, reassigned.id, "Assignment should persist across instances")
    }

    func testAssignedAffirmationReturnsFallbackWhenEmpty() {
        let emptyAPI = TestAPIClient()
        emptyAPI.affirmationsToReturn = []
        let repo = AffirmationRepository(apiClient: emptyAPI, cache: testDefaults)

        let result = repo.assignedAffirmation(for: Date())
        XCTAssertEqual(result.id, "fallback")
        XCTAssertEqual(result.text, "You are enough.")
    }

    // MARK: - Reroll Tests

    func testRerollUpdatesAssignment() async {
        let repo = makeRepository()
        await repo.fetchAffirmations()

        let date = Date()
        let original = repo.assignedAffirmation(for: date)

        // Reroll multiple times to increase chance of getting a different one
        var gotDifferent = false
        for _ in 0..<20 {
            let rerolled = repo.reroll(for: date)
            if rerolled.id != original.id {
                gotDifferent = true
                break
            }
        }

        // With 3 affirmations and 20 attempts, probability of all same = (1/3)^20 ≈ 0
        XCTAssertTrue(gotDifferent, "Reroll should eventually pick a different affirmation")
    }

    func testRerollPersistsNewAssignment() async {
        let repo = makeRepository()
        await repo.fetchAffirmations()

        let date = Date()
        let rerolled = repo.reroll(for: date)

        // New instance should see the rerolled assignment
        let repo2 = AffirmationRepository(apiClient: testAPI, cache: testDefaults)
        await repo2.fetchAffirmations()
        let retrieved = repo2.assignedAffirmation(for: date)

        XCTAssertEqual(rerolled.id, retrieved.id, "Rerolled assignment should persist")
    }
}

// MARK: - ThemeManager Tests

@MainActor
final class ThemeManagerTests: XCTestCase {

    func testAutoThemeUsesTimeOfDay() {
        let manager = ThemeManager()
        let hour = Calendar.current.component(.hour, from: Date())
        let expectedTheme: AppTheme = ThemeManager.dayHourRange.contains(hour) ? .light : .dark

        XCTAssertEqual(manager.currentTheme, expectedTheme)
        XCTAssertTrue(manager.autoThemeEnabled)
    }

    func testSetManualThemeDisablesAuto() {
        let manager = ThemeManager()
        manager.setManualTheme(.dark)

        XCTAssertFalse(manager.autoThemeEnabled)
        XCTAssertEqual(manager.currentTheme, .dark)
    }

    func testEnableAutoThemeRestoresTimeBased() {
        let manager = ThemeManager()
        manager.setManualTheme(.dark)
        manager.enableAutoTheme()

        XCTAssertTrue(manager.autoThemeEnabled)
        let hour = Calendar.current.component(.hour, from: Date())
        let expected: AppTheme = ThemeManager.dayHourRange.contains(hour) ? .light : .dark
        XCTAssertEqual(manager.currentTheme, expected)
    }
}

// MARK: - Affirmation Model Tests

final class AffirmationModelTests: XCTestCase {

    func testAffirmationCodable() throws {
        let original = Affirmation(id: "42", text: "Test text")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Affirmation.self, from: data)

        XCTAssertEqual(decoded.id, "42")
        XCTAssertEqual(decoded.text, "Test text")
    }

    func testAffirmationHashable() {
        let a = Affirmation(id: "1", text: "Hello")
        let b = Affirmation(id: "1", text: "Hello")
        let c = Affirmation(id: "2", text: "World")

        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)

        let set: Set<Affirmation> = [a, b, c]
        XCTAssertEqual(set.count, 2, "Duplicate affirmations should be deduplicated in a Set")
    }
}

// MARK: - AppTheme Tests

final class AppThemeTests: XCTestCase {

    func testLightThemeHasDistinctColors() {
        let theme = AppTheme.light
        XCTAssertFalse(theme.gradientColors.isEmpty)
        XCTAssertEqual(theme.gradientColors.count, 2)
    }

    func testDarkThemeHasDistinctColors() {
        let theme = AppTheme.dark
        XCTAssertFalse(theme.gradientColors.isEmpty)
        XCTAssertEqual(theme.gradientColors.count, 2)
    }

    func testThemesAreEquatable() {
        XCTAssertEqual(AppTheme.light, AppTheme.light)
        XCTAssertEqual(AppTheme.dark, AppTheme.dark)
        XCTAssertNotEqual(AppTheme.light, AppTheme.dark)
    }

    func testLightAndDarkHaveDifferentTextPrimary() {
        XCTAssertNotEqual(AppTheme.light.textPrimary, AppTheme.dark.textPrimary)
    }
}
