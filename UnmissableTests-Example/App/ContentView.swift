//
//  ContentView.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 14/10/2026.
//

import SwiftUI

struct ContentView: View {
    let catalogueViewModel: CatalogueViewModel
    let loansViewModel: LoansViewModel

    var body: some View {
        TabView {
            Tab("Catalogue", systemImage: "books.vertical") {
                CatalogueView(viewModel: catalogueViewModel)
            }

            Tab("Loans", systemImage: "book") {
                LoansView(viewModel: loansViewModel)
            }
        }
    }
}

#Preview {
    let session = MockServer.session(bundle: .main,
                                         loanLimit: 5,
                                         loanPeriodInDays: 21,
                                         calendar: .current,
                                         now: { Date() })
    let networkService = DefaultNetworkService(session: session)
    let repository = DefaultCatalogueRepository(baseURL: URL(string: "https://library.example.com")!,
                                                networkService: networkService)
    let loanService = LoanService(repository: repository,
                                  now: Date.init)

    ContentView(catalogueViewModel: CatalogueViewModel(catalogueService: CatalogueService(repository: repository),
                                                       loanService: loanService),
                loansViewModel: LoansViewModel(loanService: loanService))
}
