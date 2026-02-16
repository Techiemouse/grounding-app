//
//  AffirmationStore.swift
//  Grounding Sun
//
//  Repository pattern with APIClient integration
//

import Foundation
import os

struct Affirmation: Identifiable, Codable, Hashable {
    let id: String
    let text: String
}

@MainActor
class AffirmationRepository: ObservableObject {
    @Published var affirmations: [Affirmation] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?

    private let apiClient: APIClient
    private let cache: UserDefaults
    private let logger = Logger(subsystem: "com.groundingsun", category: "AffirmationRepository")

    private let storageKey = "assigned_affirmations_by_date"
    private let cacheKey = "cached_affirmations"

    init(apiClient: APIClient = MockAPIClient(), cache: UserDefaults = .standard) {
        self.apiClient = apiClient
        self.cache = cache
        loadFromCache()
    }

    // MARK: - Public Methods

    func fetchAffirmations() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            let dtos = try await apiClient.fetchAffirmations()
            let newAffirmations = dtos.map { Affirmation(id: $0.id, text: $0.text) }
            affirmations = newAffirmations
            saveToCache(newAffirmations)
        } catch {
            logger.error("Failed to fetch affirmations: \(error.localizedDescription)")
            self.error = error
            if affirmations.isEmpty {
                loadFromCache()
            }
        }

        isLoading = false
    }

    func assignedAffirmation(for date: Date) -> Affirmation {
        let key = dateKey(for: date)
        var map = (cache.dictionary(forKey: storageKey) as? [String: String]) ?? [:]

        if let id = map[key], let existing = affirmations.first(where: { $0.id == id }) {
            return existing
        }

        let picked = affirmations.randomElement() ?? Affirmation(id: "fallback", text: "You are enough.")
        map[key] = picked.id
        cache.set(map, forKey: storageKey)
        return picked
    }

    func reroll(for date: Date) -> Affirmation {
        let key = dateKey(for: date)
        var map = (cache.dictionary(forKey: storageKey) as? [String: String]) ?? [:]

        let picked = affirmations.randomElement() ?? Affirmation(id: "fallback", text: "You are enough.")
        map[key] = picked.id
        cache.set(map, forKey: storageKey)
        return picked
    }

    // MARK: - Private Methods

    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func loadFromCache() {
        guard let data = cache.data(forKey: cacheKey) else { return }
        do {
            affirmations = try JSONDecoder().decode([Affirmation].self, from: data)
        } catch {
            logger.error("Failed to decode cached affirmations: \(error.localizedDescription)")
        }
    }

    private func saveToCache(_ affirmations: [Affirmation]) {
        do {
            let data = try JSONEncoder().encode(affirmations)
            cache.set(data, forKey: cacheKey)
        } catch {
            logger.error("Failed to encode affirmations for cache: \(error.localizedDescription)")
        }
    }
}
