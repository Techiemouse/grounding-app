//
//  ProductionAPIClient.swift
//  Grounding Sun
//
//  Production implementation of APIClient using URLSession
//  Currently a stub for future backend integration
//

import Foundation

class ProductionAPIClient: APIClient {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL = URL(string: "https://api.groundingsun.com")!, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func fetchAffirmations() async throws -> [AffirmationDTO] {
        // TODO: Implement when backend is ready
        // let url = baseURL.appendingPathComponent("/affirmations")
        // let (data, _) = try await session.data(from: url)
        // return try JSONDecoder().decode([AffirmationDTO].self, from: data)

        throw APIError.notImplemented
    }
}

enum APIError: Error, LocalizedError {
    case notImplemented
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "This feature is not yet available."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Data error: \(error.localizedDescription)"
        }
    }
}
