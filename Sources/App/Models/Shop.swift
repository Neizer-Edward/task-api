import FluentKit
import Foundation
import Hummingbird

final class Shop: @unchecked Sendable, Model, ResponseCodable {
    static let schema = "shops"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Children(for: \.$shop)
    var users: [User]

    @Field(key: "address")
    var address: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}

    init(id: UUID? = nil, name: String, address: String) {
        self.id = id
        self.name = name
        self.address = address
    }
}
