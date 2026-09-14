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
}
