import Foundation

enum LoginItemStatus: Equatable {
    case notRegistered
    case enabled
    case requiresApproval
    case notFound
}

protocol LoginItemManaging {
    var status: LoginItemStatus { get }

    func register() throws
    func unregister() throws
}
