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
    func catalogue() async throws(CatalogueError) -> [Listing]
    func loans() async throws(LoansError) -> [Loan]

    func checkOut(bookID: String) async throws(CheckOutError)
    func checkIn(bookID: String) async throws(CheckInError)
}

enum CatalogueError: Error, Equatable {
    case failed
}

enum LoansError: Error, Equatable {
    case failed
}

enum CheckOutError: Error, Equatable {
    case alreadyBorrowed
    case loanLimitReached
    case bookUnavailable
    case failed
}

enum CheckInError: Error, Equatable {
    case notBorrowed
    case failed
}

@MainActor
final class DefaultCatalogueRepository: CatalogueRepository {
    private let baseURL: URL
    private let networkService: NetworkService
    private let decoder: JSONDecoder

    // MARK: - Init

    init(baseURL: URL,
         networkService: NetworkService) {
        self.baseURL = baseURL
        self.networkService = networkService

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    // MARK: - Catalogue

    func catalogue() async throws(CatalogueError) -> [Listing] {
        let request = URLRequest(url: baseURL.appending(path: "books"))

        guard let result = try? await networkService.data(for: request) else {
            throw .failed
        }

        let (data, response) = result

        guard (200..<300).contains(response.statusCode),
              let bookDTOs = try? decoder.decode([BookDTO].self,
                                                 from: data) else {
            throw .failed
        }

        return bookDTOs.map { listing(from: $0) }
    }

    // MARK: - Loans

    func loans() async throws(LoansError) -> [Loan] {
        let request = URLRequest(url: baseURL.appending(path: "loans"))

        guard let result = try? await networkService.data(for: request) else {
            throw .failed
        }

        let (data, response) = result

        guard (200..<300).contains(response.statusCode),
              let loanDTOs = try? decoder.decode([LoanDTO].self,
                                                 from: data) else {
            throw .failed
        }

        return loanDTOs.map { loan(from: $0) }
    }

    func checkOut(bookID: String) async throws(CheckOutError) {
        var request = URLRequest(url: baseURL.appending(path: "books/\(bookID)/checkout"))
        request.httpMethod = "POST"

        guard let result = try? await networkService.data(for: request) else {
            throw .failed
        }

        let (data, response) = result

        guard (200..<300).contains(response.statusCode) else {
            let errorDTO = try? decoder.decode(ErrorDTO.self,
                                               from: data)

            switch errorDTO?.error {
            case .alreadyBorrowed:
                throw .alreadyBorrowed
            case .loanLimitReached:
                throw .loanLimitReached
            case .bookUnavailable:
                throw .bookUnavailable
            case .notBorrowed, nil:
                throw .failed
            }
        }
    }

    func checkIn(bookID: String) async throws(CheckInError) {
        var request = URLRequest(url: baseURL.appending(path: "books/\(bookID)/checkin"))
        request.httpMethod = "POST"

        guard let result = try? await networkService.data(for: request) else {
            throw .failed
        }

        let (data, response) = result

        guard (200..<300).contains(response.statusCode) else {
            let errorDTO = try? decoder.decode(ErrorDTO.self,
                                               from: data)

            switch errorDTO?.error {
            case .notBorrowed:
                throw .notBorrowed
            case .alreadyBorrowed, .loanLimitReached, .bookUnavailable, nil:
                throw .failed
            }
        }
    }

    // MARK: - Mapping

    private func listing(from bookDTO: BookDTO) -> Listing {
        Listing(book: book(from: bookDTO),
                availability: availability(from: bookDTO.availability))
    }

    private func book(from bookDTO: BookDTO) -> Book {
        Book(id: bookDTO.id,
             title: bookDTO.title,
             author: Author(firstName: bookDTO.author.firstName,
                            lastName: bookDTO.author.lastName),
             coverImageName: bookDTO.coverImageName)
    }

    private func availability(from status: BookDTO.Status) -> Availability {
        switch status {
        case .available:
            .available
        case .onLoan:
            .onLoan
        case .onLoanToYou:
            .onLoanToYou
        }
    }

    private func loan(from loanDTO: LoanDTO) -> Loan {
        Loan(book: book(from: loanDTO.book),
             dueDate: loanDTO.dueDate)
    }
}
