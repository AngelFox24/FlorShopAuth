import Vapor
import Fluent

extension Application {
    func configureMigrations() {
        self.migrations.add(CreateUser())
        self.migrations.add(CreateCompany())
        self.migrations.add(CreateSubsidiary())
        self.migrations.add(CreateInvitation())
        self.migrations.add(CreateUserSubsidiary())
        self.migrations.add(CreateUserIdentity())
        self.migrations.add(CreateRefreshToken())
        self.migrations.add(CreateAuthorizationCode())
        self.migrations.add(CreateInternalService())
        self.migrations.add(UpdateUserBillingParams())
        self.migrations.add(CreatePlan())
        self.migrations.add(CreatePlanFeature())
        self.migrations.add(CreateSuscription())
        self.migrations.add(UpdateCompanyParams())
    }
}
