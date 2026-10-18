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

final class DefaultCatalogueRepository: CatalogueRepository {
    private let baseURL: URL
    private let networkService: NetworkService

    // MARK: - Init

    init(baseURL: URL,
         networkService: NetworkService) {
        self.baseURL = baseURL
        self.networkService = networkService
    }

    // MARK: - Catalogue

    func catalogue() async throws(CatalogueError) -> [Listing] {
        let request = URLRequest(url: baseURL.appending(path: "books"))

        do {
            let bookDTOs = try await networkService.send(request,
                                                         acceptableStatusCodes: 200..<300,
                                                         success: [BookDTO].self,
                                                         failure: Never.self)

            return bookDTOs.map { listing(from: $0) }
        } catch {
            throw .failed
        }
    }

    // MARK: - Loans

    func loans() async throws(LoansError) -> [Loan] {
        let request = URLRequest(url: baseURL.appending(path: "loans"))

        do {
            let loanDTOs = try await networkService.send(request,
                                                         acceptableStatusCodes: 200..<300,
                                                         success: [LoanDTO].self,
                                                         failure: Never.self)

            return loanDTOs.map { loan(from: $0) }
        } catch {
            throw .failed
        }
    }

    func checkOut(bookID: String) async throws(CheckOutError) {
        var request = URLRequest(url: baseURL.appending(path: "books/\(bookID)/checkout"))
        request.httpMethod = "POST"

        do {
            _ = try await networkService.send(request,
                                              acceptableStatusCodes: 200..<300,
                                              success: EmptyResponse.self,
                                              failure: CheckOutErrorDTO.self)
        } catch {
            switch error {
            case .failureResponse(let errorDTO):
                switch errorDTO.error {
                case .alreadyBorrowed:
                    throw .alreadyBorrowed
                case .loanLimitReached:
                    throw .loanLimitReached
                case .bookUnavailable:
                    throw .bookUnavailable
                }
            case .requestFailed, .unacceptableStatusCode, .decodingFailed:
                throw .failed
            }
        }
    }

    func checkIn(bookID: String) async throws(CheckInError) {
        var request = URLRequest(url: baseURL.appending(path: "books/\(bookID)/checkin"))
        request.httpMethod = "POST"

        do {
            _ = try await networkService.send(request,
                                              acceptableStatusCodes: 200..<300,
                                              success: EmptyResponse.self,
                                              failure: CheckInErrorDTO.self)
        } catch {
            switch error {
            case .failureResponse(let errorDTO):
                switch errorDTO.error {
                case .notBorrowed:
                    throw .notBorrowed
                }
            case .requestFailed, .unacceptableStatusCode, .decodingFailed:
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
