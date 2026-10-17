//
//  LoanService.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation

enum LoanError: Error, Equatable {
    case alreadyBorrowed
    case loanLimitReached
    case onLoan
    case invalidLoanPeriod
    case notBorrowed
}

@MainActor
final class LoanService {
    private let repository: CatalogueRepository
    private let loanLimit: Int
    private let loanPeriodInDays: Int
    private let calendar: Calendar
    private let now: () -> Date

    init(repository: CatalogueRepository,
         loanLimit: Int,
         loanPeriodInDays: Int,
         calendar: Calendar,
         now: @escaping () -> Date) {
        self.repository = repository
        self.loanLimit = loanLimit
        self.loanPeriodInDays = loanPeriodInDays
        self.calendar = calendar
        self.now = now
    }

    // MARK: - Loans

    func loans() async throws -> [Loan] {
        try await repository.loans()
    }

    // MARK: - Borrowing

    @discardableResult
    func borrow(_ book: Book) async throws -> Loan {
        let currentLoans = try await repository.loans()

        guard !currentLoans.contains(where: { $0.book.id == book.id }) else {
            throw LoanError.alreadyBorrowed
        }

        guard currentLoans.count < loanLimit else {
            throw LoanError.loanLimitReached
        }

        switch try await repository.availability(ofBookWithID: book.id) {
        case .available:
            break
        case .onLoan:
            throw LoanError.onLoan
        case .onLoanToYou:
            throw LoanError.alreadyBorrowed
        }

        let borrowedAt = now()

        guard let dueDate = calendar.date(byAdding: .day,
                                          value: loanPeriodInDays,
                                          to: borrowedAt) else {
            throw LoanError.invalidLoanPeriod
        }

        try await repository.checkOut(bookID: book.id,
                                      borrowedAt: borrowedAt,
                                      dueDate: dueDate)

        return Loan(book: book,
                    borrowedAt: borrowedAt,
                    dueDate: dueDate)
    }

    // MARK: - Returning

    func returnBook(_ book: Book) async throws {
        let currentLoans = try await repository.loans()

        guard currentLoans.contains(where: { $0.book.id == book.id }) else {
            throw LoanError.notBorrowed
        }

        try await repository.checkIn(bookID: book.id)
    }

    // MARK: - Overdue

    func overdueLoans() async throws -> [Loan] {
        try await repository.loans().filter { isOverdue($0) }
    }

    func isOverdue(_ loan: Loan) -> Bool {
        now() > loan.dueDate
    }
}
