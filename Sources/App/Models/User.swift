import FluentKit
import Foundation
import Hummingbird
import HummingbirdAuth
import HummingbirdBasicAuth
import HummingbirdBcrypt
import NIOPosix

final class User: Model, PasswordAuthenticatable, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "email")
    var email: String

    @Field(key: "password_hash")
    var passwordHash: String?

    @Parent(key: "shop_id")
    var shop: Shop

    init() {}

   init(id: UUID?, name: String, email: String, passwordHash: String?, shopID: UUID) {
    self.id = id
    self.name = name
    self.email = email
    self.passwordHash = passwordHash
    self.$shop.id = shopID
}

    init(from request: CreateUserRequest) async throws {
        self.id = nil
        self.name = request.name
        self.email = request.email
        self.passwordHash = try await NIOThreadPool.singleton.runIfActive {
            Bcrypt.hash(request.password, cost: 12)
        }
        self.$shop.id = request.shopID
    }

    var username: String { self.email }
}

struct CreateUserRequest: Decodable {
    let name: String
    let email: String
    let password: String
    let shopID: UUID  
}

struct UserResponse: ResponseCodable {
    let id: UUID?
    let name: String
    let email: String
    let shopID: UUID

    init(from user: User) {
        self.id = user.id
        self.name = user.name
        self.email = user.email
        self.shopID = user.$shop.id
    }
}



