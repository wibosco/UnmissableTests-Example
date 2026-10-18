//
//  StubLibraryRepository.swift
//  UnmissableTests-ExampleTests
//
//  Created by William Boles on 18/10/2026.
//

import Foundation

@testable import UnmissableTests_Example

final class StubLibraryRepository: LibraryRepository {
    enum Event: Equatable  {
        case retrieveListings
        case retrieveLoans
        case createLoan(forBookID: String)
        case deleteLoan(forBookID: String)
    }
    
    private(set) var events = [Event]()
    
    var retrieveListingsResponse: Result<[Listing], RetrieveListingsRepositoryError>!
    var retrieveLoansResponse: Result<[Loan], RetrieveLoansRepositoryError>!
    var createLoanResponse: Result<Loan, CreateLoanRepositoryError>!
    var deleteLoanResponse: Result<Listing, DeleteLoanRepositoryError>!
    
    // MARK: - LibraryRepository
    
    func retrieveListings() async throws(RetrieveListingsRepositoryError) -> [Listing] {
        events.append(.retrieveListings)
        
        return try retrieveListingsResponse.get()
    }
    
    func retrieveLoans() async throws(RetrieveLoansRepositoryError) -> [Loan] {
        events.append(.retrieveLoans)
        
        return try retrieveLoansResponse.get()
    }
    
    func createLoan(forBookID bookID: String) async throws(CreateLoanRepositoryError) -> Loan {
        events.append(.createLoan(forBookID: bookID))
        
        return try createLoanResponse.get()
    }
    
    func deleteLoan(forBookID bookID: String) async throws(DeleteLoanRepositoryError) -> Listing {
        events.append(.deleteLoan(forBookID: bookID))
        
        return try deleteLoanResponse.get()
    }
}
