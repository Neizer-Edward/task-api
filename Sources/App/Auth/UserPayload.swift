import Foundation
import JWTKit

struct UserPayload: JWTPayload, Equatable {
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
        case email = "email"
        case name = "name"
        case shopID = "shop_id"
    }

    let subject: SubjectClaim  
    let expiration: ExpirationClaim 
    let email: String
    let name: String
    let shopID: UUID 

    func verify(using algorithm: some JWTAlgorithm) async throws {
        try self.expiration.verifyNotExpired()
    }
}
