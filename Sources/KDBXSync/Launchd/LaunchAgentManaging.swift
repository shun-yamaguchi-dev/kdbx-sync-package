import Foundation

protocol LaunchAgentManaging {
    func install(
        vault: Vault,
        configuration: Configuration,
        applicationPaths: ApplicationPaths
    ) throws

    func remove(
        vault: Vault
    ) throws

    func reconcile(
        vault: Vault,
        enabled: Bool,
        configuration: Configuration,
        applicationPaths: ApplicationPaths
    ) throws
}
