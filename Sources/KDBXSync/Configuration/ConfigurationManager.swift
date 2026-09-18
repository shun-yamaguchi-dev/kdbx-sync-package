import Foundation

struct ConfigurationManager {
    let store: ConfigurationStoring
    let validator: ConfigurationValidator
    let launchAgentManager: LaunchAgentManaging
    let initialSynchronizer: InitialSynchronizing
    let applicationPaths: ApplicationPaths

    init(
        store: ConfigurationStoring,
        validator: ConfigurationValidator,
        launchAgentManager: LaunchAgentManaging,
        initialSynchronizer: InitialSynchronizing,
        applicationPaths: ApplicationPaths
    ) {
        self.store = store
        self.validator = validator
        self.launchAgentManager = launchAgentManager
        self.initialSynchronizer = initialSynchronizer
        self.applicationPaths = applicationPaths
    }

    func loadConfiguration() throws -> Configuration {
        let decoded = try store.loadDecoded()

        return try validator.validate(decoded)
    }

    func reconcile() throws {
        let configuration = try loadConfiguration()

        for vault in configuration.vaults {
            try launchAgentManager.reconcile(
                vault: vault,
                enabled: vault.enabled,
                configuration: configuration,
                applicationPaths: applicationPaths
            )
        }
    }

    func initializeConfiguration(
        keepassxc: String,
        fswatch: String,
        pushDebounce: Int,
        pullDebounce: Int,
        ignoreWindow: Int
    ) throws {
        let global = DecodedGlobalConfiguration(
            keepassxc: keepassxc,
            fswatch: fswatch,
            pushDebounce: pushDebounce,
            pullDebounce: pullDebounce,
            ignoreWindow: ignoreWindow
        )

        _ = try validator.validateGlobal(global)

        try store.initialize(
            DecodedConfiguration(
                global: global,
                vaults: []
            )
        )
    }

    func addVault(
        name: String,
        localPath: String,
        localWatchPath: String,
        remotePath: String,
        remoteWatchPath: String,
        keyfilePath: String
    ) throws {
        var decoded = try store.loadDecoded()

        guard !decoded.vaults.contains(
            where: { $0.name == name }
        ) else {
            throw ConfigurationError.vaultNameAlreadyExists(name)
        }

        let vault = DecodedVault(
            id: UUID(),
            name: name,
            enabled: false,
            localPath: localPath,
            localWatchPath: localWatchPath,
            remotePath: remotePath,
            remoteWatchPath: remoteWatchPath,
            keyfilePath: keyfilePath
        )

        decoded.vaults.append(vault)

        _ = try validator.validate(decoded)

        try store.save(decoded)
    }

    func listVaults() throws -> [Vault] {
        try loadConfiguration().vaults
    }

    func renameVault(
        oldName: String,
        newName: String
    ) throws {
        var decoded = try store.loadDecoded()

        guard let vaultIndex = decoded.vaults.firstIndex(
            where: { $0.name == oldName }
        ) else {
            throw ConfigurationError.vaultNotFound(oldName)
        }

        guard !decoded.vaults.contains(
            where: { $0.name == newName }
        ) else {
            throw ConfigurationError.vaultNameAlreadyExists(newName)
        }

        decoded.vaults[vaultIndex].name = newName

        _ = try validator.validate(decoded)

        try store.save(decoded)
    }

    func findVault(named name: String) throws -> Vault {
        let configuration = try loadConfiguration()

        guard let vault = configuration.vaults.first(
            where: { $0.name == name }
        ) else {
            throw ConfigurationError.vaultNotFound(name)
        }

        return vault
    }

    func removeVault(name: String) throws {
        var decoded = try store.loadDecoded()

        guard let vaultIndex = decoded.vaults.firstIndex(
            where: { $0.name == name }
        ) else {
            throw ConfigurationError.vaultNotFound(name)
        }

        guard decoded.vaults.count > 1 else {
            throw ConfigurationError.cannotRemoveLastVault
        }

        let decodedVault = decoded.vaults[vaultIndex]

        if decodedVault.enabled {
            let configuration = try validator.validate(decoded)

            guard let vault = configuration.vaults.first(
                where: { $0.id == decodedVault.id }
            ) else {
                throw ConfigurationError.vaultNotFound(name)
            }

            try launchAgentManager.remove(
                vault: vault
            )
        }

        decoded.vaults.remove(at: vaultIndex)

        _ = try validator.validate(decoded)

        try store.save(decoded)
    }

    func setVaultEnabled(
        name: String,
        enabled: Bool
    ) throws {
        var decoded = try store.loadDecoded()

        guard let vaultIndex = decoded.vaults.firstIndex(
            where: { $0.name == name }
        ) else {
            throw ConfigurationError.vaultNotFound(name)
        }

        guard decoded.vaults[vaultIndex].enabled != enabled else {
            return
        }

        let previousEnabled = decoded.vaults[vaultIndex].enabled

        decoded.vaults[vaultIndex].enabled = enabled

        let configuration = try validator.validate(decoded)

        guard let vault = configuration.vaults.first(
            where: { $0.name == name }
        ) else {
            throw ConfigurationError.vaultNotFound(name)
        }

        if enabled {
            let synchronizationResult = try initialSynchronizer.synchronize(
                vault: vault
            )

            do {
                try launchAgentManager.install(
                    vault: vault,
                    configuration: configuration,
                    applicationPaths: applicationPaths
                )
            } catch {
                let installationError = error

                do {
                    try initialSynchronizer.rollback(
                        result: synchronizationResult,
                        vault: vault
                    )
                } catch {
                    throw ConfigurationError.rollbackFailed(
                        originalError: installationError,
                        rollbackError: error
                    )
                }

                throw installationError
            }

            do {
                try store.save(decoded)
            } catch {
                let saveError = error

                do {
                    try launchAgentManager.remove(
                        vault: vault
                    )

                    try initialSynchronizer.rollback(
                        result: synchronizationResult,
                        vault: vault
                    )
                } catch {
                    throw ConfigurationError.rollbackFailed(
                        originalError: saveError,
                        rollbackError: error
                    )
                }

                throw saveError
            }

            return
        }

        try launchAgentManager.remove(
            vault: vault
        )

        do {
            try store.save(decoded)
        } catch {
            let saveError = error

            decoded.vaults[vaultIndex].enabled = previousEnabled

            do {
                let previousConfiguration = try validator.validate(decoded)

                guard let previousVault = previousConfiguration.vaults.first(
                    where: { $0.id == vault.id }
                ) else {
                    throw ConfigurationError.vaultNotFound(name)
                }

                try launchAgentManager.install(
                    vault: previousVault,
                    configuration: previousConfiguration,
                    applicationPaths: applicationPaths
                )
            } catch {
                throw ConfigurationError.rollbackFailed(
                    originalError: saveError,
                    rollbackError: error
                )
            }

            throw saveError
        }
    }
}
