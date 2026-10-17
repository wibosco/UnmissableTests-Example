//
//  UnmissableTests_ExampleApp.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 14/10/2026.
//

import SwiftUI

@main
struct UnmissableTests_ExampleApp: App {
    private let catalogueService: CatalogueService
    private let loanService: LoanService
    private let reservationService: ReservationService

    init() {
        let repository = DefaultCatalogueRepository(bundle: .main)

        catalogueService = CatalogueService(repository: repository)
        loanService = LoanService(repository: repository,
                                  loanLimit: 5,
                                  loanPeriodInDays: 21,
                                  calendar: .current,
                                  now: Date.init)
        reservationService = ReservationService(repository: repository)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(catalogueService: catalogueService,
                        loanService: loanService,
                        reservationService: reservationService)
        }
    }
}
