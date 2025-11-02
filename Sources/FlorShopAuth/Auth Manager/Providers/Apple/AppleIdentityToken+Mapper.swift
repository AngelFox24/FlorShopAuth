import JWT

extension AppleIdentityToken {
    func toUserIdentityDTO() -> UserIdentityDTO? {
        guard let email = self.email else {
            return nil
        }
        return UserIdentityDTO(
            email: email,
            providerId: self.subject.value,
            name: nil,
            picture: nil
        )
    }
}
