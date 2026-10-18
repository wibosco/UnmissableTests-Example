//
//  LoanService.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation

enum LoanError: Error, Equatable {
    case loanLimitReached
}

protocol LoanService {
    func loans() async throws -> [Loan]

    @discardableResult
    func borrowBook(_ book: Book) async throws -> Loan
    func returnBook(_ book: Book) async throws

    func isOverdue(_ loan: Loan) -> Bool
}

final class DefaultLoanService: LoanService {
    private let repository: CatalogueRepository
    private let now: () -> Date
    private var cachedLoans: [Loan]?
    
    // MARK: - Init
    
    init(repository: CatalogueRepository,
         now: @escaping () -> Date) {
        self.repository = repository
        self.now = now
    }

    // MARK: - Loans

    func loans() async throws -> [Loan] {
        if let cachedLoans {
            return cachedLoans
        }

        let loans = try await repository.retrieveLoans()
        cachedLoans = loans

        return loans
    }

    // MARK: - Borrowing

    @discardableResult
    func borrowBook(_ book: Book) async throws -> Loan {
        let loan: Loan

        do {
            loan = try await repository.checkOutBook(book.id)
        } catch CheckOutError.loanLimitReached {
            throw LoanError.loanLimitReached
        }

        // An unloaded cache has nothing to keep in sync, the next `loans()` call will fetch fresh data.
        cachedLoans?.append(loan)

        return loan
    }

    // MARK: - Returning

    func returnBook(_ book: Book) async throws {
        _ = try await repository.checkInBook(book.id)

        cachedLoans?.removeAll { $0.book.id == book.id }
    }

    // MARK: - Overdue

    func isOverdue(_ loan: Loan) -> Bool {
        now() > loan.dueDate
    }
}
