//
//  APIClient.swift
//  Grounding Sun
//
//  Protocol defining the API contract for data fetching
//

import Foundation

protocol APIClient {
    func fetchAffirmations() async throws -> [AffirmationDTO]
}
