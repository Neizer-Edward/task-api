import FluentKit

final class SaleItem: Model, @unchecked Sendable {
    static let schema = "sale_items"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "sale_id")
    var sale: Sale

    @Parent(key: "product_id")
    var product: Product

    @Field(key: "quantity")
    var quantity: Int

    @Field(key: "unit_price")
    var unitPrice: Double

    @Field(key: "total_price")
    var totalPrice: Double

    init() {}

    init(id: UUID? = nil, saleID: UUID, productID: UUID, quantity: Int, unitPrice: Double) {
        self.id = id
        self.$sale.id = saleID
        self.$product.id = productID
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.totalPrice = unitPrice * Double(quantity)
    }
}
