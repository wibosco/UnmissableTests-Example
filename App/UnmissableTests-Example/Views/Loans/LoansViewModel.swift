//
//  LoansViewModel.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import Foundation
import Observation

@Observable
final class LoansViewModel {
    struct Row: Identifiable, Equatable {
        let id: String
        let title: String
        let authorName: String
        let coverImageName: String
        let dueDate: Date
        let isOverdue: Bool
    }

    enum State: Equatable {
        case loading
        case loaded([Row])
        case failed

        var rows: [Row] {
            guard case .loaded(let rows) = self else {
                return []
            }

            return rows
        }
    }

    enum Alert: Equatable {
        case returnFailed
    }

    private(set) var state = State.loading
    private(set) var alert: Alert?

    private let loanService: LoanService
    
    @ObservationIgnored private var loans = [Loan]()

    var isShowingAlert: Bool {
        get {
            alert != nil
        }
        set {
            if !newValue {
                alert = nil
            }
        }
    }
    
    // MARK: - Init

    init(loanService: LoanService) {
        self.loanService = loanService
    }

    // MARK: - Loading

    func load() async {
        do {
            loans = try await loanService.loans()
        } catch {
            state = .failed
            return
        }

        state = .loaded(loans
            .sorted(using: [
                SortDescriptor(\Loan.dueDate),
                SortDescriptor(\Loan.book.author.lastName),
                SortDescriptor(\Loan.book.author.firstName),
                SortDescriptor(\Loan.book.title)
            ])
            .map { row(for: $0) })
    }

    private func row(for loan: Loan) -> Row {
        Row(id: loan.book.id,
            title: loan.book.title,
            authorName: loan.book.author.lastNameFirst,
            coverImageName: loan.book.coverImageName,
            dueDate: loan.dueDate,
            isOverdue: loanService.isOverdue(loan))
    }

    // MARK: - Returning

    func returnBook(_ row: Row) async {
        guard let book = loadedBook(for: row) else {
            return
        }

        do {
            try await loanService.returnBook(book)
            await load()
        } catch {
            alert = .returnFailed
        }
    }

    private func loadedBook(for row: Row) -> Book? {
        loans.first(where: { $0.book.id == row.id })?.book
    }
}

private extension Author {
    var lastNameFirst: String {
        "\(lastName), \(firstName)"
    }
}
