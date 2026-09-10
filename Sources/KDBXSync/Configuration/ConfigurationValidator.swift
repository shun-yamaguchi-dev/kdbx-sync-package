import Foundation

struct ConfigurationValidator {
    func validate(_ decoded: DecodedConfiguration) throws -> Configuration {
        guard !decoded.vaults.isEmpty else {
            throw ConfigurationError.emptyVaultList
        }

        let global = GlobalConfiguration(
            keepassxc: try validatedPath(decoded.global.keepassxc),
            fswatch: try validatedPath(decoded.global.fswatch),
            pushDebounce: try validatedDebounce(
                decoded.global.pushDebounce,
                name: "push_debounce"
            ),
            pullDebounce: try validatedDebounce(
                decoded.global.pullDebounce,
                name: "pull_debounce"
            ),
            ignoreWindow: try validatedDebounce(
                decoded.global.ignoreWindow,
                name: "ignore_window"
            )
        )

        var vaultIDs = Set<UUID>()

        let vaults = try decoded.vaults.map { decodedVault in
            guard vaultIDs.insert(decodedVault.id).inserted else {
                throw ConfigurationError.duplicateVaultID(decodedVault.id)
            }

            guard !decodedVault.name.isEmpty else {
                throw ConfigurationError.emptyVaultName
            }

            return Vault(
                id: decodedVault.id,
                name: decodedVault.name,
                enabled: decodedVault.enabled,
                localPath: try validatedPath(decodedVault.localPath),
                localWatchPath: try validatedPath(
                    decodedVault.localWatchPath
                ),
                cloudPath: try validatedPath(decodedVault.cloudPath),
                cloudWatchPath: try validatedPath(
                    decodedVault.cloudWatchPath
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
