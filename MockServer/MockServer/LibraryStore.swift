//
//  LibraryStore.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//

import Foundation

enum LibraryStoreError: Error {
    case bookNotFound
    case bookUnavailable
    case loanLimitReached
    case notBorrowed
}

final class LibraryStore: @unchecked Sendable {
    static let loanPeriod: TimeInterval = 21 * 24 * 60 * 60

    // `URLProtocol` handles requests on background threads, so every read and write of the library's state
    // happens while holding this lock.
    private let lock = NSLock()
    private var catalogue = LibrarySeed.books
    private var loans = LibrarySeed.loans

    private let loanLimit = 5

    // MARK: - Singleton

    static let shared = LibraryStore()

    private init() {}

    // MARK: - Books

    func retrieveBooks() -> [BookRecord] {
        lock.lock()
        defer { lock.unlock() }

        return catalogue
    }

    // MARK: - Loans

    func retrieveLoans() -> [LoanResponse] {
        lock.lock()
        defer { lock.unlock() }

        return loans.compactMap { loan in
            catalogue
                .first(where: { $0.id == loan.bookID })
                .map { LoanResponse(book: $0,
                                    loan: loan) }
        }
    }

    func createLoan(forBookID bookID: String) throws(LibraryStoreError) -> LoanResponse {
        lock.lock()
        defer { lock.unlock() }

        guard let bookIndex = catalogue.firstIndex(where: { $0.id == bookID }) else {
            throw .bookNotFound
        }

        // `PUT` is idempotent, so borrowing a book that's already on loan to you returns the existing loan.
        if let existingLoan = loans.first(where: { $0.bookID == bookID }) {
            return LoanResponse(book: catalogue[bookIndex],
                                loan: existingLoan)
        }

        guard catalogue[bookIndex].availability == .available else {
            throw .bookUnavailable
        }

        guard loans.count < loanLimit else {
            throw .loanLimitReached
        }

        let borrowedDate = Date()
        let loan = LoanRecord(bookID: bookID,
                              borrowedDate: borrowedDate,
                              dueDate: borrowedDate.addingTimeInterval(Self.loanPeriod))

        loans.append(loan)
        catalogue[bookIndex].availability = .onLoanToYou

        return LoanResponse(book: catalogue[bookIndex],
                            loan: loan)
    }

    func deleteLoan(forBookID bookID: String) throws(LibraryStoreError) -> BookRecord {
        lock.lock()
        defer { lock.unlock() }

        guard let loanIndex = loans.firstIndex(where: { $0.bookID == bookID }),
              let bookIndex = catalogue.firstIndex(where: { $0.id == bookID }) else {
            throw .notBorrowed
        }

        loans.remove(at: loanIndex)
        catalogue[bookIndex].availability = .available

        return catalogue[bookIndex]
    }
}
