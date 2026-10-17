//
//  CatalogueView.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import SwiftUI

struct CatalogueView: View {
    let catalogueService: CatalogueService
    let loanService: LoanService

    var body: some View {
        BookListView(title: "Catalogue",
                     loadItems: catalogueService.catalogue,
                     book: \.book,
                     actions: actions(for:)) { entry in
            switch entry.availability {
            case .available:
                Text("Available")
                    .foregroundStyle(.green)
            case .onLoan:
                Text("On loan")
                    .foregroundStyle(.orange)
            case .onLoanToYou:
                Text("On loan to you")
                    .foregroundStyle(.purple)
            }
        }
    }

    private func actions(for entry: CatalogueEntry) -> [BookAction] {
        switch entry.availability {
        case .available:
            [.borrow(entry.book, using: loanService)]
        case .onLoan:
            []
        case .onLoanToYou:
            [.return(entry.book, using: loanService)]
        }
    }
}

#Preview {
    let repository = DefaultCatalogueRepository(bundle: .main)

    CatalogueView(catalogueService: CatalogueService(repository: repository),
                  loanService: LoanService(repository: repository,
                                           loanLimit: 5,
                                           loanPeriodInDays: 21,
                                           calendar: .current,
                                           now: Date.init))
}
