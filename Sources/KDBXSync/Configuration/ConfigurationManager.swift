import Foundation

struct ConfigurationManager {
    let store: ConfigurationStore
    let validator: ConfigurationValidator
    let launchAgentManager: LaunchAgentManaging
    let applicationPaths: ApplicationPaths

    init(
        store: ConfigurationStore,
        validator: ConfigurationValidator,
        launchAgentManager: LaunchAgentManaging,
        applicationPaths: ApplicationPaths
    ) {
        self.store = store
        self.validator = validator
        self.launchAgentManager = launchAgentManager
        self.applicationPaths = applicationPaths
    }

    func loadConfiguration() throws -> Configuration {
        let decoded = try store.loadDecoded()

        return try validator.validate(decoded)
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

        decoded.vaults[vaultIndex].enabled = enabled

        let configuration = try validator.validate(decoded)

        guard let vault = configuration.vaults.first(
            where: { $0.name == name }
        ) else {
            throw ConfigurationError.vaultNotFound(name)
        }

        if enabled {
            try launchAgentManager.install(
                vault: vault,
                configuration: configuration,
                applicationPaths: applicationPaths
            )
        } else {
            try launchAgentManager.remove(
                vault: vault
            )
        }

        try store.save(decoded)
    }
}
