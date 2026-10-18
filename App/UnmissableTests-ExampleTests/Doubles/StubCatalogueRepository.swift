//
//  StubCatalogueRepository.swift
//  UnmissableTests-ExampleTests
//
//  Created by William Boles on 18/10/2026.
//

import Foundation

@testable import UnmissableTests_Example

final class StubCatalogueRepository: CatalogueRepository {
    enum Event: Equatable  {
        case retrieveListings
        case retrieveLoans
        case checkOutBook(String)
        case checkInBook(String)
    }
    
    private(set) var events = [Event]()
    
    var retrieveListingsResponse: Result<[Listing], ListingsError>!
    var retrieveLoansResponse: Result<[Loan], LoansError>!
    var checkOutBookResponse: Result<Loan, CheckOutError>!
    var checkInBookResponse: Result<Listing, CheckInError>!
    
    // MARK: - CatalogueRepository
    
    func retrieveListings() async throws(ListingsError) -> [Listing] {
        events.append(.retrieveListings)
        
        return try retrieveListingsResponse.get()
    }
    
    func retrieveLoans() async throws(LoansError) -> [Loan] {
        events.append(.retrieveLoans)
        
        return try retrieveLoansResponse.get()
    }
    
    func checkOutBook(_ bookID: String) async throws(CheckOutError) -> Loan {
        events.append(.checkOutBook(bookID))
        
        return try checkOutBookResponse.get()
    }
    
    func checkInBook(_ bookID: String) async throws(CheckInError) -> Listing {
        events.append(.checkInBook(bookID))
        
        return try checkInBookResponse.get()
    }
}
