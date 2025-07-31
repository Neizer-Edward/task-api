import FluentKit
import Foundation
import Hummingbird

final class Product: Model, ResponseCodable, @unchecked Sendable {
    static let schema = "products"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "price")
    var price: Double

    @Field(key: "quantity")
    var quantity: Int

    @Parent(key: "shop_id")
    var shop: Shop

    init() {}

    init(id: UUID? = nil, name: String, price: Double, quantity: Int, shopID: UUID) {
        self.id = id
        self.name = name
        self.price = price
        self.quantity = quantity
        self.$shop.id = shopID
    }
}
