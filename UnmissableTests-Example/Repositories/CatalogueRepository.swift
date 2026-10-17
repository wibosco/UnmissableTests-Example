//
//  CatalogueRepository.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation

enum Availability: Equatable, Sendable {
    case available
    case onLoan
    case onLoanToYou
}

@MainActor
protocol CatalogueRepository {
    func catalogue() async throws -> [Listing]
    func availability(ofBookWithID bookID: String) async throws -> Availability
    func loans() async throws -> [Loan]
    func checkOut(bookID: String,
                  borrowedAt: Date,
                  dueDate: Date) async throws
    func checkIn(bookID: String) async throws
}

enum CatalogueRepositoryError: Error, Equatable {
    case missingResource(String)
    case unknownBook(String)
}

@MainActor
final class DefaultCatalogueRepository: CatalogueRepository {
    private struct Store {
        var listings: [Listing]
        var loans: [Loan]
    }

    private let bundle: Bundle
    private let decoder: JSONDecoder

    // Changes are held in memory to stand in for the server, so they're lost when the app restarts.
    private var store: Store?
    
    // MARK: - Init
    
    init(bundle: Bundle) {
        self.bundle = bundle

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    // MARK: - Catalogue

    func catalogue() async throws -> [Listing] {
        try loadedStore().listings
    }

    func availability(ofBookWithID bookID: String) async throws -> Availability {
        guard let listing = try loadedStore().listings.first(where: { $0.book.id == bookID }) else {
            throw CatalogueRepositoryError.unknownBook(bookID)
        }

        return listing.availability
    }

    // MARK: - Loans

    func loans() async throws -> [Loan] {
        try loadedStore().loans
    }

    func checkOut(bookID: String,
                  borrowedAt: Date,
                  dueDate: Date) async throws {
        var store = try loadedStore()

        try setAvailability(.onLoanToYou,
                            forBookWithID: bookID,
                            in: &store)
        store.loans.append(Loan(book: try book(withID: bookID,
                                               in: store.listings.map(\.book)),
                                borrowedAt: borrowedAt,
                                dueDate: dueDate))

        self.store = store
    }

    func checkIn(bookID: String) async throws {
        var store = try loadedStore()

        try setAvailability(.available,
                            forBookWithID: bookID,
                            in: &store)
        store.loans.removeAll { $0.book.id == bookID }

        self.store = store
    }
}

/// Standin for actual network requests
private extension DefaultCatalogueRepository {
    // MARK: - Store

    private func loadedStore() throws -> Store {
        if let store {
            return store
        }

        let bookDTOs: [BookDTO] = try load("books")
        let loanDTOs: [LoanDTO] = try load("loans")

        let listings = bookDTOs.map(\.listing)
        let books = listings.map(\.book)

        let loans = try loanDTOs.map { response in
            Loan(book: try book(withID: response.bookId,
                                in: books),
                 borrowedAt: response.borrowedAt,
                 dueDate: response.dueDate)
        }

        let store = Store(listings: listings,
                          loans: loans)
        self.store = store

        return store
    }

    private func setAvailability(_ availability: Availability,
                                 forBookWithID bookID: String,
                                 in store: inout Store) throws {
        guard let index = store.listings.firstIndex(where: { $0.book.id == bookID }) else {
            throw CatalogueRepositoryError.unknownBook(bookID)
        }

        store.listings[index] = Listing(book: store.listings[index].book,
                                        availability: availability)
    }

    private func book(withID bookID: String,
                      in books: [Book]) throws -> Book {
        guard let book = books.first(where: { $0.id == bookID }) else {
            throw CatalogueRepositoryError.unknownBook(bookID)
        }

        return book
    }

    private func load<T: Decodable>(_ name: String) throws -> T {
        guard let url = bundle.url(forResource: name,
                                   withExtension: "json") else {
            throw CatalogueRepositoryError.missingResource(name)
        }

        let data = try Data(contentsOf: url)

        return try decoder.decode(T.self,
                                  from: data)
    }
}
