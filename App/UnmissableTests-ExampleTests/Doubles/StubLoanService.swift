//
//  StubLoanService.swift
//  UnmissableTests-ExampleTests
//
//  Created by William Boles on 18/10/2026.
//

import Foundation

@testable import UnmissableTests_Example

final class StubLoanService: LoanService {
    enum Event: Equatable {
        case loans
        case borrowBook(Book)
        case returnBook(Book)
        case isOverdue(Loan)
    }
    
    private(set) var events = [Event]()
    
    var loansResponse: Result<[Loan], LoansServiceError>!
    var borrowBookResponse: Result<Loan, BorrowBookError>!
    var returnBookResponse: Result<Void, ReturnBookError>!
    var isOverdueResponse: Bool!
    
    // MARK: - LoanService
    
    func loans() async throws(LoansServiceError) -> [Loan] {
        events.append(.loans)
        
        return try loansResponse.get()
    }
    
    func borrowBook(_ book: Book) async throws(BorrowBookError) -> Loan {
        events.append(.borrowBook(book))
        
        return try borrowBookResponse.get()
    }
    
    func returnBook(_ book: Book) async throws(ReturnBookError) {
        events.append(.returnBook(book))
        
        try returnBookResponse.get()
    }
    
    func isOverdue(_ loan: Loan) -> Bool {
        events.append(.isOverdue(loan))
        
        return isOverdueResponse
    }
}
