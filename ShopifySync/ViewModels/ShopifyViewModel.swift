import SwiftUI

class ShopifyViewModel: ObservableObject {
    @Published var collections: [Collection] = []
    @Published var products: [Product] = []
    @Published var isConnected: Bool = false
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var isLoadingCollectionProducts: Bool = false
    @Published var credentials: ShopifyCredentials
    @Published var selectedCollection: Collection?
    @Published var collectionProducts: [Product] = []
    
    private let apiVersion = "2024-01"
    
    init() {
        self.credentials = SettingsManager.shared.loadCredentials() ?? 
            ShopifyCredentials(shopDomain: "", accessToken: "")
    }
    
    private var baseURL: String {
        "https://\(credentials.shopDomain)/admin/api/\(apiVersion)"
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
        request.setValue(credentials.accessToken, forHTTPHeaderField: "X-Shopify-Access-Token")
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
        request.setValue(credentials.accessToken, forHTTPHeaderField: "X-Shopify-Access-Token")
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
    
    func fetchProducts() {
        guard isConnected else {
            errorMessage = "Please connect to Shopify first"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(baseURL)/products.json") else {
            errorMessage = "Invalid API URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue(credentials.accessToken, forHTTPHeaderField: "X-Shopify-Access-Token")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Failed to fetch products: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    
                    let response = try decoder.decode(ProductsResponse.self, from: data)
                    self?.products = response.products
                    
                    if response.products.isEmpty {
                        self?.errorMessage = "No products found"
                    }
                } catch {
                    self?.errorMessage = "Failed to parse products: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    func exportProductsToCSV() {
        let headers = ["ID", "Title", "Handle", "Vendor", "Type", "Status", "Published At", "Variants", "Price Range"]
        var csvString = headers.joined(separator: ",") + "\n"
        
        for product in products {
            let priceRange = getPriceRange(from: product.variants)
            let publishedAtString = product.publishedAt.map { DateFormatter.localizedString(from: $0, dateStyle: .medium, timeStyle: .medium) } ?? "Not published"
            
            let row = [
                String(product.id),
                product.title,
                product.handle,
                product.vendor,
                product.productType,
                product.status,
                publishedAtString,
                String(product.variants.count),
                priceRange
            ]
            csvString += row.joined(separator: ",") + "\n"
        }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.nameFieldStringValue = "shopify_products.csv"
        
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
    
    private func getPriceRange(from variants: [ProductVariant]) -> String {
        let prices = variants.compactMap { Double($0.price) }
        guard let min = prices.min(), let max = prices.max() else { return "N/A" }
        return min == max ? "$\(min)" : "$\(min) - $\(max)"
    }
    
    func fetchProductsForCollection(_ collection: Collection) {
        guard isConnected else {
            errorMessage = "Please connect to Shopify first"
            return
        }
        
        isLoadingCollectionProducts = true
        errorMessage = nil
        selectedCollection = collection
        
        // First, get the collects (product-collection relationships)
        guard let url = URL(string: "\(baseURL)/collects.json?collection_id=\(collection.id)") else {
            errorMessage = "Invalid API URL"
            isLoadingCollectionProducts = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue(credentials.accessToken, forHTTPHeaderField: "X-Shopify-Access-Token")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = "Failed to fetch collection products: \(error.localizedDescription)"
                    self?.isLoadingCollectionProducts = false
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self?.errorMessage = "No data received"
                    self?.isLoadingCollectionProducts = false
                }
                return
            }
            
            do {
                let collectResponse = try JSONDecoder().decode(CollectResponse.self, from: data)
                let productIds = collectResponse.collects.map { String($0.productId) }
                
                if productIds.isEmpty {
                    DispatchQueue.main.async {
                        self?.collectionProducts = []
                        self?.isLoadingCollectionProducts = false
                    }
                    return
                }
                
                // Now fetch the actual products using the product IDs
                self?.fetchProductsByIds(productIds)
                
            } catch {
                DispatchQueue.main.async {
                    self?.errorMessage = "Failed to parse collection products: \(error.localizedDescription)"
                    self?.isLoadingCollectionProducts = false
                }
            }
        }.resume()
    }
    
    private func fetchProductsByIds(_ productIds: [String]) {
        let idsString = productIds.joined(separator: ",")
        guard let url = URL(string: "\(baseURL)/products.json?ids=\(idsString)") else {
            errorMessage = "Invalid API URL"
            isLoadingCollectionProducts = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue(credentials.accessToken, forHTTPHeaderField: "X-Shopify-Access-Token")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoadingCollectionProducts = false
                
                if let error = error {
                    self?.errorMessage = "Failed to fetch products: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let response = try decoder.decode(ProductsResponse.self, from: data)
                    self?.collectionProducts = response.products
                } catch {
                    self?.errorMessage = "Failed to parse products: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

// Create a KeychainManager class to handle secure storage
class KeychainManager {
    static let shared = KeychainManager()
    
    private init() {}
    
    func setValue(_ value: String, for key: String) -> Bool {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func getValue(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            if let data = dataTypeRef as? Data {
                return String(data: data, encoding: .utf8)
            }
        }
        return nil
    }
} 
