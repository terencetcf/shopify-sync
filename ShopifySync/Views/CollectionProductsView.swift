import SwiftUI

struct CollectionProductsView: View {
    @ObservedObject var viewModel: ShopifyViewModel
    let collection: Collection
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(collection.title)
                        .font(.headline)
                    Text("ID: \(collection.id)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(Color(.windowBackgroundColor))
            
            Divider()
            
            // Products
            if viewModel.isLoadingCollectionProducts {
                CollectionProductLoadingView()
            } else if viewModel.collectionProducts.isEmpty {
                ContentUnavailableView {
                    Label("No Products", systemImage: "tag.slash")
                } description: {
                    Text("This collection has no products")
                }
            } else {
                CollectionProductsTable(products: viewModel.collectionProducts)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            }
        }
        .onAppear {
            viewModel.fetchProductsForCollection(collection)
        }
    }
}

private struct CollectionProductLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .controlSize(.large)
            Text("Loading collection products...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
}

private struct CollectionProductsTable: View {
    let products: [Product]
    
    var body: some View {
        Table(products) {
            TableColumn("ID", value: \.id.description)
                .width(min: 80, ideal: 100)
            
            TableColumn("Title", value: \.title)
                .width(min: 200, ideal: 250)
            
            TableColumn("Vendor", value: \.vendor)
                .width(min: 100, ideal: 150)
            
            TableColumn("Type", value: \.productType)
                .width(min: 100, ideal: 150)
            
            TableColumn("Status", value: \.status)
                .width(min: 80, ideal: 100)
            
            TableColumn("Variants") { product in
                Text("\(product.variants.count)")
                    .foregroundStyle(.secondary)
            }
            .width(min: 80, ideal: 100)
            
            TableColumn("Last Updated") { product in
                Text(product.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    .foregroundStyle(.secondary)
            }
            .width(min: 180, ideal: 200)
        }
    }
} 