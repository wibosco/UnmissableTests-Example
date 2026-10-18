//
//  ContentView.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 14/10/2026.
//

import MockServer
import SwiftUI

struct ContentView: View {
    let listingsViewModel: ListingsViewModel
    let loansViewModel: LoansViewModel

    var body: some View {
        TabView {
            Tab("Listings", systemImage: "books.vertical") {
                ListingsView(viewModel: listingsViewModel)
            }

            Tab("Loans", systemImage: "book") {
                LoansView(viewModel: loansViewModel)
            }
        }
    }
}

#Preview {
    let session = DefaultMockServer.session()
    let networkService = DefaultNetworkService(session: session)
    let repository = DefaultCatalogueRepository(baseURL: URL(string: "https://library.example.com")!,
                                                networkService: networkService)
    let loanService = DefaultLoanService(repository: repository,
                                  now: Date.init)

    ContentView(listingsViewModel: ListingsViewModel(listingService: DefaultListingService(repository: repository),
                                                       loanService: loanService),
                loansViewModel: LoansViewModel(loanService: loanService))
}
