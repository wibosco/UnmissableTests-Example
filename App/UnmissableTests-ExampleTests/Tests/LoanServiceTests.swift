//
//  LoanServiceTests.swift
//  UnmissableTests-ExampleTests
//
//  Created by William Boles on 18/10/2026.
//

import Foundation
import Testing

@testable import UnmissableTests_Example

struct LoanServiceTests {

    // MARK: - Loans

    @Test("Given loans are retrieved, when the retrieval is made, then the repository is asked for loans")
    func loansRetrievalRequest() async throws {
        let repository = StubCatalogueRepository()
        repository.retrieveLoansResponse = .success([])

        let sut = createSUT(repository: repository)

        _ = try await sut.loans()

        #expect(repository.events == [.retrieveLoans])
    }

    @Test("Given loans are retrieved, when that retrieval is successful, then the repository's loans are returned")
    func successfulLoansRetrieval() async throws {
        let repository = StubCatalogueRepository()
        let repositoryLoans: [Loan] = [.testData(book: .testData(id: "book-01"),
                                                 dueDate: Date(timeIntervalSince1970: 100)),
                                       .testData(book: .testData(id: "book-02"),
                                                 dueDate: Date(timeIntervalSince1970: 200))]
        repository.retrieveLoansResponse = .success(repositoryLoans)

        let sut = createSUT(repository: repository)

        let loans = try await sut.loans()

        let expectedLoans: [Loan] = [.testData(book: .testData(id: "book-01"),
                                               dueDate: Date(timeIntervalSince1970: 100)),
                                     .testData(book: .testData(id: "book-02"),
                                               dueDate: Date(timeIntervalSince1970: 200))]

        #expect(loans == expectedLoans)
    }

    @Test("Given loans are retrieved, when that retrieval fails, then a failed error is thrown")
    func failedLoansRetrieval() async throws {
        let repository = StubCatalogueRepository()
        repository.retrieveLoansResponse = .failure(.failed)

        let sut = createSUT(repository: repository)

        await #expect(throws: LoansServiceError.failed) {
            try await sut.loans()
        }
    }

    @Test("Given loans have already been retrieved, when they are retrieved again, then the repository isn't asked again")
    func cachedLoansRetrieval() async throws {
        let repository = StubCatalogueRepository()
        repository.retrieveLoansResponse = .success([.testData()])

        let sut = createSUT(repository: repository)

        _ = try await sut.loans()
        _ = try await sut.loans()

        #expect(repository.events == [.retrieveLoans])
    }

    @Test("Given a loans retrieval has failed, when loans are retrieved again, then the repository is asked again")
    func failedLoansRetrievalIsNotCached() async throws {
        let repository = StubCatalogueRepository()
        repository.retrieveLoansResponse = .failure(.failed)

        let sut = createSUT(repository: repository)

        _ = try? await sut.loans()

        repository.retrieveLoansResponse = .success([.testData()])

        _ = try await sut.loans()

        #expect(repository.events == [.retrieveLoans, .retrieveLoans])
    }

    // MARK: - BorrowBook

    @Test("Given a book is borrowed, when the borrow is made, then the repository is asked to check out that book")
    func borrowBookRequest() async throws {
        let repository = StubCatalogueRepository()
        repository.checkOutBookResponse = .success(.testData(book: .testData(id: "book-01")))

        let sut = createSUT(repository: repository)

        try await sut.borrowBook(.testData(id: "book-01"))

        #expect(repository.events == [.checkOutBook("book-01")])
    }

    @Test("Given a book is borrowed, when that borrow is successful, then the repository's loan is returned")
    func successfulBorrowBook() async throws {
        let repository = StubCatalogueRepository()
        repository.checkOutBookResponse = .success(.testData(book: .testData(id: "book-01"),
                                                             dueDate: Date(timeIntervalSince1970: 100)))

        let sut = createSUT(repository: repository)

        let loan = try await sut.borrowBook(.testData(id: "book-01"))

        let expectedLoan = Loan.testData(book: .testData(id: "book-01"),
                                         dueDate: Date(timeIntervalSince1970: 100))

        #expect(loan == expectedLoan)
    }

    @Test("Given a book is borrowed, when that borrow fails, then the matching error is thrown",
          arguments: zip(
            [
              .loanLimitReached,
              .alreadyBorrowed,
              .bookUnavailable,
              .failed
            ] as [CheckOutError],
            [
              .loanLimitReached,
              .failed,
              .failed,
              .failed
            ] as [BorrowBookError]
          )
    )
    func borrowBookFailure(repositoryError: CheckOutError,
                           expectedError: BorrowBookError) async throws {
        let repository = StubCatalogueRepository()
        repository.checkOutBookResponse = .failure(repositoryError)

        let sut = createSUT(repository: repository)

        await #expect(throws: expectedError) {
            try await sut.borrowBook(.testData(id: "book-01"))
        }
    }

    @Test("Given loans have been retrieved, when a book is borrowed, then its loan is added to the cached loans")
    func borrowBookAddsToCachedLoans() async throws {
        let repository = StubCatalogueRepository()
        repository.retrieveLoansResponse = .success([.testData(book: .testData(id: "book-01"))])
        repository.checkOutBookResponse = .success(.testData(book: .testData(id: "book-02")))

        let sut = createSUT(repository: repository)

        _ = try await sut.loans()
        try await sut.borrowBook(.testData(id: "book-02"))

        let loans = try await sut.loans()

        let expectedLoans: [Loan] = [.testData(book: .testData(id: "book-01")),
                                     .testData(book: .testData(id: "book-02"))]

        #expect(loans == expectedLoans)
    }

    @Test("Given loans haven't been retrieved, when a book is borrowed, then the next loans retrieval returns the repository's loans")
    func borrowBookWithUnloadedCache() async throws {
        let repository = StubCatalogueRepository()
        repository.checkOutBookResponse = .success(.testData(book: .testData(id: "book-02")))
        repository.retrieveLoansResponse = .success([.testData(book: .testData(id: "book-01")),
                                                     .testData(book: .testData(id: "book-02"))])

        let sut = createSUT(repository: repository)

        try await sut.borrowBook(.testData(id: "book-02"))

        let loans = try await sut.loans()

        let expectedLoans: [Loan] = [.testData(book: .testData(id: "book-01")),
                                     .testData(book: .testData(id: "book-02"))]

        #expect(loans == expectedLoans)
    }

    @Test("Given loans have been retrieved, when a book borrow fails, then the cached loans are unchanged")
    func failedBorrowBookLeavesCachedLoansUnchanged() async throws {
        let repository = StubCatalogueRepository()
        repository.retrieveLoansResponse = .success([.testData(book: .testData(id: "book-01"))])
        repository.checkOutBookResponse = .failure(.failed)

        let sut = createSUT(repository: repository)

        _ = try await sut.loans()
        _ = try? await sut.borrowBook(.testData(id: "book-02"))

        let loans = try await sut.loans()

        #expect(loans == [.testData(book: .testData(id: "book-01"))])
    }

    // MARK: - ReturnBook

    @Test("Given a book is returned, when the return is made, then the repository is asked to check in that book")
    func returnBookRequest() async throws {
        let repository = StubCatalogueRepository()
        repository.checkInBookResponse = .success(.testData(book: .testData(id: "book-01")))

        let sut = createSUT(repository: repository)

        try await sut.returnBook(.testData(id: "book-01"))

        #expect(repository.events == [.checkInBook("book-01")])
    }

    @Test("Given a book is returned, when that return is successful, then an error isn't thrown")
    func successfulReturnBook() async throws {
        let repository = StubCatalogueRepository()
        repository.checkInBookResponse = .success(.testData(book: .testData(id: "book-01")))

        let sut = createSUT(repository: repository)

        await #expect(throws: Never.self) {
            try await sut.returnBook(.testData(id: "book-01"))
        }
    }

    @Test("Given a book is returned, when that return fails, then a failed error is thrown",
          arguments: [
            .notBorrowed,
            .failed
          ] as [CheckInError]
    )
    func returnBookFailure(repositoryError: CheckInError) async throws {
        let repository = StubCatalogueRepository()
        repository.checkInBookResponse = .failure(repositoryError)

        let sut = createSUT(repository: repository)

        await #expect(throws: ReturnBookError.failed) {
            try await sut.returnBook(.testData(id: "book-01"))
        }
    }

    @Test("Given loans have been retrieved, when a book is returned, then its loan is removed from the cached loans")
    func returnBookRemovesFromCachedLoans() async throws {
        let repository = StubCatalogueRepository()
        repository.retrieveLoansResponse = .success([.testData(book: .testData(id: "book-01")),
                                                     .testData(book: .testData(id: "book-02"))])
        repository.checkInBookResponse = .success(.testData(book: .testData(id: "book-01")))

        let sut = createSUT(repository: repository)

        _ = try await sut.loans()
        try await sut.returnBook(.testData(id: "book-01"))

        let loans = try await sut.loans()

        #expect(loans == [.testData(book: .testData(id: "book-02"))])
    }

    @Test("Given loans have been retrieved, when a book return fails, then the cached loans are unchanged")
    func failedReturnBookLeavesCachedLoansUnchanged() async throws {
        let repository = StubCatalogueRepository()
        repository.retrieveLoansResponse = .success([.testData(book: .testData(id: "book-01")),
                                                     .testData(book: .testData(id: "book-02"))])
        repository.checkInBookResponse = .failure(.failed)

        let sut = createSUT(repository: repository)

        _ = try await sut.loans()
        _ = try? await sut.returnBook(.testData(id: "book-01"))

        let loans = try await sut.loans()

        let expectedLoans: [Loan] = [.testData(book: .testData(id: "book-01")),
                                     .testData(book: .testData(id: "book-02"))]

        #expect(loans == expectedLoans)
    }

    // MARK: - IsOverdue

    @Test("Given a loan, when checking if it's overdue, then it's only overdue once the due date has passed",
          arguments: zip(
            [
              Date(timeIntervalSince1970: 99),
              Date(timeIntervalSince1970: 100),
              Date(timeIntervalSince1970: 101)
            ] as [Date],
            [
              false,
              false,
              true
            ] as [Bool]
          )
    )
    func isOverdue(now: Date,
                   expectedIsOverdue: Bool) {
        let sut = createSUT(now: { now })

        let isOverdue = sut.isOverdue(.testData(dueDate: Date(timeIntervalSince1970: 100)))

        #expect(isOverdue == expectedIsOverdue)
    }
}

extension LoanServiceTests {
    func createSUT(repository: CatalogueRepository = StubCatalogueRepository(),
                   now: @escaping () -> Date = { Date(timeIntervalSince1970: 0) }) -> DefaultLoanService {
        DefaultLoanService(repository: repository,
                           now: now)
    }
}
