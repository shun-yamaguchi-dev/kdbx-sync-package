import Foundation

enum ConfigurationError: Error {
    case emptyVaultList
    case duplicateVaultID(UUID)
    case emptyVaultName
    case invalidPath(String)
    case invalidDebounce(String)
}

extension ConfigurationError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case .emptyVaultList:
            return "configuration must contain at least one vault."

        case .duplicateVaultID(let id):
            return "vault ID '\(id)' is used more than once."

        case .emptyVaultName:
            return "vault name cannot be empty."

        case .invalidPath(let path):
            return "path must be a non-empty absolute path: '\(path)'."

        case .invalidDebounce(let name):
            return "'\(name)' must be greater than or equal to 0."
        }
    }
}
