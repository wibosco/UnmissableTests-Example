//
//  UnmissableTests_ExampleApp.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 14/10/2026.
//

import MockServer
import SwiftUI

@main
struct UnmissableTests_ExampleApp: App {
    @State private var catalogueViewModel: CatalogueViewModel
    @State private var loansViewModel: LoansViewModel

    init() {
        let session = DefaultMockServer.session()
        let networkService = DefaultNetworkService(session: session)
        let repository = DefaultCatalogueRepository(baseURL: URL(string: "https://library.example.com")!,
                                                    networkService: networkService)
        let catalogueService = CatalogueService(repository: repository)
        let loanService = LoanService(repository: repository,
                                      now: Date.init)

        _catalogueViewModel = State(initialValue: CatalogueViewModel(catalogueService: catalogueService,
                                                                     loanService: loanService))
        _loansViewModel = State(initialValue: LoansViewModel(loanService: loanService))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(catalogueViewModel: catalogueViewModel,
                        loansViewModel: loansViewModel)
        }
    }
}
