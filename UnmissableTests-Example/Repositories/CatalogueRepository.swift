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
    case reserved
}

@MainActor
protocol CatalogueRepository {
    func catalogue() async throws -> [CatalogueEntry]
    func availability(ofBookWithID bookID: String) async throws -> Availability
    func loans() async throws -> [Loan]
    func reservations() async throws -> [Reservation]
    func checkOut(bookID: String) async throws
    func checkIn(bookID: String) async throws
}

enum CatalogueRepositoryError: Error, Equatable {
    case missingResource(String)
    case unknownBook(String)
}

@MainActor
final class DefaultCatalogueRepository: CatalogueRepository {
    private let bundle: Bundle
    private let decoder: JSONDecoder

    init(bundle: Bundle) {
        self.bundle = bundle

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    // MARK: - Catalogue

    func catalogue() async throws -> [CatalogueEntry] {
        try bookResponses().map(\.entry)
    }

    func availability(ofBookWithID bookID: String) async throws -> Availability {
        guard let response = try bookResponses().first(where: { $0.id == bookID }) else {
            throw CatalogueRepositoryError.unknownBook(bookID)
        }

        return response.entry.availability
    }

    private func bookResponses() throws -> [BookResponse] {
        try load("books")
    }

    private func book(withID bookID: String,
                      in books: [Book]) throws -> Book {
        guard let book = books.first(where: { $0.id == bookID }) else {
            throw CatalogueRepositoryError.unknownBook(bookID)
        }

        return book
    }

    // MARK: - Loans

    func loans() async throws -> [Loan] {
        let books = try bookResponses().map(\.book)
        let responses: [LoanResponse] = try load("loans")

        return try responses.map { response in
            Loan(book: try book(withID: response.bookId,
                                in: books),
                 borrowedAt: response.borrowedAt,
                 dueDate: response.dueDate)
        }
    }

    // MARK: - Reservations

    func reservations() async throws -> [Reservation] {
        let books = try bookResponses().map(\.book)
        let responses: [ReservationResponse] = try load("reservations")

        return try responses.map { response in
            Reservation(book: try book(withID: response.bookId,
                                       in: books),
                        reservedAt: response.reservedAt)
        }
    }

    // MARK: - Lending

    // The bundled responses are read-only, so there is nothing for a checkout or check-in to change.
    func checkOut(bookID: String) async throws {}

    func checkIn(bookID: String) async throws {}

    // MARK: - Loading

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
        case reserved
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

    var book: Book {
        Book(id: id,
             title: title,
             author: Author(firstName: author.firstName,
                            lastName: author.lastName),
             isbn: isbn,
             coverImageName: coverImageName)
    }

    var entry: CatalogueEntry {
        CatalogueEntry(book: book,
                       availability: mappedAvailability)
    }

    private var mappedAvailability: Availability {
        switch availability {
        case .available:
            .available
        case .onLoan:
            .onLoan
        case .reserved:
            .reserved
        }
    }
}

private struct LoanResponse: Decodable {
    let bookId: String
    let borrowedAt: Date
    let dueDate: Date
}

private struct ReservationResponse: Decodable {
    let bookId: String
    let reservedAt: Date
}
