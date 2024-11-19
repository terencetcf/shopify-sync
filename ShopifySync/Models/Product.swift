import Foundation

struct Product: Codable, Identifiable {
    let id: Int64
    let title: String
    let handle: String
    let vendor: String
    let productType: String
    let status: String
    let publishedAt: Date?
    let updatedAt: Date
    let variants: [ProductVariant]
    let images: [ProductImage]
    
    enum CodingKeys: String, CodingKey {
        case id, title, handle, vendor, status
        case productType = "product_type"
        case publishedAt = "published_at"
        case updatedAt = "updated_at"
        case variants, images
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int64.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        handle = try container.decode(String.self, forKey: .handle)
        vendor = try container.decode(String.self, forKey: .vendor)
        productType = try container.decode(String.self, forKey: .productType)
        status = try container.decode(String.self, forKey: .status)
        publishedAt = try container.decodeIfPresent(Date.self, forKey: .publishedAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        variants = try container.decode([ProductVariant].self, forKey: .variants)
        images = try container.decode([ProductImage].self, forKey: .images)
    }
}

struct ProductVariant: Codable, Identifiable {
    let id: Int64
    let title: String
    let price: String
    let sku: String?
    let position: Int
    let inventoryQuantity: Int
    
    enum CodingKeys: String, CodingKey {
        case id, title, price, sku, position
        case inventoryQuantity = "inventory_quantity"
    }
}

struct ProductImage: Codable {
    let id: Int64
    let src: String
    let width: Int
    let height: Int
    let alt: String?
}

struct ProductsResponse: Codable {
    let products: [Product]
} 