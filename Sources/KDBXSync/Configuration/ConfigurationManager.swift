import Foundation

struct ConfigurationManager {
    let store: ConfigurationStore
    let validator: ConfigurationValidator

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
}
