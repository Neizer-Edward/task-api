import FluentKit
import Foundation
import Hummingbird

final class Sale: Model,ResponseCodable, @unchecked Sendable {
    static let schema = "sales"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Parent(key: "shop_id")
    var shop: Shop

    @Field(key: "total_amount")
    var totalAmount: Double

    @Field(key: "created_at")
    var createdAt: Date

    init() {}

    init(id: UUID? = nil, userID: UUID, shopID: UUID, totalAmount: Double, createdAt: Date = Date()) {
        self.id = id
        self.$user.id = userID
        self.$shop.id = shopID
        self.totalAmount = totalAmount
        self.createdAt = createdAt
    }
}
