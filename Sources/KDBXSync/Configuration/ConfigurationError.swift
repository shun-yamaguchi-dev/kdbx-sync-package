import Foundation

enum ConfigurationError: Error {
    case emptyVaultList
    case duplicateVaultID(UUID)
    case duplicateVaultName(String)
    case emptyVaultName
    case invalidPath(String)
    case invalidDebounce(String)
    case vaultNotFound(String)
    case vaultNameAlreadyExists(String)
}

extension ConfigurationError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case .emptyVaultList:
            return "configuration must contain at least one vault."

        case .duplicateVaultID(let id):
            return "vault ID '\(id)' is used more than once."

        case .duplicateVaultName(let name):
            return "vault name '\(name)' is used more than once."

        case .emptyVaultName:
            return "vault name cannot be empty."

        case .invalidPath(let path):
            return "path must be a non-empty absolute path: '\(path)'."

        case .invalidDebounce(let name):
            return "'\(name)' must be greater than or equal to 0."

        case .vaultNotFound(let name):
            return "vault '\(name)' was not found."

        case .vaultNameAlreadyExists(let name):
            return "vault name '\(name)' is already in use."
        }
    }
}
