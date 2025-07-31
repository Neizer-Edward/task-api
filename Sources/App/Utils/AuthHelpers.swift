import Foundation
import Hummingbird
import FluentKit


func authorizeShopAccess(user: User?, shopID: UUID) throws {
    guard let user = user else {
        throw HTTPError(.unauthorized, message: "Unauthorized")
    }

    guard user.$shop.id == shopID else {
        throw HTTPError(.forbidden, message: "You do not have access to this shop.")
    }
}
