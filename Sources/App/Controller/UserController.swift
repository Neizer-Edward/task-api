import HummingbirdBcrypt
import FluentKit
import Foundation
import Hummingbird
import HummingbirdAuth
import HummingbirdBasicAuth
import HummingbirdFluent
import JWTKit

struct UserController {
    typealias Context = AppRequestContext
    let jwtKeyCollection: JWTKeyCollection
    let kid: JWKIdentifier
    let fluent: Fluent

    func addRoutes(to group: RouterGroup<Context>) {
        let auth = group.group("auth")
        auth.post("register", use: self.register)
        auth.post("login", use: self.login)

        let protected = auth.group()
            .add(middleware: JWTAuthenticator(jwtKeyCollection: jwtKeyCollection, fluent: fluent))

        protected.get("me", use: self.me)
    }

    func register(_ request: Request, context: Context) async throws -> UserResponse {
        let reqData = try await request.decode(as: CreateUserRequest.self, context: context)
        let db = fluent.db()
        let exists = try await User.query(on: db)
            .filter(\.$email == reqData.email)
            .first()

        guard exists == nil else {
            throw HTTPError(.conflict, message: "Email already in use")
        }
        let newUser = try await User(from: reqData)
        try await newUser.save(on: db)

        return UserResponse(from: newUser)
    }

    func login(_ request: Request, context: Context) async throws -> [String: String] {
        struct LoginRequest: Decodable {
            let email: String
            let password: String
        }

        let reqData = try await request.decode(as: LoginRequest.self, context: context)
        let db = fluent.db()
        guard let user = try await User.query(on: db)
            .filter(\.$email == reqData.email)
            .first(),
              let hash = user.passwordHash,
              Bcrypt.verify(reqData.password, hash: hash)
        else {
            throw HTTPError(.unauthorized, message: "Invalid email or password")
        }

        let payload = UserPayload(
            subject: .init(value: try user.requireID().uuidString),
            expiration: .init(value: Date().addingTimeInterval(12 * 60 * 60)), // 12 hrs
            email: user.email,
            name: user.name,
            shopID: user.$shop.id
        )

        let token = try await jwtKeyCollection.sign(payload, kid: kid)
        return ["token": token]
    }

    func me(_ request: Request, context: Context) async throws -> UserResponse {
        guard let user = context.identity else {
            throw HTTPError(.unauthorized)
        }
        return UserResponse(from: user)
    }
}
