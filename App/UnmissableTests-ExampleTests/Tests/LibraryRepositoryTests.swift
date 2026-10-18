//
//  LibraryRepositoryTests.swift
//  UnmissableTests-ExampleTests
//
//  Created by William Boles on 18/10/2026.
//

import Foundation
import Testing

@testable import UnmissableTests_Example

struct LibraryRepositoryTests {

    // MARK: - RetrieveListings

    @Test("Given listings are retrieved, when the request is made, then a GET request is sent to the books endpoint")
    func listingsRetrievalRequest() async throws {
        let networkService = StubNetworkService()
        networkService.sendResponse = .success(BookListDTO.testData())

        let sut = createSUT(baseURL: URL(string: "https://catalogue.example.org")!,
                            networkService: networkService)

        _ = try await sut.retrieveListings()

        let expectedRequest = URLRequest(url: URL(string: "https://catalogue.example.org/books")!)

        #expect(networkService.events == [.send(expectedRequest)])
    }

    @Test("Given listings are retrieved, when that retrieval and mapping is successful, then each book's details are mapped")
    func successfulListingsRetrieval() async throws {
        let networkService = StubNetworkService()
        let bookDTOs: [BookDTO] = [.testData(id: "book-01",
                                             title: "Dracula",
                                             author: .testData(firstName: "Bram",
                                                               lastName: "Stoker"),
                                             coverImageName: "dracula")]
        networkService.sendResponse = .success(BookListDTO.testData(books: bookDTOs))

        let sut = createSUT(networkService: networkService)

        let listings = try await sut.retrieveListings()

        let expectedBook = Book.testData(id: "book-01",
                                         title: "Dracula",
                                         author: .testData(firstName: "Bram",
                                                           lastName: "Stoker"),
                                         coverImageName: "dracula")

        #expect(listings.map(\.book) == [expectedBook])
    }

    @Test("Given listings are retrieved, when that retrieval and mapping is successful, then each book's availability is mapped",
          arguments: zip(
            [
              .available,
              .onLoan,
              .onLoanToYou
            ] as [BookDTO.AvailabilityDTO],
            [
              .available,
              .onLoan,
              .onLoanToYou
            ] as [Availability]
          )
    )
    func listingsAvailabilityMapping(dtoAvailability: BookDTO.AvailabilityDTO,
                                     expectedAvailability: Availability) async throws {
        let networkService = StubNetworkService()
        networkService.sendResponse = .success(BookListDTO.testData(books: [.testData(availability: dtoAvailability)]))

        let sut = createSUT(networkService: networkService)

        let listings = try await sut.retrieveListings()

        #expect(listings.map(\.availability) == [expectedAvailability])
    }

    @Test("Given listings are retrieved, when that retrieval fails, then a failed error is thrown",
          arguments: [
            .requestFailed,
            .unacceptableStatusCode(500),
            .decodingFailed
          ] as [NetworkServiceError<RetrieveListingsErrorDTO>]
    )
    func failedListingsRetrieval(networkError: NetworkServiceError<RetrieveListingsErrorDTO>) async throws {
        let networkService = StubNetworkService()
        networkService.sendResponse = .failure(networkError)

        let sut = createSUT(networkService: networkService)

        await #expect(throws: RetrieveListingsRepositoryError.failed) {
            try await sut.retrieveListings()
        }
    }

    @Test("Given listings are retrieved, when the server responds with a catalogue unavailable failure, then a catalogue unavailable error is thrown")
    func failedListingsRetrievalWithErrorResponse() async throws {
        let networkService = StubNetworkService()
        networkService.sendResponse = .failure(NetworkServiceError.failureResponse(RetrieveListingsErrorDTO.testData(error: .catalogueUnavailable)))

        let sut = createSUT(networkService: networkService)

        await #expect(throws: RetrieveListingsRepositoryError.catalogueUnavailable) {
            try await sut.retrieveListings()
        }
    }

    // MARK: - RetrieveLoans

    @Test("Given loans are retrieved, when the request is made, then a GET request is sent to the loans endpoint")
    func loansRetrievalRequest() async throws {
        let networkService = StubNetworkService()
        networkService.sendResponse = .success(LoanListDTO.testData())

        let sut = createSUT(baseURL: URL(string: "https://catalogue.example.org")!,
                            networkService: networkService)

        _ = try await sut.retrieveLoans()

        let expectedRequest = URLRequest(url: URL(string: "https://catalogue.example.org/loans")!)

        #expect(networkService.events == [.send(expectedRequest)])
    }

    @Test("Given loans are retrieved, when that retrieval and mapping is successful, then each loan's details are mapped")
    func successfulLoansRetrieval() async throws {
        let networkService = StubNetworkService()
        let loanDTOs: [LoanDTO] = [.testData(book: .testData(id: "book-01",
                                                             title: "Dracula",
                                                             author: .testData(firstName: "Bram",
                                                                               lastName: "Stoker"),
                                                             coverImageName: "dracula"),
                                             dueDate: Date(timeIntervalSince1970: 100))]
        networkService.sendResponse = .success(LoanListDTO.testData(loans: loanDTOs))

        let sut = createSUT(networkService: networkService)

        let loans = try await sut.retrieveLoans()

        let expectedLoan = Loan.testData(book: .testData(id: "book-01",
                                                         title: "Dracula",
                                                         author: .testData(firstName: "Bram",
                                                                           lastName: "Stoker"),
                                                         coverImageName: "dracula"),
                                         dueDate: Date(timeIntervalSince1970: 100))

        #expect(loans == [expectedLoan])
    }

    @Test("Given loans are retrieved, when that retrieval fails, then a failed error is thrown",
          arguments: [
            .requestFailed,
            .unacceptableStatusCode(500),
            .decodingFailed
          ] as [NetworkServiceError<RetrieveLoansErrorDTO>]
    )
    func failedLoansRetrieval(networkError: NetworkServiceError<RetrieveLoansErrorDTO>) async throws {
        let networkService = StubNetworkService()
        networkService.sendResponse = .failure(networkError)

        let sut = createSUT(networkService: networkService)

        await #expect(throws: RetrieveLoansRepositoryError.failed) {
            try await sut.retrieveLoans()
        }
    }

    @Test("Given loans are retrieved, when the server responds with a membership expired failure, then a membership expired error is thrown")
    func failedLoansRetrievalWithErrorResponse() async throws {
        let networkService = StubNetworkService()
        networkService.sendResponse = .failure(NetworkServiceError.failureResponse(RetrieveLoansErrorDTO.testData(error: .membershipExpired)))

        let sut = createSUT(networkService: networkService)

        await #expect(throws: RetrieveLoansRepositoryError.membershipExpired) {
            try await sut.retrieveLoans()
        }
    }

    // MARK: - CreateLoan

    @Test("Given a loan is created, when the request is made, then a PUT request is sent to that book's loan endpoint")
    func createLoanRequest() async throws {
        let networkService = StubNetworkService()
        networkService.sendResponse = .success(LoanDTO.testData())

        let sut = createSUT(baseURL: URL(string: "https://catalogue.example.org")!,
                            networkService: networkService)

        _ = try await sut.createLoan(forBookID: "book-01")

        var expectedRequest = URLRequest(url: URL(string: "https://catalogue.example.org/loans/book-01")!)
        expectedRequest.httpMethod = "PUT"

        #expect(networkService.events == [.send(expectedRequest)])
    }

    @Test("Given a loan is created, when that creation and mapping is successful, then the created loan is returned")
    func successfulCreateLoan() async throws {
        let networkService = StubNetworkService()
        let loanDTO = LoanDTO.testData(book: .testData(id: "book-01",
                                                       title: "Dracula",
                                                       author: .testData(firstName: "Bram",
                                                                         lastName: "Stoker"),
                                                       coverImageName: "dracula"),
                                       dueDate: Date(timeIntervalSince1970: 100))
        networkService.sendResponse = .success(loanDTO)

        let sut = createSUT(networkService: networkService)

        let loan = try await sut.createLoan(forBookID: "book-01")

        let expectedLoan = Loan.testData(book: .testData(id: "book-01",
                                                         title: "Dracula",
                                                         author: .testData(firstName: "Bram",
                                                                           lastName: "Stoker"),
                                                         coverImageName: "dracula"),
                                         dueDate: Date(timeIntervalSince1970: 100))

        #expect(loan == expectedLoan)
    }

    @Test("Given a loan is created, when the server responds with a failure, then the matching error is thrown",
          arguments: zip(
            [
              .loanLimitReached,
              .bookUnavailable
            ] as [CreateLoanErrorDTO.CodeDTO],
            [
              .loanLimitReached,
              .bookUnavailable
            ] as [CreateLoanRepositoryError]
          )
    )
    func failedCreateLoanWithErrorResponse(code: CreateLoanErrorDTO.CodeDTO,
                                           expectedError: CreateLoanRepositoryError) async throws {
        let networkService = StubNetworkService()
        networkService.sendResponse = .failure(NetworkServiceError.failureResponse(CreateLoanErrorDTO.testData(error: code)))

        let sut = createSUT(networkService: networkService)

        await #expect(throws: expectedError) {
            try await sut.createLoan(forBookID: "book-01")
        }
    }

    @Test("Given a loan is created, when that creation fails, then a failed error is thrown",
          arguments: [
            .requestFailed,
            .unacceptableStatusCode(500),
            .decodingFailed
          ] as [NetworkServiceError<CreateLoanErrorDTO>]
    )
    func failedCreateLoan(networkError: NetworkServiceError<CreateLoanErrorDTO>) async throws {
        let networkService = StubNetworkService()
        networkService.sendResponse = .failure(networkError)

        let sut = createSUT(networkService: networkService)

        await #expect(throws: CreateLoanRepositoryError.failed) {
            try await sut.createLoan(forBookID: "book-01")
        }
    }

    // MARK: - DeleteLoan

    @Test("Given a loan is deleted, when the request is made, then a DELETE request is sent to that book's loan endpoint")
    func deleteLoanRequest() async throws {
        let networkService = StubNetworkService()
        networkService.sendResponse = .success(BookDTO.testData())

        let sut = createSUT(baseURL: URL(string: "https://catalogue.example.org")!,
                            networkService: networkService)

        _ = try await sut.deleteLoan(forBookID: "book-01")

        var expectedRequest = URLRequest(url: URL(string: "https://catalogue.example.org/loans/book-01")!)
        expectedRequest.httpMethod = "DELETE"

        #expect(networkService.events == [.send(expectedRequest)])
    }

    @Test("Given a loan is deleted, when that deletion and mapping is successful, then the book's listing is returned")
    func successfulDeleteLoan() async throws {
        let networkService = StubNetworkService()
        let bookDTO = BookDTO.testData(id: "book-01",
                                       title: "Dracula",
                                       author: .testData(firstName: "Bram",
                                                         lastName: "Stoker"),
                                       coverImageName: "dracula",
                                       availability: .onLoan)
        networkService.sendResponse = .success(bookDTO)

        let sut = createSUT(networkService: networkService)

        let listing = try await sut.deleteLoan(forBookID: "book-01")

        let expectedListing = Listing.testData(book: .testData(id: "book-01",
                                                               title: "Dracula",
                                                               author: .testData(firstName: "Bram",
                                                                                 lastName: "Stoker"),
                                                               coverImageName: "dracula"),
                                               availability: .onLoan)

        #expect(listing == expectedListing)
    }

    @Test("Given a loan is deleted, when the server responds with a not borrowed failure, then a not borrowed error is thrown")
    func failedDeleteLoanWithErrorResponse() async throws {
        let networkService = StubNetworkService()
        networkService.sendResponse = .failure(NetworkServiceError.failureResponse(DeleteLoanErrorDTO.testData(error: .notBorrowed)))

        let sut = createSUT(networkService: networkService)

        await #expect(throws: DeleteLoanRepositoryError.notBorrowed) {
            try await sut.deleteLoan(forBookID: "book-01")
        }
    }

    @Test("Given a loan is deleted, when that deletion fails, then a failed error is thrown",
          arguments: [
            .requestFailed,
            .unacceptableStatusCode(500),
            .decodingFailed
          ] as [NetworkServiceError<DeleteLoanErrorDTO>]
    )
    func failedDeleteLoan(networkError: NetworkServiceError<DeleteLoanErrorDTO>) async throws {
        let networkService = StubNetworkService()
        networkService.sendResponse = .failure(networkError)

        let sut = createSUT(networkService: networkService)

        await #expect(throws: DeleteLoanRepositoryError.failed) {
            try await sut.deleteLoan(forBookID: "book-01")
        }
    }
}

extension LibraryRepositoryTests {
    func createSUT(baseURL: URL = URL(string: "https://library.example.com")!,
                   networkService: NetworkService = StubNetworkService()) -> DefaultLibraryRepository {
        DefaultLibraryRepository(baseURL: baseURL,
                                 networkService: networkService)
    }
}
