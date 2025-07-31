import FluentKit
import Foundation
import Hummingbird
import HummingbirdFluent
import JWTKit

struct ShopController {
    typealias Context = AppRequestContext

    let fluent: Fluent
    let jwtKeyCollection: JWTKeyCollection
    let kid: JWKIdentifier

    func addRoutes(to group: RouterGroup<Context>) {
        let shop = group.group("shops")
        let protected = shop.group()
            .add(middleware: JWTAuthenticator(jwtKeyCollection: jwtKeyCollection, fluent: fluent))

        protected.post(use: self.create)
        protected.get(use: self.list)
        protected.get(":id", use: self.getShop)
    }

    func create(_ request: Request, context: Context) async throws -> Shop {
        struct CreateShopRequest: Decodable {
            let name: String
            let address: String
        }

        guard let user = context.identity else {
            throw HTTPError(.unauthorized)
        }

        let input = try await request.decode(as: CreateShopRequest.self, context: context)
        let shop = Shop(name: input.name, address: input.address)
        try await shop.save(on: fluent.db())

        return shop
    }

  func list(_ request: Request, context: Context) async throws -> [Shop] {
    guard let user = context.identity else {
        throw HTTPError(.unauthorized)
    }

    guard let shop = try await Shop.find(user.$shop.id, on: fluent.db()) else {
        throw HTTPError(.notFound)
    }

    return [shop]
}

    func getShop(_ request: Request, context: Context) async throws -> Shop {
        guard let user = context.identity else {
            throw HTTPError(.unauthorized)
        }

        guard let shopID = context.parameters.get("id", as: UUID.self) else {
            throw HTTPError(.badRequest, message: "Invalid shop ID")
        }

        guard shopID == user.$shop.id else {
            throw HTTPError(.unauthorized, message: "Not your shop")
        }

        guard let shop = try await Shop.find(shopID, on: fluent.db()) else {
            throw HTTPError(.notFound)
        }
        return shop
    }
}
