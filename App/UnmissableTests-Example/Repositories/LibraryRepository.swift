//
//  LibraryRepository.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation

protocol LibraryRepository {
    func retrieveListings() async throws(RetrieveListingsRepositoryError) -> [Listing]
    func retrieveLoans() async throws(RetrieveLoansRepositoryError) -> [Loan]

    func createLoan(forBookID bookID: String) async throws(CreateLoanRepositoryError) -> Loan
    func deleteLoan(forBookID bookID: String) async throws(DeleteLoanRepositoryError) -> Listing
}

enum RetrieveListingsRepositoryError: Error, Equatable {
    case catalogueUnavailable
    case failed
}

enum RetrieveLoansRepositoryError: Error, Equatable {
    case membershipExpired
    case failed
}

enum CreateLoanRepositoryError: Error, Equatable {
    case loanLimitReached
    case bookUnavailable
    case failed
}

enum DeleteLoanRepositoryError: Error, Equatable {
    case notBorrowed
    case failed
}

final class DefaultLibraryRepository: LibraryRepository {
    private let baseURL: URL
    private let networkService: NetworkService

    // MARK: - Init

    init(baseURL: URL,
         networkService: NetworkService) {
        self.baseURL = baseURL
        self.networkService = networkService
    }

    // MARK: - Listings

    func retrieveListings() async throws(RetrieveListingsRepositoryError) -> [Listing] {
        let request = URLRequest(url: baseURL.appending(path: "books"))

        do {
            let bookListDTO = try await networkService.send(request,
                                                            success: BookListDTO.self,
                                                            failure: RetrieveListingsErrorDTO.self)

            return bookListDTO.books.map { listing(from: $0) }
        } catch {
            switch error {
            case .failureResponse(let errorDTO):
                switch errorDTO.error {
                case .catalogueUnavailable:
                    throw .catalogueUnavailable
                }
            case .requestFailed, .unacceptableStatusCode, .decodingFailed:
                throw .failed
            }
        }
    }

    // MARK: - Loans

    func retrieveLoans() async throws(RetrieveLoansRepositoryError) -> [Loan] {
        let request = URLRequest(url: baseURL.appending(path: "loans"))

        do {
            let loanListDTO = try await networkService.send(request,
                                                            success: LoanListDTO.self,
                                                            failure: RetrieveLoansErrorDTO.self)

            return loanListDTO.loans.map { loan(from: $0) }
        } catch {
            switch error {
            case .failureResponse(let errorDTO):
                switch errorDTO.error {
                case .membershipExpired:
                    throw .membershipExpired
                }
            case .requestFailed, .unacceptableStatusCode, .decodingFailed:
                throw .failed
            }
        }
    }

    func createLoan(forBookID bookID: String) async throws(CreateLoanRepositoryError) -> Loan {
        var request = URLRequest(url: baseURL.appending(path: "loans/\(bookID)"))
        request.httpMethod = "PUT"

        do {
            let loanDTO = try await networkService.send(request,
                                                        success: LoanDTO.self,
                                                        failure: CreateLoanErrorDTO.self)

            return loan(from: loanDTO)
        } catch {
            switch error {
            case .failureResponse(let errorDTO):
                switch errorDTO.error {
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

    func deleteLoan(forBookID bookID: String) async throws(DeleteLoanRepositoryError) -> Listing {
        var request = URLRequest(url: baseURL.appending(path: "loans/\(bookID)"))
        request.httpMethod = "DELETE"

        do {
            let bookDTO = try await networkService.send(request,
                                                        success: BookDTO.self,
                                                        failure: DeleteLoanErrorDTO.self)

            return listing(from: bookDTO)
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
             author: author(from: bookDTO.author),
             coverImageName: bookDTO.coverImageName)
    }

    private func author(from authorDTO: BookDTO.AuthorDTO) -> Author {
        Author(firstName: authorDTO.firstName,
               lastName: authorDTO.lastName)
    }

    private func availability(from availability: BookDTO.AvailabilityDTO) -> Availability {
        switch availability {
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
