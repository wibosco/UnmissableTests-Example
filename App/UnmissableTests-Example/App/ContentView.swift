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
    
    // MARK: - Views
    
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
    let dependencies = AppDependencies()

    ContentView(catalogueViewModel: dependencies.catalogueViewModel,
                loansViewModel: dependencies.loansViewModel)
}
