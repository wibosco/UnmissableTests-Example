//
//  StubListingService.swift
//  UnmissableTests-ExampleTests
//
//  Created by William Boles on 18/10/2026.
//

import Foundation

@testable import UnmissableTests_Example

final class StubListingService: ListingService {
    enum Event: Equatable  {
        case listings
    }
    
    private(set) var events = [Event]()
    
    var listingsResponse: Result<[Listing], ListingServiceError>!
    
    // MARK: - ListingService
    
    func listings() async throws(ListingServiceError) -> [Listing] {
        events.append(.listings)
        
        return try listingsResponse.get()
    }
}
