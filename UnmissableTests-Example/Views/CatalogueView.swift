//
//  CatalogueView.swift
//  UnmissableTests-Example
//
//  Created by William Boles on 17/10/2026.
//

import SwiftUI

struct CatalogueView: View {
    let catalogueService: CatalogueService

    var body: some View {
        BookListView(title: "All Books",
                     loadItems: catalogueService.catalogue,
                     book: \.book) { entry in
            switch entry.availability {
            case .available:
                Text("Available")
                    .foregroundStyle(.green)
            case .onLoan:
                Text("On loan")
                    .foregroundStyle(.orange)
            case .reserved:
                Text("Reserved")
                    .foregroundStyle(.blue)
            }
        }
    }
}

#Preview {
    CatalogueView(catalogueService: CatalogueService(repository: DefaultCatalogueRepository(bundle: .main)))
}
