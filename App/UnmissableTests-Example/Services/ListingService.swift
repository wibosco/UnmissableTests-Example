//
//  ListingService.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation

protocol ListingService {
    func listings() async throws -> [Listing]
}

final class DefaultListingService: ListingService {
    private let repository: CatalogueRepository
    private var cachedListings: [Listing]?
    
    // MARK: - Init
    
    init(repository: CatalogueRepository) {
        self.repository = repository
    }
    
    // MARK: - Listing

    func listings() async throws -> [Listing] {
        if let cachedListings {
            return cachedListings
        }

        let listings = try await repository.retrieveListings()
        cachedListings = listings

        return listings
    }
}
