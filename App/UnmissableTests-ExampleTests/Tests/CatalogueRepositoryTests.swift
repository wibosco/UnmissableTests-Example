//
//  CatalogueRepositoryTests.swift
//  UnmissableTests-ExampleTests
//
//  Created by William Boles on 18/10/2026.
//

import Foundation
import Testing

@testable import UnmissableTests_Example

struct CatalogueRepositoryTests {
    
    // MARK: - RetrieveListings
    
    @Test("Given listings are retrieved, when the request is made, then a GET request is sent to the books endpoint")
    func listingsRetrievalRequest() async throws {
        let networkService = StubNetworkService()
        networkService.sendResponse = .success([BookDTO]())
        
        let sut = createSUT(networkService: networkService)
        
        _ = try await sut.retrieveListings()
        
        let expectedRequest = URLRequest(url: URL(string: "https://library.example.com/books")!)
        
        #expect(networkService.events == [.send(expectedRequest, 200..<300)])
    }
    
    @Test("Given listing are retrieved, when that retrieval and mapping is successful, then an array of Listings is returned")
    func successfulListingsRetrieval() async throws {
        let networkService = StubNetworkService()
        let bookDTOs: [BookDTO] = [.testData(id: "book-01",
                                             availability: .available),
                                   .testData(id: "book-02",
                                             availability: .onLoan),
                                   .testData(id: "book-03",
                                             availability: .onLoanToYou)]
        networkService.sendResponse = .success(bookDTOs)

        let sut = createSUT(networkService: networkService)

        let listings = try await sut.retrieveListings()

        let expectedListings: [Listing] = [.testData(book: .testData(id: "book-01"),
                                                     availability: .available),
                                           .testData(book: .testData(id: "book-02"),
                                                     availability: .onLoan),
                                           .testData(book: .testData(id: "book-03"),
                                                     availability: .onLoanToYou)]

        #expect(listings == expectedListings)
    }
    
    @Test("Given listings are retrieved, when that retrieval fails, then a failed error is thrown",
          arguments: [
            .requestFailed,
            .unacceptableStatusCode(500),
            .decodingFailed
          ] as [NetworkServiceError<Never>]
    )
    func failedListingsRetrieval(networkError: NetworkServiceError<Never>) async throws {
        let networkService = StubNetworkService()
        networkService.sendResponse = .failure(networkError)
        
        let sut = createSUT(networkService: networkService)
        
        await #expect(throws: ListingsError.failed) {
            try await sut.retrieveListings()
        }
    }
    
    // MARK: - RetrieveLoans
    
    @Test("Given loans are retrieved, when the request is made, then a GET request is sent to the loans endpoint")
    func loansRetrievalRequest() async throws {
        let networkService = StubNetworkService()
        networkService.sendResponse = .success([LoanDTO]())
        
        let sut = createSUT(networkService: networkService)
        
        _ = try await sut.retrieveLoans()
        
        let expectedRequest = URLRequest(url: URL(string: "https://library.example.com/loans")!)
        
        #expect(networkService.events == [.send(expectedRequest, 200..<300)])
    }
    
    @Test("Given loans are retrieved, when that retrieval and mapping is successful, then an array of Loans is returned")
    func successfulLoansRetrieval() async throws {
        let networkService = StubNetworkService()
        let loanDTOs: [LoanDTO] = [.testData(book: .testData(id: "book-01"),
                                             dueDate: Date(timeIntervalSince1970: 100)),
                                   .testData(book: .testData(id: "book-02"),
                                             dueDate: Date(timeIntervalSince1970: 200))]
        networkService.sendResponse = .success(loanDTOs)
        
        let sut = createSUT(networkService: networkService)
        
        let loans = try await sut.retrieveLoans()
        
        let expectedLoans: [Loan] = [.testData(book: .testData(id: "book-01"),
                                               dueDate: Date(timeIntervalSince1970: 100)),
                                     .testData(book: .testData(id: "book-02"),
                                               dueDate: Date(timeIntervalSince1970: 200))]
        
        #expect(loans == expectedLoans)
    }
    
    @Test("Given loans are retrieved, when that retrieval fails, then a failed error is thrown",
          arguments: [
            .requestFailed,
            .unacceptableStatusCode(500),
            .decodingFailed
          ] as [NetworkServiceError<Never>]
    )
    func failedLoansRetrieval(networkError: NetworkServiceError<Never>) async throws {
        let networkService = StubNetworkService()
        networkService.sendResponse = .failure(networkError)
        
        let sut = createSUT(networkService: networkService)
        
        await #expect(throws: LoansError.failed) {
            try await sut.retrieveLoans()
        }
    }
    
    // MARK: - CheckOutBook
    
    @Test("Given a book is checked out, when the request is made, then a POST request is sent to that book's checkout endpoint")
    func checkOutRequest() async throws {
        let networkService = StubNetworkService()
        networkService.sendResponse = .success(LoanDTO.testData())
        
        let sut = createSUT(networkService: networkService)
        
        _ = try await sut.checkOutBook("book-01")
        
        var expectedRequest = URLRequest(url: URL(string: "https://library.example.com/books/book-01/checkout")!)
        expectedRequest.httpMethod = "POST"
        
        #expect(networkService.events == [.send(expectedRequest, 200..<300)])
    }
    
    @Test("Given a book is checked out, when that check out and mapping is successful, then a Loan is returned")
    func successfulCheckOut() async throws {
        let networkService = StubNetworkService()
        let loanDTO = LoanDTO.testData(book: .testData(id: "book-01"),
                                       dueDate: Date(timeIntervalSince1970: 100))
        networkService.sendResponse = .success(loanDTO)
        
        let sut = createSUT(networkService: networkService)
        
        let loan = try await sut.checkOutBook("book-01")
        
        let expectedLoan = Loan.testData(book: .testData(id: "book-01"),
                                         dueDate: Date(timeIntervalSince1970: 100))
        
        #expect(loan == expectedLoan)
    }
    
    @Test("Given a book is checked out, when the server responds with a failure, then the matching error is thrown",
          arguments: zip(
            [
              .alreadyBorrowed,
              .loanLimitReached,
              .bookUnavailable
            ] as [CheckOutErrorDTO.Code],
            [
              .alreadyBorrowed,
              .loanLimitReached,
              .bookUnavailable
            ] as [CheckOutError]
          )
    )
    func checkOutFailureResponse(code: CheckOutErrorDTO.Code,
                                 expectedError: CheckOutError) async throws {
        let networkService = StubNetworkService()
        networkService.sendResponse = .failure(NetworkServiceError.failureResponse(CheckOutErrorDTO.testData(error: code)))
        
        let sut = createSUT(networkService: networkService)
        
        await #expect(throws: expectedError) {
            try await sut.checkOutBook("book-01")
        }
    }
    
    @Test("Given a book is checked out, when that check out fails, then a failed error is thrown",
          arguments: [
            .requestFailed,
            .unacceptableStatusCode(500),
            .decodingFailed
          ] as [NetworkServiceError<CheckOutErrorDTO>]
    )
    func failedCheckOut(networkError: NetworkServiceError<CheckOutErrorDTO>) async throws {
        let networkService = StubNetworkService()
        networkService.sendResponse = .failure(networkError)
        
        let sut = createSUT(networkService: networkService)
        
        await #expect(throws: CheckOutError.failed) {
            try await sut.checkOutBook("book-01")
        }
    }
    
    // MARK: - CheckInBook
    
    @Test("Given a book is checked in, when the request is made, then a POST request is sent to that book's checkin endpoint")
    func checkInRequest() async throws {
        let networkService = StubNetworkService()
        networkService.sendResponse = .success(BookDTO.testData())
        
        let sut = createSUT(networkService: networkService)
        
        _ = try await sut.checkInBook("book-01")
        
        var expectedRequest = URLRequest(url: URL(string: "https://library.example.com/books/book-01/checkin")!)
        expectedRequest.httpMethod = "POST"
        
        #expect(networkService.events == [.send(expectedRequest, 200..<300)])
    }
    
    @Test("Given a book is checked in, when that check in and mapping is successful, then a Listing is returned")
    func successfulCheckIn() async throws {
        let networkService = StubNetworkService()
        let bookDTO = BookDTO.testData(id: "book-01",
                                       availability: .available)
        networkService.sendResponse = .success(bookDTO)
        
        let sut = createSUT(networkService: networkService)
        
        let listing = try await sut.checkInBook("book-01")
        
        let expectedListing = Listing.testData(book: .testData(id: "book-01"),
                                               availability: .available)
        
        #expect(listing == expectedListing)
    }
    
    @Test("Given a book is checked in, when the server responds with a not borrowed failure, then a not borrowed error is thrown")
    func checkInFailureResponse() async throws {
        let networkService = StubNetworkService()
        networkService.sendResponse = .failure(NetworkServiceError.failureResponse(CheckInErrorDTO.testData(error: .notBorrowed)))
        
        let sut = createSUT(networkService: networkService)
        
        await #expect(throws: CheckInError.notBorrowed) {
            try await sut.checkInBook("book-01")
        }
    }
    
    @Test("Given a book is checked in, when that check in fails, then a failed error is thrown",
          arguments: [
            .requestFailed,
            .unacceptableStatusCode(500),
            .decodingFailed
          ] as [NetworkServiceError<CheckInErrorDTO>]
    )
    func failedCheckIn(networkError: NetworkServiceError<CheckInErrorDTO>) async throws {
        let networkService = StubNetworkService()
        networkService.sendResponse = .failure(networkError)
        
        let sut = createSUT(networkService: networkService)
        
        await #expect(throws: CheckInError.failed) {
            try await sut.checkInBook("book-01")
        }
    }
}

extension CatalogueRepositoryTests {
    func createSUT(baseURL: URL = URL(string: "https://library.example.com")!,
                   networkService: NetworkService = StubNetworkService()) -> DefaultCatalogueRepository {
        DefaultCatalogueRepository(baseURL: baseURL,
                                   networkService: networkService)
    }
}
