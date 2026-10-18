//
//  AppDependencies.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 18/10/2026.
//

import Foundation
import MockServer

struct AppDependencies {
    let catalogueViewModel: CatalogueViewModel
    let loansViewModel: LoansViewModel

    // MARK: - Init

    init() {
        let session = MockLibraryServer.session()
        let networkService = DefaultNetworkService(session: session)
        let repository = DefaultLibraryRepository(baseURL: URL(string: "https://library.example.com")!,
                                                  networkService: networkService)
        let listingService = DefaultListingService(repository: repository)
        let loanService = DefaultLoanService(repository: repository,
                                             now: Date.init)

        catalogueViewModel = CatalogueViewModel(listingService: listingService,
                                                loanService: loanService)
        loansViewModel = LoansViewModel(loanService: loanService)
    }
}
