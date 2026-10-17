//
//  CatalogueService.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation

@MainActor
final class CatalogueService {
    private let repository: CatalogueRepository

    init(repository: CatalogueRepository) {
        self.repository = repository
    }

    func catalogue() async throws -> [Listing] {
        try await repository.catalogue()
    }
}
