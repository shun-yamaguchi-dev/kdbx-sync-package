import Foundation

enum LaunchdError: Error, LocalizedError {
    case plistSerializationFailed

    case commandFailed(
        status: Int32,
        message: String
    )

    case installationRollbackFailed(
        installationError: Error,
        rollbackError: Error
    )

    var errorDescription: String? {
        switch self {
        case .plistSerializationFailed:
            return "Failed to serialize LaunchAgent plist."

        case let .commandFailed(status, message):
            return "launchctl failed with status \(status): \(message)"

        case let .installationRollbackFailed(
            installationError,
            rollbackError
        ):
            return """
            LaunchAgent installation failed: \(installationError.localizedDescription)
            Rollback also failed: \(rollbackError.localizedDescription)
            """
        }
    }
}
