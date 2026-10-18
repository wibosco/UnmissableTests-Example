//
//  CatalogueViewModelTests.swift
//  UnmissableTests-ExampleTests
//
//  Created by William Boles on 18/10/2026.
//

import Foundation
import Testing

@testable import UnmissableTests_Example

struct CatalogueViewModelTests {

    // MARK: - Load

    @Test("Given no load has been made, when checking the state, then it is loading")
    func stateBeforeLoad() async throws {
        let sut = createSUT()

        #expect(sut.state == .loading)
    }

    @Test("Given listings are loaded, when the load is made, then the listing service is asked for listings")
    func loadListingsRequest() async throws {
        let listingService = StubListingService()
        listingService.listingsResponse = .success([])
        let loanService = StubLoanService()
        loanService.loansResponse = .success([])

        let sut = createSUT(listingService: listingService,
                            loanService: loanService)

        await sut.load()

        #expect(listingService.events == [.listings])
    }

    @Test("Given listings are loaded, when the load is made, then the loan service is asked for loans")
    func loadLoansRequest() async throws {
        let listingService = StubListingService()
        listingService.listingsResponse = .success([])
        let loanService = StubLoanService()
        loanService.loansResponse = .success([])

        let sut = createSUT(listingService: listingService,
                            loanService: loanService)

        await sut.load()

        #expect(loanService.events == [.loans])
    }

    @Test("Given listings are loaded, when that load is successful, then a row is created for each listing")
    func successfulLoad() async throws {
        let listingService = StubListingService()
        listingService.listingsResponse = .success([.testData(book: .testData(id: "book-01",
                                                                              title: "Dracula",
                                                                              author: .testData(firstName: "Bram",
                                                                                                lastName: "Stoker"),
                                                                              coverImageName: "dracula"),
                                                              availability: .onLoan)])
        let loanService = StubLoanService()
        loanService.loansResponse = .success([])

        let sut = createSUT(listingService: listingService,
                            loanService: loanService)

        await sut.load()

        let expectedRows: [CatalogueViewModel.Row] = [.testData(id: "book-01",
                                                                title: "Dracula",
                                                                authorName: "Stoker, Bram",
                                                                coverImageName: "dracula",
                                                                availability: .onLoan)]

        #expect(sut.state == .loaded(expectedRows))
    }

    @Test("Given listings are loaded, when that load is successful, then the rows are sorted by author's last name, author's first name and then title")
    func loadSortsRows() async throws {
        let listingService = StubListingService()
        listingService.listingsResponse = .success([.testData(book: .testData(id: "book-01",
                                                                              title: "Wuthering Heights",
                                                                              author: .testData(firstName: "Emily",
                                                                                                lastName: "Brontë"))),
                                                    .testData(book: .testData(id: "book-02",
                                                                              title: "Pride and Prejudice",
                                                                              author: .testData(firstName: "Jane",
                                                                                                lastName: "Austen"))),
                                                    .testData(book: .testData(id: "book-03",
                                                                              title: "Jane Eyre",
                                                                              author: .testData(firstName: "Charlotte",
                                                                                                lastName: "Brontë"))),
                                                    .testData(book: .testData(id: "book-04",
                                                                              title: "Emma",
                                                                              author: .testData(firstName: "Jane",
                                                                                                lastName: "Austen")))])
        let loanService = StubLoanService()
        loanService.loansResponse = .success([])

        let sut = createSUT(listingService: listingService,
                            loanService: loanService)

        await sut.load()

        #expect(sut.state.rows.map(\.id) == ["book-04", "book-02", "book-03", "book-01"])
    }

    @Test("Given listings are loaded, when a listing isn't on loan to the user, then its row's availability comes from the listing",
          arguments: [
            (.available, .available),
            (.onLoan, .onLoan),
            (.onLoanToYou, .available)
          ] as [(Availability, CatalogueViewModel.Row.Availability)]
    )
    func loadNotLoanedListing(listingAvailability: Availability,
                              expectedAvailability: CatalogueViewModel.Row.Availability) async throws {
        let listingService = StubListingService()
        listingService.listingsResponse = .success([.testData(availability: listingAvailability)])
        let loanService = StubLoanService()
        loanService.loansResponse = .success([])

        let sut = createSUT(listingService: listingService,
                            loanService: loanService)

        await sut.load()

        let row = try #require(sut.state.rows.first)

        #expect(row.availability == expectedAvailability)
    }

    @Test("Given listings are loaded, when a listing is on loan to the user, then its row is on loan to you",
          arguments: [
            .available,
            .onLoan,
            .onLoanToYou
          ] as [Availability]
    )
    func loadLoanedListing(listingAvailability: Availability) async throws {
        let listingService = StubListingService()
        listingService.listingsResponse = .success([.testData(book: .testData(id: "book-01"),
                                                              availability: listingAvailability)])
        let loanService = StubLoanService()
        loanService.loansResponse = .success([.testData(book: .testData(id: "book-01"))])

        let sut = createSUT(listingService: listingService,
                            loanService: loanService)

        await sut.load()

        let row = try #require(sut.state.rows.first)

        #expect(row.availability == .onLoanToYou)
    }

    @Test("Given listings are loaded, when the listings retrieval fails, then the state is failed")
    func failedListingsLoad() async throws {
        let listingService = StubListingService()
        listingService.listingsResponse = .failure(.failed)

        let sut = createSUT(listingService: listingService)

        await sut.load()

        #expect(sut.state == .failed)
    }

    @Test("Given listings are loaded, when the loans retrieval fails, then the state is failed")
    func failedLoansLoad() async throws {
        let listingService = StubListingService()
        listingService.listingsResponse = .success([.testData()])
        let loanService = StubLoanService()
        loanService.loansResponse = .failure(.failed)

        let sut = createSUT(listingService: listingService,
                            loanService: loanService)

        await sut.load()

        #expect(sut.state == .failed)
    }

    // MARK: - BorrowBook

    @Test("Given a row is borrowed, when the borrow is made, then the loan service is asked to borrow that row's book and the loans are refreshed")
    func borrowBookRequest() async throws {
        let listingService = StubListingService()
        listingService.listingsResponse = .success([.testData(book: .testData(id: "book-01"))])
        let loanService = StubLoanService()
        loanService.loansResponse = .success([])
        loanService.borrowBookResponse = .success(.testData())

        let sut = createSUT(listingService: listingService,
                            loanService: loanService)

        await sut.load()

        let row = try #require(sut.state.rows.first)

        await sut.borrowBook(row)

        #expect(loanService.events == [.loans, .borrowBook(.testData(id: "book-01")), .loans])
    }

    @Test("Given a row is borrowed, when that borrow is successful, then the row is on loan to you")
    func successfulBorrowBook() async throws {
        let listingService = StubListingService()
        listingService.listingsResponse = .success([.testData(book: .testData(id: "book-01"))])
        let loanService = StubLoanService()
        loanService.loansResponse = .success([])
        loanService.borrowBookResponse = .success(.testData())

        let sut = createSUT(listingService: listingService,
                            loanService: loanService)

        await sut.load()

        let row = try #require(sut.state.rows.first)

        loanService.loansResponse = .success([.testData(book: .testData(id: "book-01"))])

        await sut.borrowBook(row)

        let updatedRow = try #require(sut.state.rows.first)

        #expect(updatedRow.availability == .onLoanToYou)
    }

    @Test("Given a row is borrowed, when that borrow fails, then the matching alert is set",
          arguments: zip(
            [
              .loanLimitReached,
              .failed
            ] as [BorrowBookServiceError],
            [
              .loanLimitReached,
              .borrowFailed
            ] as [CatalogueViewModel.Alert]
          )
    )
    func failedBorrowBook(borrowError: BorrowBookServiceError,
                          expectedAlert: CatalogueViewModel.Alert) async throws {
        let listingService = StubListingService()
        listingService.listingsResponse = .success([.testData(book: .testData(id: "book-01"))])
        let loanService = StubLoanService()
        loanService.loansResponse = .success([])
        loanService.borrowBookResponse = .failure(borrowError)

        let sut = createSUT(listingService: listingService,
                            loanService: loanService)

        await sut.load()

        let row = try #require(sut.state.rows.first)

        await sut.borrowBook(row)

        #expect(sut.alert == expectedAlert)
    }

    @Test("Given a row is borrowed, when that borrow fails, then the loans aren't refreshed")
    func failedBorrowBookDoesNotRefreshLoans() async throws {
        let listingService = StubListingService()
        listingService.listingsResponse = .success([.testData(book: .testData(id: "book-01"))])
        let loanService = StubLoanService()
        loanService.loansResponse = .success([])
        loanService.borrowBookResponse = .failure(.failed)

        let sut = createSUT(listingService: listingService,
                            loanService: loanService)

        await sut.load()

        let row = try #require(sut.state.rows.first)

        await sut.borrowBook(row)

        #expect(loanService.events == [.loans, .borrowBook(.testData(id: "book-01"))])
    }

    @Test("Given a row is borrowed, when that borrow is successful but the loans refresh fails, then the state is failed")
    func successfulBorrowBookWithFailedRefresh() async throws {
        let listingService = StubListingService()
        listingService.listingsResponse = .success([.testData()])
        let loanService = StubLoanService()
        loanService.loansResponse = .success([])
        loanService.borrowBookResponse = .success(.testData())

        let sut = createSUT(listingService: listingService,
                            loanService: loanService)

        await sut.load()

        let row = try #require(sut.state.rows.first)

        loanService.loansResponse = .failure(.failed)

        await sut.borrowBook(row)

        #expect(sut.state == .failed)
    }

    @Test("Given a row is borrowed, when that row doesn't match a loaded listing, then the loan service isn't asked to borrow")
    func borrowBookWithUnknownRow() async throws {
        let listingService = StubListingService()
        listingService.listingsResponse = .success([.testData(book: .testData(id: "book-01"))])
        let loanService = StubLoanService()
        loanService.loansResponse = .success([])

        let sut = createSUT(listingService: listingService,
                            loanService: loanService)

        await sut.load()
        await sut.borrowBook(.testData(id: "book-99"))

        #expect(loanService.events == [.loans])
    }

    // MARK: - ReturnBook

    @Test("Given a row is returned, when the return is made, then the loan service is asked to return that row's book and the loans are refreshed")
    func returnBookRequest() async throws {
        let listingService = StubListingService()
        listingService.listingsResponse = .success([.testData(book: .testData(id: "book-01"))])
        let loanService = StubLoanService()
        loanService.loansResponse = .success([.testData(book: .testData(id: "book-01"))])
        loanService.returnBookResponse = .success(())

        let sut = createSUT(listingService: listingService,
                            loanService: loanService)

        await sut.load()

        let row = try #require(sut.state.rows.first)

        await sut.returnBook(row)

        #expect(loanService.events == [.loans, .returnBook(.testData(id: "book-01")), .loans])
    }

    @Test("Given a row is returned, when that return is successful, then the row is available")
    func successfulReturnBook() async throws {
        let listingService = StubListingService()
        listingService.listingsResponse = .success([.testData(book: .testData(id: "book-01"),
                                                              availability: .onLoanToYou)])
        let loanService = StubLoanService()
        loanService.loansResponse = .success([.testData(book: .testData(id: "book-01"))])
        loanService.returnBookResponse = .success(())

        let sut = createSUT(listingService: listingService,
                            loanService: loanService)

        await sut.load()

        let row = try #require(sut.state.rows.first)

        loanService.loansResponse = .success([])

        await sut.returnBook(row)

        let updatedRow = try #require(sut.state.rows.first)

        #expect(updatedRow.availability == .available)
    }

    @Test("Given a row is returned, when that return fails, then the return failed alert is set")
    func failedReturnBook() async throws {
        let listingService = StubListingService()
        listingService.listingsResponse = .success([.testData(book: .testData(id: "book-01"))])
        let loanService = StubLoanService()
        loanService.loansResponse = .success([.testData(book: .testData(id: "book-01"))])
        loanService.returnBookResponse = .failure(.failed)

        let sut = createSUT(listingService: listingService,
                            loanService: loanService)

        await sut.load()

        let row = try #require(sut.state.rows.first)

        await sut.returnBook(row)

        #expect(sut.alert == .returnFailed)
    }

    @Test("Given a row is returned, when that return fails, then the loans aren't refreshed")
    func failedReturnBookDoesNotRefreshLoans() async throws {
        let listingService = StubListingService()
        listingService.listingsResponse = .success([.testData(book: .testData(id: "book-01"))])
        let loanService = StubLoanService()
        loanService.loansResponse = .success([.testData(book: .testData(id: "book-01"))])
        loanService.returnBookResponse = .failure(.failed)

        let sut = createSUT(listingService: listingService,
                            loanService: loanService)

        await sut.load()

        let row = try #require(sut.state.rows.first)

        await sut.returnBook(row)

        #expect(loanService.events == [.loans, .returnBook(.testData(id: "book-01"))])
    }

    @Test("Given a row is returned, when that return is successful but the loans refresh fails, then the state is failed")
    func successfulReturnBookWithFailedRefresh() async throws {
        let listingService = StubListingService()
        listingService.listingsResponse = .success([.testData()])
        let loanService = StubLoanService()
        loanService.loansResponse = .success([.testData()])
        loanService.returnBookResponse = .success(())

        let sut = createSUT(listingService: listingService,
                            loanService: loanService)

        await sut.load()

        let row = try #require(sut.state.rows.first)

        loanService.loansResponse = .failure(.failed)

        await sut.returnBook(row)

        #expect(sut.state == .failed)
    }

    @Test("Given a row is returned, when that row doesn't match a loaded listing, then the loan service isn't asked to return")
    func returnBookWithUnknownRow() async throws {
        let listingService = StubListingService()
        listingService.listingsResponse = .success([.testData(book: .testData(id: "book-01"))])
        let loanService = StubLoanService()
        loanService.loansResponse = .success([])

        let sut = createSUT(listingService: listingService,
                            loanService: loanService)

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
        let listingService = StubListingService()
        listingService.listingsResponse = .success([.testData(book: .testData(id: "book-01"))])
        let loanService = StubLoanService()
        loanService.loansResponse = .success([.testData(book: .testData(id: "book-01"))])
        loanService.returnBookResponse = .failure(.failed)

        let sut = createSUT(listingService: listingService,
                            loanService: loanService)

        await sut.load()

        let row = try #require(sut.state.rows.first)

        await sut.returnBook(row)

        #expect(sut.isShowingAlert == true)
    }

    @Test("Given an alert is showing, when it's dismissed, then the alert is cleared")
    func dismissAlert() async throws {
        let listingService = StubListingService()
        listingService.listingsResponse = .success([.testData(book: .testData(id: "book-01"))])
        let loanService = StubLoanService()
        loanService.loansResponse = .success([.testData(book: .testData(id: "book-01"))])
        loanService.returnBookResponse = .failure(.failed)

        let sut = createSUT(listingService: listingService,
                            loanService: loanService)

        await sut.load()

        let row = try #require(sut.state.rows.first)

        await sut.returnBook(row)

        sut.isShowingAlert = false

        #expect(sut.alert == nil)
    }

    // MARK: - RowAction

    @Test("Given a row, when checking its action, then the action follows from the row's availability",
          arguments: [
            (.available, .borrow),
            (.onLoan, nil),
            (.onLoanToYou, .return)
          ] as [(CatalogueViewModel.Row.Availability, CatalogueViewModel.Row.Action?)]
    )
    func rowAction(availability: CatalogueViewModel.Row.Availability,
                   expectedAction: CatalogueViewModel.Row.Action?) {
        let sut = CatalogueViewModel.Row.testData(availability: availability)

        #expect(sut.action == expectedAction)
    }
}

extension CatalogueViewModelTests {
    func createSUT(listingService: ListingService = StubListingService(),
                   loanService: LoanService = StubLoanService()) -> CatalogueViewModel {
        CatalogueViewModel(listingService: listingService,
                           loanService: loanService)
    }
}
