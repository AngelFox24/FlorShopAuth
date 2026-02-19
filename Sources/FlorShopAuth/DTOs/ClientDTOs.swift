import Vapor
import FlorShopDTOs

extension CompanyClientDTO: @retroactive Content {}
extension SubsidiaryClientDTO: @retroactive Content {}
extension EmployeeClientDTO: @retroactive Content {}
extension CustomerClientDTO: @retroactive Content {}
extension ProductClientDTO: @retroactive Content {}
extension SaleClientDTO: @retroactive Content {}
extension SaleDetailClientDTO: @retroactive Content {}
extension PayCustomerDebtClientDTO: @retroactive Content {}
extension SyncResponse: @retroactive Content {}
extension DefaultResponse: @retroactive Content {}
extension CompanyResponseDTO: @retroactive Content {}
extension SubsidiaryResponseDTO: @retroactive Content {}
extension RefreshTokenRequest: @retroactive Content {}
extension BaseTokenResponse: @retroactive Content {}
extension ScopedTokenResponse: @retroactive Content {}
extension ScopedTokenWithRefreshResponse: @retroactive Content {}
extension InitialDataDTO: @retroactive Content {}
