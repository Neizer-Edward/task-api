import FluentKit
import Foundation
import Hummingbird
import HummingbirdAuth
import HummingbirdFluent
import JWTKit
import NIOFoundationCompat

struct JWTAuthenticator: AuthenticatorMiddleware, @unchecked Sendable {
    typealias Context = AppRequestContext
    let jwtKeyCollection: JWTKeyCollection
    let fluent: Fluent

    init(jwtKeyCollection: JWTKeyCollection, fluent: Fluent) {
        self.jwtKeyCollection = jwtKeyCollection
        self.fluent = fluent
    }

    func authenticate(request: Request, context: Context) async throws -> User? {
        guard let token = request.headers.bearer?.token else {
            throw HTTPError(.unauthorized)
        }

        let payload: UserPayload
        do {
            payload = try await jwtKeyCollection.verify(token, as: UserPayload.self)
        } catch {
            context.logger.debug("JWT verification failed: \(error)")
            throw HTTPError(.unauthorized)
        }

        guard let userID = UUID(uuidString: payload.subject.value) else {
            context.logger.debug("Invalid JWT subject: \(payload.subject.value)")
            throw HTTPError(.unauthorized)
        }

        return User(
            id: userID,
            name: payload.name,
            email: payload.email,
            passwordHash: nil,
            shopID: payload.shopID
        )
    }
}
