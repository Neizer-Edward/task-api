import FluentKit
import Foundation
import Hummingbird
import HummingbirdFluent
import JWTKit

struct ProductController {
    typealias Context = AppRequestContext

    let fluent: Fluent
    let jwtKeyCollection: JWTKeyCollection
    let kid: JWKIdentifier

    func addRoutes(to group: RouterGroup<Context>) {
        let product = group.group("products")

        let protected = product.group()
            .add(middleware: JWTAuthenticator(jwtKeyCollection: jwtKeyCollection, fluent: fluent))
            protected.post(use: self.create)
            protected.get(use: self.list)
            protected.get(":id", use: self.getProduct)
            protected.put(":id", use: self.updateProduct)     
            protected.delete(":id", use: self.deleteProduct)   
    }

    func create(_ request: Request, context: Context) async throws -> Product {
        struct CreateProductRequest: Decodable {
            let name: String
            let price: Double
            let quantity: Int
        }

        guard let user = context.identity else {
            throw HTTPError(.unauthorized)
        }
        let data = try await request.decode(as: CreateProductRequest.self, context: context)
        let product = Product(
            name: data.name,
            price: data.price,
            quantity: data.quantity,
            shopID: user.$shop.id
        )
        try await product.save(on: fluent.db())
        return product
    }

    func list(_ request: Request, context: Context) async throws -> [Product] {
        guard let user = context.identity else {
            throw HTTPError(.unauthorized)
        }
        return try await Product.query(on: fluent.db())
            .filter(\.$shop.$id == user.$shop.id)
            .all()
    }

    func getProduct(_ request: Request, context: Context) async throws -> Product {
        guard let user = context.identity else {
            throw HTTPError(.unauthorized)
        }
        guard let id = context.parameters.get("id", as: UUID.self) else {
            throw HTTPError(.badRequest, message: "Invalid product ID")
        }
        guard let product = try await Product.find(id, on: fluent.db()) else {
            throw HTTPError(.notFound)
        }
        guard product.$shop.id == user.$shop.id else {
            throw HTTPError(.unauthorized, message: "Not your product")
        }
        return product
    }

    func updateProduct(_ request: Request, context: Context) async throws -> Product {
    struct UpdateProductRequest: Decodable {
        let name: String?
        let price: Double?
        let quantity: Int?
    }

    guard let user = context.identity else {
        throw HTTPError(.unauthorized)
    }

    guard let id = context.parameters.get("id", as: UUID.self) else {
        throw HTTPError(.badRequest, message: "Invalid product ID")
    }

    guard let product = try await Product.find(id, on: fluent.db()) else {
        throw HTTPError(.notFound)
    }

    guard product.$shop.id == user.$shop.id else {
        throw HTTPError(.unauthorized, message: "Not your product")
    }

    let input = try await request.decode(as: UpdateProductRequest.self, context: context)

    if let name = input.name { product.name = name }
    if let price = input.price { product.price = price }
    if let quantity = input.quantity { product.quantity = quantity }

    try await product.update(on: fluent.db())
    return product
}

func deleteProduct(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
    guard let user = context.identity else {
        throw HTTPError(.unauthorized)
    }

    guard let id = context.parameters.get("id", as: UUID.self) else {
        throw HTTPError(.badRequest, message: "Invalid product ID")
    }

    guard let product = try await Product.find(id, on: fluent.db()) else {
        throw HTTPError(.notFound)
    }

    guard product.$shop.id == user.$shop.id else {
        throw HTTPError(.unauthorized, message: "Not your product")
    }

    try await product.delete(on: fluent.db())
    return .ok
}


}
