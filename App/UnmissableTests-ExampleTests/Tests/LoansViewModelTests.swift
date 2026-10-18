//
//  LoansViewModelTests.swift
//  UnmissableTests-ExampleTests
//
//  Created by William Boles on 18/10/2026.
//

import Foundation
import Testing

@testable import UnmissableTests_Example

struct LoansViewModelTests {

    // MARK: - Load

    @Test("Given no load has been made, when checking the state, then it is loading")
    func stateBeforeLoad() async throws {
        let sut = createSUT()

        #expect(sut.state == .loading)
    }

    @Test("Given loans are loaded, when the load is made, then the loan service is asked for loans and whether each one is overdue")
    func loadRequest() async throws {
        let loanService = StubLoanService()
        loanService.loansResponse = .success([.testData(book: .testData(id: "book-01"))])
        loanService.isOverdueResponse = false

        let sut = createSUT(loanService: loanService)

        await sut.load()

        #expect(loanService.events == [.loans, .isOverdue(.testData(book: .testData(id: "book-01")))])
    }

    @Test("Given loans are loaded, when that load is successful, then a row is created for each loan",
          arguments: [
            false,
            true
          ] as [Bool]
    )
    func successfulLoad(isOverdue: Bool) async throws {
        let loanService = StubLoanService()
        loanService.loansResponse = .success([.testData(book: .testData(id: "book-01",
                                                                        title: "Dracula",
                                                                        author: .testData(firstName: "Bram",
                                                                                          lastName: "Stoker"),
                                                                        coverImageName: "dracula"),
                                                        dueDate: Date(timeIntervalSince1970: 100))])
        loanService.isOverdueResponse = isOverdue

        let sut = createSUT(loanService: loanService)

        await sut.load()

        let expectedRows: [LoansViewModel.Row] = [.testData(id: "book-01",
                                                            title: "Dracula",
                                                            authorName: "Stoker, Bram",
                                                            coverImageName: "dracula",
                                                            dueDate: Date(timeIntervalSince1970: 100),
                                                            isOverdue: isOverdue)]

        #expect(sut.state == .loaded(expectedRows))
    }

    @Test("Given loans are loaded, when that load is successful, then the rows are sorted by due date, author's last name, author's first name and then title")
    func loadSortsRows() async throws {
        let loanService = StubLoanService()
        loanService.loansResponse = .success([.testData(book: .testData(id: "book-01",
                                                                        title: "Emma",
                                                                        author: .testData(firstName: "Jane",
                                                                                          lastName: "Austen")),
                                                        dueDate: Date(timeIntervalSince1970: 200)),
                                              .testData(book: .testData(id: "book-02",
                                                                        title: "Wuthering Heights",
                                                                        author: .testData(firstName: "Emily",
                                                                                          lastName: "Brontë")),
                                                        dueDate: Date(timeIntervalSince1970: 100)),
                                              .testData(book: .testData(id: "book-03",
                                                                        title: "Jane Eyre",
                                                                        author: .testData(firstName: "Charlotte",
                                                                                          lastName: "Brontë")),
                                                        dueDate: Date(timeIntervalSince1970: 100)),
                                              .testData(book: .testData(id: "book-04",
                                                                        title: "Pride and Prejudice",
                                                                        author: .testData(firstName: "Jane",
                                                                                          lastName: "Austen")),
                                                        dueDate: Date(timeIntervalSince1970: 100)),
                                              .testData(book: .testData(id: "book-05",
                                                                        title: "Mansfield Park",
                                                                        author: .testData(firstName: "Jane",
                                                                                          lastName: "Austen")),
                                                        dueDate: Date(timeIntervalSince1970: 100))])
        loanService.isOverdueResponse = false

        let sut = createSUT(loanService: loanService)

        await sut.load()

        #expect(sut.state.rows.map(\.id) == ["book-05", "book-04", "book-03", "book-02", "book-01"])
    }

    @Test("Given loans are loaded, when that load fails, then the matching failed state is set",
          arguments: zip(
            [
              .membershipExpired,
              .failed
            ] as [LoansServiceError],
            [
              .membershipExpired,
              .failed
            ] as [LoansViewModel.State]
          )
    )
    func failedLoad(loansError: LoansServiceError,
                    expectedState: LoansViewModel.State) async throws {
        let loanService = StubLoanService()
        loanService.loansResponse = .failure(loansError)

        let sut = createSUT(loanService: loanService)

        await sut.load()

        #expect(sut.state == expectedState)
    }

    // MARK: - ReturnBook

    @Test("Given a row is returned, when the return is made, then the loan service is asked to return that row's book and the loans are refreshed")
    func returnBookRequest() async throws {
        let loanService = StubLoanService()
        loanService.loansResponse = .success([.testData(book: .testData(id: "book-01"))])
        loanService.isOverdueResponse = false
        loanService.returnBookResponse = .success(())

        let sut = createSUT(loanService: loanService)

        await sut.load()

        let row = try #require(sut.state.rows.first)

        loanService.loansResponse = .success([])

        await sut.returnBook(row)

        #expect(loanService.events == [.loans, .isOverdue(.testData(book: .testData(id: "book-01"))), .returnBook(.testData(id: "book-01")), .loans])
    }

    @Test("Given a row is returned, when that return is successful, then the row is removed")
    func successfulReturnBook() async throws {
        let loanService = StubLoanService()
        loanService.loansResponse = .success([.testData(book: .testData(id: "book-01"))])
        loanService.isOverdueResponse = false
        loanService.returnBookResponse = .success(())

        let sut = createSUT(loanService: loanService)

        await sut.load()

        let row = try #require(sut.state.rows.first)

        loanService.loansResponse = .success([])

        await sut.returnBook(row)

        #expect(sut.state == .loaded([]))
    }

    @Test("Given a row is returned, when that return fails, then the return failed alert is set")
    func failedReturnBook() async throws {
        let loanService = StubLoanService()
        loanService.loansResponse = .success([.testData(book: .testData(id: "book-01"))])
        loanService.isOverdueResponse = false
        loanService.returnBookResponse = .failure(.failed)

        let sut = createSUT(loanService: loanService)

        await sut.load()

        let row = try #require(sut.state.rows.first)

        await sut.returnBook(row)

        #expect(sut.alert == .returnFailed)
    }

    @Test("Given a row is returned, when that return fails, then the loans aren't refreshed")
    func failedReturnBookDoesNotRefreshLoans() async throws {
        let loanService = StubLoanService()
        loanService.loansResponse = .success([.testData(book: .testData(id: "book-01"))])
        loanService.isOverdueResponse = false
        loanService.returnBookResponse = .failure(.failed)

        let sut = createSUT(loanService: loanService)

        await sut.load()

        let row = try #require(sut.state.rows.first)

        await sut.returnBook(row)

        #expect(loanService.events == [.loans, .isOverdue(.testData(book: .testData(id: "book-01"))), .returnBook(.testData(id: "book-01"))])
    }

    @Test("Given a row is returned, when that return is successful but the loans refresh fails, then the state is failed")
    func successfulReturnBookWithFailedRefresh() async throws {
        let loanService = StubLoanService()
        loanService.loansResponse = .success([.testData()])
        loanService.isOverdueResponse = false
        loanService.returnBookResponse = .success(())

        let sut = createSUT(loanService: loanService)

        await sut.load()

        let row = try #require(sut.state.rows.first)

        loanService.loansResponse = .failure(.failed)

        await sut.returnBook(row)

        #expect(sut.state == .failed)
    }

    @Test("Given a row is returned, when that row doesn't match a loaded loan, then the loan service isn't asked to return")
    func returnBookWithUnknownRow() async throws {
        let loanService = StubLoanService()
        loanService.loansResponse = .success([])

        let sut = createSUT(loanService: loanService)

        await sut.load()
        await sut.returnBook(.testData(id: "book-99"))

        #expect(loanService.events == [.loans])
    }

    // MARK: - IsShowingAlert

    @Test("Given no alert has been set, when checking if an alert is showing, then it isn't")
    func isShowingAlertWithoutAlert() async throws {
        let sut = createSUT()

        #expect(sut.isShowingAlert == false)
    }

    @Test("Given an alert has been set, when checking if an alert is showing, then it is")
    func isShowingAlertWithAlert() async throws {
        let loanService = StubLoanService()
        loanService.loansResponse = .success([.testData(book: .testData(id: "book-01"))])
        loanService.isOverdueResponse = false
        loanService.returnBookResponse = .failure(.failed)

        let sut = createSUT(loanService: loanService)

        await sut.load()

        let row = try #require(sut.state.rows.first)

        await sut.returnBook(row)

        #expect(sut.isShowingAlert == true)
    }

    @Test("Given an alert is showing, when it's dismissed, then the alert is cleared")
    func dismissAlert() async throws {
        let loanService = StubLoanService()
        loanService.loansResponse = .success([.testData(book: .testData(id: "book-01"))])
        loanService.isOverdueResponse = false
        loanService.returnBookResponse = .failure(.failed)

        let sut = createSUT(loanService: loanService)

        await sut.load()

        let row = try #require(sut.state.rows.first)

        await sut.returnBook(row)

        sut.isShowingAlert = false

        #expect(sut.alert == nil)
    }
}

extension LoansViewModelTests {
    func createSUT(loanService: LoanService = StubLoanService()) -> LoansViewModel {
        LoansViewModel(loanService: loanService)
    }
}
