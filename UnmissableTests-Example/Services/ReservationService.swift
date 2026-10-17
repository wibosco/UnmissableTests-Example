//
//  ReservationService.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation

@MainActor
final class ReservationService {
    private let repository: CatalogueRepository

    init(repository: CatalogueRepository) {
        self.repository = repository
    }

    func reservations() async throws -> [Reservation] {
        try await repository.reservations()
    }
}
