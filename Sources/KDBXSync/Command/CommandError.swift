import Foundation

enum CommandError: Error {
    case invalidArguments
    case unknownCommand(String)
}

extension CommandError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidArguments:
            return "invalid command arguments."

        case .unknownCommand(let command):
            return "unknown command: '\(command)'."
       }
    }
}
