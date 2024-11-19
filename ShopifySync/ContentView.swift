//
//  ContentView.swift
//  ShopifySync
//
//  Created by Terence Tai on 19/11/2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ShopifyViewModel()
    @State private var showingSettings = false
    @State private var selectedTab = Tab.collections
    @State private var selectedCollection: Collection?
    
    enum Tab {
        case collections, products
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Selector and Toolbar
            HStack {
                Picker("", selection: $selectedTab) {
                    Text("Collections").tag(Tab.collections)
                    Text("Products").tag(Tab.products)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: {
                        viewModel.connectToShopify()
                        if selectedTab == .products {
                            viewModel.fetchProducts()
                        }
                    }) {
                        Label(viewModel.isConnected ? "Refresh" : "Connect", 
                              systemImage: "arrow.triangle.2.circlepath")
                    }
                    .disabled(viewModel.isLoading)
                    
                    Button(action: {
                        if selectedTab == .collections {
                            viewModel.exportToCSV()
                        } else {
                            viewModel.exportProductsToCSV()
                        }
                    }) {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .disabled(!viewModel.isConnected || 
                             (selectedTab == .collections ? viewModel.collections.isEmpty : viewModel.products.isEmpty) || 
                             viewModel.isLoading)
                    
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                            .font(.title2)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.windowBackgroundColor))
            
            Divider()
            
            // Main Content
            if let selectedCollection = selectedCollection {
                // Show collection products view when a collection is selected
                CollectionProductsView(viewModel: viewModel, collection: selectedCollection)
                    .overlay(alignment: .topLeading) {
                        Button(action: { self.selectedCollection = nil }) {
                            Label("Back to Collections", systemImage: "chevron.left")
                                .labelStyle(.titleAndIcon)
                        }
                        .padding()
                    }
            } else {
                // Show main content based on selected tab
                Group {
                    switch selectedTab {
                    case .collections:
                        CollectionsView(viewModel: viewModel, selectedCollection: $selectedCollection)
                    case .products:
                        ProductsView(viewModel: viewModel)
                    }
                }
            }
            
            Divider()
            
            // Status Bar
            StatusBarView(viewModel: viewModel, selectedTab: selectedTab)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(viewModel: viewModel)
        }
    }
}

// MARK: - Collections View
private struct CollectionsView: View {
    @ObservedObject var viewModel: ShopifyViewModel
    @Binding var selectedCollection: Collection?
    @State private var showingProducts = false
    
    var body: some View {
        if viewModel.isLoading {
            LoadingView(selectedTab: .collections)
        } else if viewModel.collections.isEmpty {
            EmptyStateView(viewModel: viewModel, selectedTab: .collections)
        } else {
            Table(viewModel.collections) {
                TableColumn("Actions") { collection in
                    Button(action: {
                        let window = CollectionProductsWindow(collection: collection, viewModel: viewModel)
                        NSApp.windows.first(where: { $0 is CollectionProductsWindow })?.close()
                        window.makeKeyAndOrderFront(nil)
                    }) {
                        Label("See Products", systemImage: "tag.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .width(min: 120, ideal: 120)
                
                TableColumn("ID", value: \.id.description)
                    .width(min: 80, ideal: 100)
                
                TableColumn("Title", value: \.title)
                    .width(min: 250, ideal: 300)
                
                TableColumn("Handle", value: \.handle)
                    .width(min: 150, ideal: 200)
                
                TableColumn("Published Scope", value: \.publishedScope)
                    .width(min: 120, ideal: 150)
                
                TableColumn("Last Updated") { collection in
                    Text(collection.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        .foregroundStyle(.secondary)
                }
                .width(min: 180, ideal: 200)
                
                TableColumn("Image") { collection in
                    if let image = collection.image {
                        AsyncImage(url: URL(string: image.src)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 40, height: 40)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 40, height: 40)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            case .failure:
                                Image(systemName: "photo")
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 40, height: 40)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Image(systemName: "photo")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                            .frame(width: 40, height: 40)
                    }
                }
                .width(min: 60, ideal: 60)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .sheet(isPresented: $showingProducts) {
                if let collection = selectedCollection {
                    CollectionProductsView(viewModel: viewModel, collection: collection)
                        .frame(minWidth: 800, minHeight: 600)
                }
            }
        }
    }
}

// Add this new struct to handle table selection
private struct TableSelectionCoordinator: NSViewRepresentable {
    let collections: [Collection]
    @Binding var selectedCollection: Collection?
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let tableView = view.window?.contentView?.subviews.first(where: { $0 is NSTableView }) as? NSTableView {
                tableView.delegate = context.coordinator
                tableView.target = context.coordinator
                tableView.action = #selector(Coordinator.tableViewClicked(_:))
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.collections = collections
        context.coordinator.selectedCollection = $selectedCollection
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(collections: collections, selectedCollection: $selectedCollection)
    }
    
    class Coordinator: NSObject, NSTableViewDelegate {
        var collections: [Collection]
        var selectedCollection: Binding<Collection?>
        
        init(collections: [Collection], selectedCollection: Binding<Collection?>) {
            self.collections = collections
            self.selectedCollection = selectedCollection
        }
        
        @objc func tableViewClicked(_ sender: NSTableView) {
            let row = sender.clickedRow
            if row >= 0 && row < collections.count {
                selectedCollection.wrappedValue = collections[row]
            }
        }
    }
}

// MARK: - Loading View
private struct LoadingView: View {
    let selectedTab: ContentView.Tab
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .controlSize(.large)
            Text("Loading \(selectedTab == .collections ? "collections" : "products")...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
}

// MARK: - Empty State View
private struct EmptyStateView: View {
    @ObservedObject var viewModel: ShopifyViewModel
    let selectedTab: ContentView.Tab
    
    var body: some View {
        ContentUnavailableView {
            Label {
                Text(selectedTab == .collections ? "No Collections" : "No Products")
                    .fontWeight(.medium)
            } icon: {
                Image(systemName: selectedTab == .collections ? "tray.fill" : "tag.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
                    .font(.system(size: 36))
            }
        } description: {
            Text(selectedTab == .collections ? 
                 "Connect to Shopify to view your collections" : 
                 "Connect to Shopify to view your products")
                .foregroundStyle(.secondary)
        } actions: {
            Button(action: {
                if selectedTab == .collections {
                    viewModel.connectToShopify()
                } else {
                    viewModel.fetchProducts()
                }
            }) {
                Label(selectedTab == .collections ? "Connect to Shopify" : "Fetch Products", 
                      systemImage: selectedTab == .collections ? "link" : "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
}

// MARK: - Status Bar View
private struct StatusBarView: View {
    @ObservedObject var viewModel: ShopifyViewModel
    let selectedTab: ContentView.Tab
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(viewModel.isConnected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            Text(viewModel.isConnected ? "Connected to Shopify" : "Not Connected")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 16, height: 16)
                
                Text("Loading...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                switch selectedTab {
                case .collections:
                    if !viewModel.collections.isEmpty {
                        Text("\(viewModel.collections.count) collections")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                case .products:
                    if !viewModel.products.isEmpty {
                        Text("\(viewModel.products.count) products")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(Color(.windowBackgroundColor))
    }
}

// MARK: - Menu Commands
extension ContentView {
    @CommandsBuilder
    var commands: some Commands {
        CommandGroup(after: .newItem) {
            Button("Refresh Collections") {
                viewModel.fetchCollections()
            }
            .keyboardShortcut("R", modifiers: .command)
            
            Divider()
            
            Button("Export to CSV") {
                viewModel.exportToCSV()
            }
            .keyboardShortcut("E", modifiers: .command)
            .disabled(!viewModel.isConnected || viewModel.collections.isEmpty)
        }
    }
}

#Preview {
    ContentView()
}
