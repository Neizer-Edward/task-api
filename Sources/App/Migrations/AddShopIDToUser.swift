import FluentKit

struct AddShopIDToUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .field("shop_id", .uuid, .references("shops", "id", onDelete: .cascade))
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .deleteField("shop_id")
            .update()
    }
}
