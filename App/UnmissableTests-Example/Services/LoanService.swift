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

final class LoanService {
    private let repository: CatalogueRepository
    private let now: () -> Date

    init(repository: CatalogueRepository,
         now: @escaping () -> Date) {
        self.repository = repository
        self.now = now
    }

    // MARK: - Loans

    func loans() async throws -> [Loan] {
        try await repository.loans()
    }

    // MARK: - Borrowing

    @discardableResult
    func borrow(_ book: Book) async throws -> Listing {
        do {
            return try await repository.checkOut(bookID: book.id)
        } catch CheckOutError.loanLimitReached {
            throw LoanError.loanLimitReached
        }
    }

    // MARK: - Returning

    @discardableResult
    func returnBook(_ book: Book) async throws -> Listing {
        try await repository.checkIn(bookID: book.id)
    }

    // MARK: - Overdue

    func isOverdue(_ loan: Loan) -> Bool {
        now() > loan.dueDate
    }
}
