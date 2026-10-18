//
//  ListingService.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation

protocol ListingService {
    func listings() async throws(ListingsServiceError) -> [Listing]
}

enum ListingsServiceError: Error, Equatable {
    case failed
}

final class DefaultListingService: ListingService {
    private let repository: LibraryRepository
    private var cachedListings: [Listing]?
    
    // MARK: - Init
    
    init(repository: LibraryRepository) {
        self.repository = repository
    }
    
    // MARK: - Listings

    func listings() async throws(ListingsServiceError) -> [Listing] {
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
