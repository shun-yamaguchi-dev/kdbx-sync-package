import Foundation

struct CommandHandler {
    let manager: ConfigurationManager

    func execute(arguments: ArraySlice<String>) throws {
        guard let resource = arguments.first else {
            throw CommandError.invalidArguments
        }

        switch resource {
        case "vault":
            try executeVaultCommand(
                arguments: arguments.dropFirst()
            )

        default:
            throw CommandError.unknownCommand(resource)
        }
    }

    private func executeVaultCommand(
        arguments: ArraySlice<String>
    ) throws {
        guard let action = arguments.first else {
            throw CommandError.invalidArguments
        }

        switch action {
        case "rename":
            try renameVault(
                arguments: arguments.dropFirst()
            )

        default:
            throw CommandError.unknownCommand(
                "vault \(action)"
            )
        }
    }

    private func renameVault(
        arguments: ArraySlice<String>
    ) throws {
        guard arguments.count == 2 else {
            throw CommandError.invalidArguments
        }

        let oldName = arguments[arguments.startIndex]
        let newName = arguments[
            arguments.index(after: arguments.startIndex)
        ]

        try manager.renameVault(
            oldName: oldName,
            newName: newName
        )

        print("Renamed vault '\(oldName)' to '\(newName)'.")
    }
}
