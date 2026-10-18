//
//  ListingService.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation

protocol ListingService {
    func listings() async throws(ListingServiceError) -> [Listing]
}

enum ListingServiceError: Error, Equatable {
    case failed
}

final class DefaultListingService: ListingService {
    private let repository: CatalogueRepository
    private var cachedListings: [Listing]?
    
    // MARK: - Init
    
    init(repository: CatalogueRepository) {
        self.repository = repository
    }
    
    // MARK: - Listing

    func listings() async throws(ListingServiceError) -> [Listing] {
        if let cachedListings {
            return cachedListings
        }

        let listings: [Listing]

        do {
            listings = try await repository.retrieveListings()
        } catch {
            switch error {
            case .failed:
                throw .failed
            }
        }

        cachedListings = listings

        return listings
    }
}
