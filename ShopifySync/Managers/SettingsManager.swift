import Foundation

class SettingsManager {
    static let shared = SettingsManager()
    private let credentialsFileName = "shopify_credentials.json"
    
    private var credentialsFileURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(credentialsFileName)
    }
    
    private init() {
        // Create application support directory if it doesn't exist
        if let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    func saveCredentials(_ credentials: ShopifyCredentials) throws {
        guard let fileURL = credentialsFileURL else {
            throw NSError(domain: "SettingsManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not determine file URL"])
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(credentials)
        try data.write(to: fileURL)
    }
    
    func loadCredentials() -> ShopifyCredentials? {
        guard let fileURL = credentialsFileURL,
              let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        
        return try? JSONDecoder().decode(ShopifyCredentials.self, from: data)
    }
} 