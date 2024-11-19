import Foundation

struct CollectionProducts: Codable {
    let products: [Product]
}

struct CollectProduct: Codable {
    let id: Int64
    let productId: Int64
    let collectionId: Int64
    
    enum CodingKeys: String, CodingKey {
        case id
        case productId = "product_id"
        case collectionId = "collection_id"
    }
}

struct CollectResponse: Codable {
    let collects: [CollectProduct]
} 