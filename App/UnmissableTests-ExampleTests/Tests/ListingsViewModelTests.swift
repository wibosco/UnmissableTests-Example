//
//  ListingsViewModelTests.swift
//  UnmissableTests-ExampleTests
//
//  Created by William Boles on 18/10/2026.
//

import Foundation
import Testing

@testable import UnmissableTests_Example

struct ListingsViewModelTests {

    // MARK: - Load

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
        listingService.listingsResponse = .success([.testData(book: .testData(id: "book-01"),
                                                              availability: .available)])
        let loanService = StubLoanService()
        loanService.loansResponse = .success([])

        let sut = createSUT(listingService: listingService,
                            loanService: loanService)

        await sut.load()

        let expectedRows = [ListingsViewModel.Row(id: "book-01",
                                                  title: "test_title",
                                                  authorName: "test_lastName, test_firstName",
                                                  coverImageName: "test_coverImageName",
                                                  availability: .available,
                                                  action: .borrow)]

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

        let expectedRows = [ListingsViewModel.Row(id: "book-04",
                                                  title: "Emma",
                                                  authorName: "Austen, Jane",
                                                  coverImageName: "test_coverImageName",
                                                  availability: .available,
                                                  action: .borrow),
                            ListingsViewModel.Row(id: "book-02",
                                                  title: "Pride and Prejudice",
                                                  authorName: "Austen, Jane",
                                                  coverImageName: "test_coverImageName",
                                                  availability: .available,
                                                  action: .borrow),
                            ListingsViewModel.Row(id: "book-03",
                                                  title: "Jane Eyre",
                                                  authorName: "Brontë, Charlotte",
                                                  coverImageName: "test_coverImageName",
                                                  availability: .available,
                                                  action: .borrow),
                            ListingsViewModel.Row(id: "book-01",
                                                  title: "Wuthering Heights",
                                                  authorName: "Brontë, Emily",
                                                  coverImageName: "test_coverImageName",
                                                  availability: .available,
                                                  action: .borrow)]

        #expect(sut.state == .loaded(expectedRows))
    }

    @Test("Given listings are loaded, when a listing isn't on loan to the user, then its row's availability and action come from the listing",
          arguments: [
            (.available, .available, .borrow),
            (.onLoan, .onLoan, nil),
            (.onLoanToYou, .available, .borrow)
          ] as [(Availability, ListingsViewModel.Row.Availability, ListingsViewModel.Row.Action?)]
    )
    func loadNotLoanedListing(listingAvailability: Availability,
                              expectedAvailability: ListingsViewModel.Row.Availability,
                              expectedAction: ListingsViewModel.Row.Action?) async throws {
        let listingService = StubListingService()
        listingService.listingsResponse = .success([.testData(book: .testData(id: "book-01"),
                                                              availability: listingAvailability)])
        let loanService = StubLoanService()
        loanService.loansResponse = .success([])

        let sut = createSUT(listingService: listingService,
                            loanService: loanService)

        await sut.load()

        let expectedRows = [ListingsViewModel.Row(id: "book-01",
                                                  title: "test_title",
                                                  authorName: "test_lastName, test_firstName",
                                                  coverImageName: "test_coverImageName",
                                                  availability: expectedAvailability,
                                                  action: expectedAction)]

        #expect(sut.state == .loaded(expectedRows))
    }

    @Test("Given listings are loaded, when a listing is on loan to the user, then its row is on loan to you and can be returned",
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

        let expectedRows = [ListingsViewModel.Row(id: "book-01",
                                                  title: "test_title",
                                                  authorName: "test_lastName, test_firstName",
                                                  coverImageName: "test_coverImageName",
                                                  availability: .onLoanToYou,
                                                  action: .return)]

        #expect(sut.state == .loaded(expectedRows))
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

    // MARK: - Borrow

    @Test("Given a row is borrowed, when the borrow is made, then the loan service is asked to borrow that row's book and the loans are refreshed")
    func borrowRequest() async throws {
        let listingService = StubListingService()
        listingService.listingsResponse = .success([.testData(book: .testData(id: "book-01"))])
        let loanService = StubLoanService()
        loanService.loansResponse = .success([])
        loanService.borrowBookResponse = .success(.testData(book: .testData(id: "book-01")))

        let sut = createSUT(listingService: listingService,
                            loanService: loanService)

        await sut.load()
        await sut.borrow(ListingsViewModel.Row(id: "book-01",
                                               title: "test_title",
                                               authorName: "test_lastName, test_firstName",
                                               coverImageName: "test_coverImageName",
                                               availability: .available,
                                               action: .borrow))

        #expect(loanService.events == [.loans, .borrowBook(.testData(id: "book-01")), .loans])
    }

    @Test("Given a row is borrowed, when that borrow is successful, then the row is on loan to you and can be returned")
    func successfulBorrow() async throws {
        let listingService = StubListingService()
        listingService.listingsResponse = .success([.testData(book: .testData(id: "book-01"))])
        let loanService = StubLoanService()
        loanService.loansResponse = .success([])
        loanService.borrowBookResponse = .success(.testData(book: .testData(id: "book-01")))

        let sut = createSUT(listingService: listingService,
                            loanService: loanService)

        await sut.load()

        loanService.loansResponse = .success([.testData(book: .testData(id: "book-01"))])

        await sut.borrow(ListingsViewModel.Row(id: "book-01",
                                               title: "test_title",
                                               authorName: "test_lastName, test_firstName",
                                               coverImageName: "test_coverImageName",
                                               availability: .available,
                                               action: .borrow))

        let expectedRows = [ListingsViewModel.Row(id: "book-01",
                                                  title: "test_title",
                                                  authorName: "test_lastName, test_firstName",
                                                  coverImageName: "test_coverImageName",
                                                  availability: .onLoanToYou,
                                                  action: .return)]

        #expect(sut.state == .loaded(expectedRows))
    }

    @Test("Given a row is borrowed, when that borrow fails, then the matching alert is set",
          arguments: zip(
            [
              .loanLimitReached,
              .failed
            ] as [BorrowBookError],
            [
              .loanLimitReached,
              .borrowFailed
            ] as [ListingsViewModel.Alert]
          )
    )
    func failedBorrow(borrowError: BorrowBookError,
                      expectedAlert: ListingsViewModel.Alert) async throws {
        let listingService = StubListingService()
        listingService.listingsResponse = .success([.testData(book: .testData(id: "book-01"))])
        let loanService = StubLoanService()
        loanService.loansResponse = .success([])
        loanService.borrowBookResponse = .failure(borrowError)

        let sut = createSUT(listingService: listingService,
                            loanService: loanService)

        await sut.load()
        await sut.borrow(ListingsViewModel.Row(id: "book-01",
                                               title: "test_title",
                                               authorName: "test_lastName, test_firstName",
                                               coverImageName: "test_coverImageName",
                                               availability: .available,
                                               action: .borrow))

        #expect(sut.alert == expectedAlert)
    }

    @Test("Given a row is borrowed, when that row doesn't match a loaded listing, then the loan service isn't asked to borrow")
    func borrowUnknownRow() async throws {
        let listingService = StubListingService()
        listingService.listingsResponse = .success([.testData(book: .testData(id: "book-01"))])
        let loanService = StubLoanService()
        loanService.loansResponse = .success([])

        let sut = createSUT(listingService: listingService,
                            loanService: loanService)

        await sut.load()
        await sut.borrow(ListingsViewModel.Row(id: "book-99",
                                               title: "test_title",
                                               authorName: "test_lastName, test_firstName",
                                               coverImageName: "test_coverImageName",
                                               availability: .available,
                                               action: .borrow))

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
        await sut.returnBook(ListingsViewModel.Row(id: "book-01",
                                                   title: "test_title",
                                                   authorName: "test_lastName, test_firstName",
                                                   coverImageName: "test_coverImageName",
                                                   availability: .onLoanToYou,
                                                   action: .return))

        #expect(loanService.events == [.loans, .returnBook(.testData(id: "book-01")), .loans])
    }

    @Test("Given a row is returned, when that return is successful, then the row is available and can be borrowed")
    func successfulReturnBook() async throws {
        let listingService = StubListingService()
        listingService.listingsResponse = .success([.testData(book: .testData(id: "book-01"))])
        let loanService = StubLoanService()
        loanService.loansResponse = .success([.testData(book: .testData(id: "book-01"))])
        loanService.returnBookResponse = .success(())

        let sut = createSUT(listingService: listingService,
                            loanService: loanService)

        await sut.load()

        loanService.loansResponse = .success([])

        await sut.returnBook(ListingsViewModel.Row(id: "book-01",
                                                   title: "test_title",
                                                   authorName: "test_lastName, test_firstName",
                                                   coverImageName: "test_coverImageName",
                                                   availability: .onLoanToYou,
                                                   action: .return))

        let expectedRows = [ListingsViewModel.Row(id: "book-01",
                                                  title: "test_title",
                                                  authorName: "test_lastName, test_firstName",
                                                  coverImageName: "test_coverImageName",
                                                  availability: .available,
                                                  action: .borrow)]

        #expect(sut.state == .loaded(expectedRows))
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
        await sut.returnBook(ListingsViewModel.Row(id: "book-01",
                                                   title: "test_title",
                                                   authorName: "test_lastName, test_firstName",
                                                   coverImageName: "test_coverImageName",
                                                   availability: .onLoanToYou,
                                                   action: .return))

        #expect(sut.alert == .returnFailed)
    }

    @Test("Given a row is returned, when that row doesn't match a loaded listing, then the loan service isn't asked to return")
    func returnUnknownRow() async throws {
        let listingService = StubListingService()
        listingService.listingsResponse = .success([.testData(book: .testData(id: "book-01"))])
        let loanService = StubLoanService()
        loanService.loansResponse = .success([])

        let sut = createSUT(listingService: listingService,
                            loanService: loanService)

        await sut.load()
        await sut.returnBook(ListingsViewModel.Row(id: "book-99",
                                                   title: "test_title",
                                                   authorName: "test_lastName, test_firstName",
                                                   coverImageName: "test_coverImageName",
                                                   availability: .onLoanToYou,
                                                   action: .return))

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
        await sut.returnBook(ListingsViewModel.Row(id: "book-01",
                                                   title: "test_title",
                                                   authorName: "test_lastName, test_firstName",
                                                   coverImageName: "test_coverImageName",
                                                   availability: .onLoanToYou,
                                                   action: .return))

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
        await sut.returnBook(ListingsViewModel.Row(id: "book-01",
                                                   title: "test_title",
                                                   authorName: "test_lastName, test_firstName",
                                                   coverImageName: "test_coverImageName",
                                                   availability: .onLoanToYou,
                                                   action: .return))

        sut.isShowingAlert = false

        #expect(sut.alert == nil)
    }
}

extension ListingsViewModelTests {
    func createSUT(listingService: ListingService = StubListingService(),
                   loanService: LoanService? = nil) -> ListingsViewModel {
        // `StubLoanService` is main actor-isolated, so it can't be created in a default argument.
        ListingsViewModel(listingService: listingService,
                          loanService: loanService ?? StubLoanService())
    }
}
