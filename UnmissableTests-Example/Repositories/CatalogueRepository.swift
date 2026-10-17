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
    func catalogue() async throws -> [CatalogueEntry]
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
        var entries: [CatalogueEntry]
        var loans: [Loan]
    }

    private let bundle: Bundle
    private let decoder: JSONDecoder

    // Changes are held in memory to stand in for the server, so they're lost when the app restarts.
    private var store: Store?

    init(bundle: Bundle) {
        self.bundle = bundle

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    // MARK: - Catalogue

    func catalogue() async throws -> [CatalogueEntry] {
        try loadedStore().entries
    }

    func availability(ofBookWithID bookID: String) async throws -> Availability {
        guard let entry = try loadedStore().entries.first(where: { $0.book.id == bookID }) else {
            throw CatalogueRepositoryError.unknownBook(bookID)
        }

        return entry.availability
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
                                               in: store.entries.map(\.book)),
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

    // MARK: - Store

    private func loadedStore() throws -> Store {
        if let store {
            return store
        }

        let bookResponses: [BookResponse] = try load("books")
        let loanResponses: [LoanResponse] = try load("loans")

        let entries = bookResponses.map(\.entry)
        let books = entries.map(\.book)

        let loans = try loanResponses.map { response in
            Loan(book: try book(withID: response.bookId,
                                in: books),
                 borrowedAt: response.borrowedAt,
                 dueDate: response.dueDate)
        }

        let store = Store(entries: entries,
                          loans: loans)
        self.store = store

        return store
    }

    private func setAvailability(_ availability: Availability,
                                 forBookWithID bookID: String,
                                 in store: inout Store) throws {
        guard let index = store.entries.firstIndex(where: { $0.book.id == bookID }) else {
            throw CatalogueRepositoryError.unknownBook(bookID)
        }

        store.entries[index] = CatalogueEntry(book: store.entries[index].book,
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

private struct BookResponse: Decodable {
    enum Status: String, Decodable {
        case available
        case onLoan = "on_loan"
        case onLoanToYou = "on_loan_to_you"
    }

    struct AuthorResponse: Decodable {
        let firstName: String
        let lastName: String
    }

    let id: String
    let title: String
    let author: AuthorResponse
    let isbn: String
    let coverImageName: String
    let availability: Status

    var entry: CatalogueEntry {
        CatalogueEntry(book: book,
                       availability: mappedAvailability)
    }

    private var book: Book {
        Book(id: id,
             title: title,
             author: Author(firstName: author.firstName,
                            lastName: author.lastName),
             isbn: isbn,
             coverImageName: coverImageName)
    }

    private var mappedAvailability: Availability {
        switch availability {
        case .available:
            .available
        case .onLoan:
            .onLoan
        case .onLoanToYou:
            .onLoanToYou
        }
    }
}

private struct LoanResponse: Decodable {
    let bookId: String
    let borrowedAt: Date
    let dueDate: Date
}
