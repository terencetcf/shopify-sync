import SwiftUI

class ShopifyViewModel: ObservableObject {
    @Published var collections: [Collection] = []
    @Published var isConnected: Bool = false
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    // In production, these should be stored securely (e.g., in Keychain)
    private let shopDomain = "the_domain.com"
    private let accessToken = "the_access_token"
    private let apiVersion = "2024-01"  // Changed to current stable version
    
    private var baseURL: String {
        "https://\(shopDomain)/admin/api/\(apiVersion)"
    }
    
    func connectToShopify() {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(baseURL)/shop.json") else {
            errorMessage = "Invalid shop URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        // Fixed: Correct header format for Shopify Admin API
        request.setValue(accessToken, forHTTPHeaderField: "X-Shopify-Access-Token")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("Attempting to connect to: \(url.absoluteString)") // Debug line
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Connection error: \(error.localizedDescription)"
                    print("Debug - Connection error: \(error)") // Debug line
                    self?.isConnected = false
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.errorMessage = "Invalid response"
                    self?.isConnected = false
                    return
                }
                
                print("Debug - Status code: \(httpResponse.statusCode)") // Debug line
                
                switch httpResponse.statusCode {
                case 200:
                    self?.isConnected = true
                    self?.fetchCollections()
                case 401:
                    self?.errorMessage = "Authentication failed. Please check your access token."
                    self?.isConnected = false
                case 402:
                    self?.errorMessage = "Payment required. Please check your Shopify plan."
                    self?.isConnected = false
                case 403:
                    self?.errorMessage = "Access forbidden. Please check your API permissions."
                    self?.isConnected = false
                case 404:
                    self?.errorMessage = "Shop not found. Please check your shop domain."
                    self?.isConnected = false
                default:
                    self?.errorMessage = "Unexpected error (Status \(httpResponse.statusCode))"
                    self?.isConnected = false
                }
            }
        }.resume()
    }
    
    func fetchCollections() {
        guard isConnected else {
            errorMessage = "Please connect to Shopify first"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(baseURL)/custom_collections.json") else {
            errorMessage = "Invalid API URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        // Fixed: Correct header format for Shopify Admin API
        request.setValue(accessToken, forHTTPHeaderField: "X-Shopify-Access-Token")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("Fetching collections from: \(url.absoluteString)") // Debug line
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Failed to fetch collections: \(error.localizedDescription)"
                    print("Debug - Fetch error: \(error)") // Debug line
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }
                
                // Debug: Print response data
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Debug - Response: \(responseString)")
                }
                
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    
                    let response = try decoder.decode(CollectionsResponse.self, from: data)

                    print("***Debug - Collections: \(response.customCollections)")

                    self?.collections = response.customCollections
                    
                    if response.customCollections.isEmpty {
                        self?.errorMessage = "No collections found"
                    }
                } catch {
                    self?.errorMessage = "Failed to parse collections: \(error.localizedDescription)"
                    print("Debug - JSON parsing error: \(error)")
                }
            }
        }.resume()
    }
    
    func exportToCSV() {
        let headers = ["ID", "Title", "Handle", "Published Scope", "Last Updated", "Image URL"]
        var csvString = headers.joined(separator: ",") + "\n"
        
        for collection in collections {
            let row = [
                String(collection.id),
                collection.title,
                collection.handle,
                collection.publishedScope,
                DateFormatter.localizedString(from: collection.updatedAt, dateStyle: .medium, timeStyle: .medium),
                collection.image?.src ?? ""
            ]
            csvString += row.joined(separator: ",") + "\n"
        }
        
        // Save CSV file
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.nameFieldStringValue = "shopify_collections.csv"
        
        savePanel.begin { result in
            if result == .OK, let url = savePanel.url {
                do {
                    try csvString.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    self.errorMessage = "Failed to save CSV: \(error.localizedDescription)"
                }
            }
        }
    }
} 
