import JWT

extension GoogleIdentityToken {
    func toUserIdentityDTO() -> UserIdentityDTO? {
        guard let email = self.email else {
            return nil
        }
        return UserIdentityDTO(
            email: email,
            providerId: self.subject.value,
            name: self.name,
            picture: self.picture
        )
    }
}
