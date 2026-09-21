import Foundation

enum SynchronizationError: LocalizedError {
    case bothFilesMissing
    case conflict

    var errorDescription: String? {
        switch self {
        case .bothFilesMissing:
            return "Both the local and remote vault files are missing."

        case .conflict:
            return "The local and remote vault files both exist but contain different data. Neither file was modified."
        }
    }
}
