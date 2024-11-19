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
    
    enum Tab {
        case collections, products
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
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
            Group {
                switch selectedTab {
                case .collections:
                    MainContentView(viewModel: viewModel, selectedTab: selectedTab)
                case .products:
                    ProductsView(viewModel: viewModel)
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

// MARK: - Sidebar View
private struct SidebarView: View {
    let collections: [Collection]
    @Binding var selectedCollection: Collection?
    
    var body: some View {
        List(selection: $selectedCollection) {
            Section {
                Label("Collections", systemImage: "folder.fill")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }
            
            if !collections.isEmpty {
                Section {
                    ForEach(collections) { collection in
                        NavigationLink(value: collection) {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(collection.title)
                                        .fontWeight(.medium)
                                    Text("ID: \(collection.id)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: "tag.fill")
                                    .foregroundStyle(.blue)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } header: {
                    Text("All Collections")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Shopify Sync")
    }
}

// MARK: - Detail View
private struct DetailView: View {
    @ObservedObject var viewModel: ShopifyViewModel
    let selectedTab: ContentView.Tab
    
    var body: some View {
        VStack(spacing: 0) {
            ToolbarView(viewModel: viewModel)
            
            Divider()
            
            MainContentView(viewModel: viewModel, selectedTab: selectedTab)
            
            Divider()
            
            StatusBarView(viewModel: viewModel, selectedTab: selectedTab)
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: toggleSidebar) {
                    Image(systemName: "sidebar.left")
                }
            }
        }
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?
            .tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

// MARK: - Toolbar View
private struct ToolbarView: View {
    @ObservedObject var viewModel: ShopifyViewModel
    
    var body: some View {
        HStack {
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: viewModel.connectToShopify) {
                    Label(viewModel.isConnected ? "Refresh" : "Connect", 
                          systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(viewModel.isLoading)
                
                Button(action: viewModel.exportToCSV) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .disabled(!viewModel.isConnected || viewModel.collections.isEmpty || viewModel.isLoading)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
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

// MARK: - Main Content View
private struct MainContentView: View {
    @ObservedObject var viewModel: ShopifyViewModel
    let selectedTab: ContentView.Tab
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(selectedTab: selectedTab)
            } else if viewModel.collections.isEmpty {
                EmptyStateView(viewModel: viewModel, selectedTab: selectedTab)
            } else {
                CollectionsTable(collections: viewModel.collections)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
}

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

private struct CollectionsTable: View {
    let collections: [Collection]
    
    var body: some View {
        Table(collections) {
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
