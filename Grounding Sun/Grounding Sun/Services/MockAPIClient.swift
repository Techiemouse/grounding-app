//
//  MockAPIClient.swift
//  Grounding Sun
//
//  Mock implementation of APIClient with hardcoded data
//

import Foundation

class MockAPIClient: APIClient {
    func fetchAffirmations() async throws -> [AffirmationDTO] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)

        return [
            AffirmationDTO(id: "1", text: "I am grounded in this moment, fully present and at peace."),
            AffirmationDTO(id: "2", text: "I have many choices"),
            AffirmationDTO(id: "3", text: "I get to decide what happens next"),
            AffirmationDTO(id: "4", text: "I am exactly where I need to be on my journey."),
            AffirmationDTO(id: "5", text: "With each breath, I become more centered and calm."),
            AffirmationDTO(id: "6", text: "I now acknowledge how far I have come and how much I have grown"),
            AffirmationDTO(id: "7", text: "I honor myself"),
            AffirmationDTO(id: "8", text: "I open myself to express love in a way that is safe for me"),
            AffirmationDTO(id: "9", text: "I am committed to loving myself"),
            AffirmationDTO(id: "10", text: "Focusing on myself is not selfish, it is selfless"),
            AffirmationDTO(id: "11", text: "I am worthy of love and respect"),
            AffirmationDTO(id: "12", text: "I can't fill anyone else's cup if mine is empty"),
            AffirmationDTO(id: "13", text: "Life is happening for me and not to me"),
            AffirmationDTO(id: "14", text: "I am open to seeing the situation with new eyes"),
            AffirmationDTO(id: "15", text: "It is safe for me to speak clearly"),
            AffirmationDTO(id: "16", text: "It is safe for me to co-create"),
            AffirmationDTO(id: "17", text: "I allow the unique wildness within me to be free"),
            AffirmationDTO(id: "18", text: "I open myself up to love"),
            AffirmationDTO(id: "19", text: "I am connected to myself"),
            AffirmationDTO(id: "20", text: "I am inspired by the joy around me"),
            AffirmationDTO(id: "21", text: "I am proud of myself"),
            AffirmationDTO(id: "22", text: "I believe in harmony and balance"),
            AffirmationDTO(id: "23", text: "I carry the wisdom of my ancestors before me"),
            AffirmationDTO(id: "24", text: "When the time is right I know it will happen"),
            AffirmationDTO(id: "25", text: "I trust the timing"),
            AffirmationDTO(id: "26", text: "I am becoming the best version that I can be"),
            AffirmationDTO(id: "27", text: "It is safe for me to trust"),
            AffirmationDTO(id: "28", text: "I release my old programming"),
            AffirmationDTO(id: "29", text: "The right connections will always be reciprocated"),
            AffirmationDTO(id: "30", text: "The best day of my life has yet to occur"),
            AffirmationDTO(id: "31", text: "I believe that I can find love and abundance"),
            AffirmationDTO(id: "32", text: "Love exists all around me"),
            AffirmationDTO(id: "33", text: "I can now feel the love within"),
            AffirmationDTO(id: "34", text: "I open myself up to new relationships and collaborations"),
            AffirmationDTO(id: "35", text: "I celebrate all I have accomplished"),
            AffirmationDTO(id: "36", text: "I can enjoy each moment fully and celebrate all I have created"),
            AffirmationDTO(id: "37", text: "I release painful programming and experiences")
        ]
    }
}
