import FluentKit

struct CreateSale: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("sales")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id"))
            .field("shop_id", .uuid, .required, .references("shops", "id"))
            .field("total_amount", .double, .required)
            .field("created_at", .datetime, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("sales").delete()
    }
}
