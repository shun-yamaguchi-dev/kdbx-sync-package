import Foundation
import ServiceManagement

struct SMAppLoginItemManager: LoginItemManaging {
    private let service: SMAppService

    init(
        service: SMAppService = .mainApp
    ) {
        self.service = service
    }

    var status: LoginItemStatus {
        switch service.status {
        case .notRegistered:
            return .notRegistered

        case .enabled:
            return .enabled

        case .requiresApproval:
            return .requiresApproval

        case .notFound:
            return .notFound

        @unknown default:
            return .notFound
        }
    }

    func register() throws {
        try service.register()
    }

    func unregister() throws {
        try service.unregister()
    }
}
