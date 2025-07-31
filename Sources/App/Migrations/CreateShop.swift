import FluentKit

struct CreateShop: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("shops")
            .id()
            .field("name", .string, .required)
            .field("address", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("shops").delete()
    }
}
