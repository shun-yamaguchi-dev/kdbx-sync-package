import Foundation

struct ConfigurationValidator {
    func validate(_ decoded: DecodedConfiguration) throws -> Configuration {
        guard !decoded.vaults.isEmpty else {
            throw ConfigurationError.emptyVaultList
        }

        let global = try validateGlobal(decoded.global)

        var vaultIDs = Set<UUID>()
        var vaultNames = Set<String>()

        let vaults = try decoded.vaults.map { decodedVault in
            guard vaultIDs.insert(decodedVault.id).inserted else {
                throw ConfigurationError.duplicateVaultID(decodedVault.id)
            }

            guard !decodedVault.name.isEmpty else {
                throw ConfigurationError.emptyVaultName
            }

            guard vaultNames.insert(decodedVault.name).inserted else {
                throw ConfigurationError.duplicateVaultName(
                    decodedVault.name
                )
            }

            return Vault(
                id: decodedVault.id,
                name: decodedVault.name,
                enabled: decodedVault.enabled,
                localPath: try validatedPath(decodedVault.localPath),
                localWatchPath: try validatedPath(
                    decodedVault.localWatchPath
                ),
                remotePath: try validatedPath(decodedVault.remotePath),
                remoteWatchPath: try validatedPath(
                    decodedVault.remoteWatchPath
                ),
                keyfilePath: try validatedPath(
                    decodedVault.keyfilePath
                )
            )
        }

        return Configuration(
            global: global,
            vaults: vaults
        )
    }

    func validateGlobal(
        _ decoded: DecodedGlobalConfiguration
    ) throws -> GlobalConfiguration {
        GlobalConfiguration(
            keepassxc: try validatedPath(decoded.keepassxc),
            fswatch: try validatedPath(decoded.fswatch),
            pushDebounce: try validatedDebounce(
                decoded.pushDebounce,
                name: "push_debounce"
            ),
            pullDebounce: try validatedDebounce(
                decoded.pullDebounce,
                name: "pull_debounce"
            ),
            ignoreWindow: try validatedDebounce(
                decoded.ignoreWindow,
                name: "ignore_window"
            )
        )
    }

    private func validatedPath(_ value: String) throws -> URL {
        guard !value.isEmpty, value.hasPrefix("/") else {
            throw ConfigurationError.invalidPath(value)
        }

        return URL(fileURLWithPath: value)
    }

    private func validatedDebounce(
        _ value: Int,
        name: String
    ) throws -> Int {
        guard value >= 0 else {
            throw ConfigurationError.invalidDebounce(name)
        }

        return value
    }
}
