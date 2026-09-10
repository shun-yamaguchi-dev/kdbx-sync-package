import Foundation

struct ConfigurationManager {
    let store: ConfigurationStore
    let validator: ConfigurationValidator

    func loadConfiguration() throws -> Configuration {
        let decoded = try store.loadDecoded()

        return try validator.validate(decoded)
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
}
