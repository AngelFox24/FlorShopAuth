import Foundation
import JWT

struct BaseTokenPayload: JWTPayload {
    var sub: SubjectClaim       //user_cic
    var type: String            //type of token
    var iss: IssuerClaim        //signer
    var iat: IssuedAtClaim      //generated date
    var exp: ExpirationClaim    //expiration date

    init(subject: String, issuedAt: Date, expiration: Date) {
        self.sub = .init(value: subject)
        self.type = "base"
        self.iss = .init(value: "FlorShopAuth")
        self.iat = .init(value: issuedAt)
        self.exp = .init(value: expiration)
    }

    func verify(using signer: some JWTAlgorithm) throws {
        try exp.verifyNotExpired()
    }
}
