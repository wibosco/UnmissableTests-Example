//
//  ListingServiceTests.swift
//  UnmissableTests-ExampleTests
//
//  Created by William Boles on 18/10/2026.
//

import Foundation
import Testing

@testable import UnmissableTests_Example

struct ListingServiceTests {

    // MARK: - Listings

    @Test("Given listings are retrieved, when the retrieval is made, then the repository is asked for listings")
    func listingsRetrievalRequest() async throws {
        let repository = StubLibraryRepository()
        repository.retrieveListingsResponse = .success([])

        let sut = createSUT(repository: repository)

        _ = try await sut.listings()

        #expect(repository.events == [.retrieveListings])
    }

    @Test("Given listings are retrieved, when that retrieval is successful, then the repository's listings are returned")
    func successfulListingsRetrieval() async throws {
        let repository = StubLibraryRepository()
        let repositoryListings: [Listing] = [.testData(book: .testData(id: "book-01"),
                                                       availability: .available),
                                             .testData(book: .testData(id: "book-02"),
                                                       availability: .onLoan),
                                             .testData(book: .testData(id: "book-03"),
                                                       availability: .onLoanToYou)]
        repository.retrieveListingsResponse = .success(repositoryListings)

        let sut = createSUT(repository: repository)

        let listings = try await sut.listings()

        #expect(listings == repositoryListings)
    }

    @Test("Given listings are retrieved, when that retrieval fails, then the matching error is thrown",
          arguments: zip(
            [
              .catalogueUnavailable,
              .failed
            ] as [RetrieveListingsRepositoryError],
            [
              .catalogueUnavailable,
              .failed
            ] as [ListingsServiceError]
          )
    )
    func failedListingsRetrieval(repositoryError: RetrieveListingsRepositoryError,
                                 expectedError: ListingsServiceError) async throws {
        let repository = StubLibraryRepository()
        repository.retrieveListingsResponse = .failure(repositoryError)

        let sut = createSUT(repository: repository)

        await #expect(throws: expectedError) {
            try await sut.listings()
        }
    }

    @Test("Given listings have already been retrieved, when they are retrieved again, then the repository isn't asked again")
    func cachedListingsRetrieval() async throws {
        let repository = StubLibraryRepository()
        repository.retrieveListingsResponse = .success([.testData()])

        let sut = createSUT(repository: repository)

        _ = try await sut.listings()
        _ = try await sut.listings()

        #expect(repository.events == [.retrieveListings])
    }

    @Test("Given a listings retrieval has failed, when listings are retrieved again, then the repository is asked again")
    func failedListingsRetrievalIsNotCached() async throws {
        let repository = StubLibraryRepository()
        repository.retrieveListingsResponse = .failure(.failed)

        let sut = createSUT(repository: repository)

        _ = try? await sut.listings()

        repository.retrieveListingsResponse = .success([.testData()])

        _ = try await sut.listings()

        #expect(repository.events == [.retrieveListings, .retrieveListings])
    }
}

extension ListingServiceTests {
    func createSUT(repository: LibraryRepository = StubLibraryRepository()) -> DefaultListingService {
        DefaultListingService(repository: repository)
    }
}
