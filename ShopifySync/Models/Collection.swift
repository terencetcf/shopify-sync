import Foundation

struct Collection: Identifiable, Codable, Hashable {
    let id: Int
    let handle: String
    let title: String
    let updatedAt: Date
    let bodyHtml: String?
    let publishedAt: Date
    let sortOrder: String
    let templateSuffix: String?
    let publishedScope: String
    let adminGraphqlApiId: String
    let image: CollectionImage?
    
    // For decoding from Shopify API
    enum CodingKeys: String, CodingKey {
        case id
        case handle
        case title
        case updatedAt = "updated_at"
        case bodyHtml = "body_html"
        case publishedAt = "published_at"
        case sortOrder = "sort_order"
        case templateSuffix = "template_suffix"
        case publishedScope = "published_scope"
        case adminGraphqlApiId = "admin_graphql_api_id"
        case image
    }
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Implement Equatable (required by Hashable)
    static func == (lhs: Collection, rhs: Collection) -> Bool {
        lhs.id == rhs.id
    }
}

struct CollectionImage: Codable, Hashable {
    let createdAt: Date
    let alt: String?
    let width: Int
    let height: Int
    let src: String
    
    enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case alt
        case width
        case height
        case src
    }
}

// Shopify API response structure
struct CollectionsResponse: Codable {
    let customCollections: [Collection]
    
    enum CodingKeys: String, CodingKey {
        case customCollections = "custom_collections"
    }
} 
