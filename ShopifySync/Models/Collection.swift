import Foundation

struct Collection: Codable, Identifiable, Hashable {
    let id: Int64
    let title: String
    let handle: String
    let publishedScope: String
    let updatedAt: Date
    let image: CollectionImage?
    
    enum CodingKeys: String, CodingKey {
        case id, title, handle, image
        case publishedScope = "published_scope"
        case updatedAt = "updated_at"
    }
    
    // Add Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
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

struct CollectionsResponse: Codable {
    let customCollections: [Collection]
    
    enum CodingKeys: String, CodingKey {
        case customCollections = "custom_collections"
    }
} 
