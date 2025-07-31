import Foundation
import FluentKit
import Hummingbird
import HummingbirdFluent
import JWTKit

struct SaleController {
    typealias Context = AppRequestContext

    let fluent: Fluent
    let jwtKeyCollection: JWTKeyCollection
    let kid: JWKIdentifier

    func addRoutes(to group: RouterGroup<Context>) {
        let sale = group.group("sales")

        let protected = sale.group()
            .add(middleware: JWTAuthenticator(jwtKeyCollection: jwtKeyCollection, fluent: fluent))

        protected.post(use: self.createSale)
        protected.get(use: self.listSales)
        protected.get(":id", use: self.getSale)
    }

    struct CreateSaleItemRequest: Decodable {
        let productID: UUID
        let quantity: Int
        let unitPrice: Double 
    }

    struct CreateSaleRequest: Decodable {
        let items: [CreateSaleItemRequest]
    }

 func createSale(_ request: Request, context: Context) async throws -> some ResponseEncodable {
    guard let user = context.identity else {
        throw HTTPError(.unauthorized)
    }

    do {
        let input = try await request.decode(as: CreateSaleRequest.self, context: context)

        guard !input.items.isEmpty else {
            throw HTTPError(.badRequest, message: "No sale items provided")
        }

        return try await fluent.db().transaction { db in

            let totalAmount = input.items.reduce(0.0) { $0 + ($1.unitPrice * Double($1.quantity)) }
            let sale = Sale(
                userID: try user.requireID(),
                shopID: user.$shop.id,
                totalAmount: totalAmount
            )
            try await sale.save(on: db)

            for item in input.items {
                guard let product = try await Product.find(item.productID, on: db) else {
                    throw HTTPError(.badRequest, message: "Invalid product ID: \(item.productID)")
                }

                guard product.$shop.id == user.$shop.id else {
                    throw HTTPError(.unauthorized, message: "You do not own product: \(product.name)")
                }

                if product.quantity < item.quantity {
                    throw HTTPError(.badRequest, message: "Insufficient stock for product: \(product.name)")
                }

                let saleItem = SaleItem(
                    saleID: try sale.requireID(),
                    productID: item.productID,
                    quantity: item.quantity,
                    unitPrice: item.unitPrice
                )
                try await saleItem.save(on: db)
                product.quantity -= item.quantity
                try await product.save(on: db)
            }

            return sale
        }

    } catch {
        context.logger.error("Sale creation failed: \(String(reflecting: error))")
        throw HTTPError(.internalServerError, message: "Could not create sale: \(error)")
    }
}


    func listSales(_ request: Request, context: Context) async throws -> [Sale] {
        guard let user = context.identity else {
            throw HTTPError(.unauthorized)
        }
        return try await Sale.query(on: fluent.db())
            .filter(\.$shop.$id == user.$shop.id)
            .sort(\.$createdAt, .descending)
            .all()
    }

    func getSale(_ request: Request, context: Context) async throws -> SaleWithItemsResponse {
        guard let user = context.identity else {
            throw HTTPError(.unauthorized)
        }
        guard let id = context.parameters.get("id", as: UUID.self),
              let sale = try await Sale.find(id, on: fluent.db()) else {
            throw HTTPError(.notFound, message: "Sale not found")
        }

        guard sale.$shop.id == user.$shop.id else {
            throw HTTPError(.unauthorized, message: "Not your sale")
        }

        let items = try await SaleItem.query(on: fluent.db())
            .filter(\.$sale.$id == sale.requireID())
            .with(\.$product)
            .all()

        return SaleWithItemsResponse(
            id: try sale.requireID(),
            totalAmount: sale.totalAmount,
            createdAt: sale.createdAt,
            items: items.map {
                SaleItemResponse(
                    id: $0.id!,
                    productID: $0.$product.id,
                    productName: $0.product.name,
                    quantity: $0.quantity,
                    unitPrice: $0.unitPrice,
                    totalPrice: $0.totalPrice
                )
            }
        )
    }

    struct SaleWithItemsResponse: Codable, ResponseEncodable {
        let id: UUID
        let totalAmount: Double
        let createdAt: Date
        let items: [SaleItemResponse]
    }

    struct SaleItemResponse: Codable {
        let id: UUID
        let productID: UUID
        let productName: String
        let quantity: Int
        let unitPrice: Double
        let totalPrice: Double
    }
}
