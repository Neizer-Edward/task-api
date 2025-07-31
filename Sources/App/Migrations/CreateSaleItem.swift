import FluentKit

struct CreateSaleItem: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("sale_items")
            .id()
            .field("sale_id", .uuid, .required, .references("sales", "id", onDelete: .cascade))
            .field("product_id", .uuid, .required, .references("products", "id"))
            .field("quantity", .int, .required)
            .field("unit_price", .double, .required)
            .field("total_price", .double, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("sale_items").delete()
    }
}
