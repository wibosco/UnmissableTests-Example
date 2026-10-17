//
//  ContentView.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 14/10/2026.
//

import SwiftUI

struct ContentView: View {
    let catalogueService: CatalogueService
    let loanService: LoanService

    var body: some View {
        TabView {
            Tab("All Books", systemImage: "books.vertical") {
                CatalogueView(catalogueService: catalogueService,
                              loanService: loanService)
            }

            Tab("Borrowed", systemImage: "book") {
                LoansView(loanService: loanService)
            }
        }
    }
}

#Preview {
    let repository = DefaultCatalogueRepository(bundle: .main)

    ContentView(catalogueService: CatalogueService(repository: repository),
                loanService: LoanService(repository: repository,
                                         loanLimit: 5,
                                         loanPeriodInDays: 21,
                                         calendar: .current,
                                         now: Date.init))
}
