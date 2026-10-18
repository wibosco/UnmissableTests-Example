//
//  LoanService.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation

protocol LoanService {
    func loans() async throws(LoansServiceError) -> [Loan]

    @discardableResult
    func borrowBook(_ book: Book) async throws(BorrowBookError) -> Loan
    func returnBook(_ book: Book) async throws(ReturnBookError)

    func isOverdue(_ loan: Loan) -> Bool
}

enum LoansServiceError: Error, Equatable {
    case failed
}

enum BorrowBookError: Error, Equatable {
    case loanLimitReached
    case failed
}

enum ReturnBookError: Error, Equatable {
    case failed
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

    func loans() async throws(LoansServiceError) -> [Loan] {
        if let cachedLoans {
            return cachedLoans
        }

        let loans: [Loan]

        do {
            loans = try await repository.retrieveLoans()
        } catch {
            switch error {
            case .failed:
                throw .failed
            }
        }

        cachedLoans = loans

        return loans
    }

    // MARK: - Borrowing

    @discardableResult
    func borrowBook(_ book: Book) async throws(BorrowBookError) -> Loan {
        let loan: Loan

        do {
            loan = try await repository.checkOutBook(book.id)
        } catch {
            switch error {
            case .loanLimitReached:
                throw .loanLimitReached
            case .alreadyBorrowed, .bookUnavailable, .failed:
                throw .failed
            }
        }

        // An unloaded cache has nothing to keep in sync, the next `loans()` call will fetch fresh data.
        cachedLoans?.append(loan)

        return loan
    }

    // MARK: - Returning

    func returnBook(_ book: Book) async throws(ReturnBookError) {
        do {
            _ = try await repository.checkInBook(book.id)
        } catch {
            switch error {
            case .notBorrowed, .failed:
                throw .failed
            }
        }

        cachedLoans?.removeAll { $0.book.id == book.id }
    }

    // MARK: - Overdue

    func isOverdue(_ loan: Loan) -> Bool {
        now() > loan.dueDate
    }
}
