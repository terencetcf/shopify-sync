import SwiftUI

struct ProductsView: View {
    @ObservedObject var viewModel: ShopifyViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                ProductLoadingView()
            } else if viewModel.products.isEmpty {
                ProductEmptyStateView(viewModel: viewModel)
            } else {
                ProductsTable(products: viewModel.products)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            }
        }
    }
}

private struct ProductLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .controlSize(.large)
            Text("Loading products...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
}

private struct ProductEmptyStateView: View {
    @ObservedObject var viewModel: ShopifyViewModel
    
    var body: some View {
        ContentUnavailableView {
            Label {
                Text("No Products")
                    .fontWeight(.medium)
            } icon: {
                Image(systemName: "tag.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
                    .font(.system(size: 36))
            }
        } description: {
            Text("Connect to Shopify to view your products")
                .foregroundStyle(.secondary)
        } actions: {
            Button(action: viewModel.fetchProducts) {
                Label("Fetch Products", systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
}

private struct ProductsTable: View {
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