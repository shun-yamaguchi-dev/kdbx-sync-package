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
        case "list":
            try listVaults(
                arguments: arguments.dropFirst()
            )

        case "show":
        try showVault(
            arguments: arguments.dropFirst()
        )

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

   private func listVaults(
        arguments: ArraySlice<String>
    ) throws {
        guard arguments.isEmpty else {
            throw CommandError.invalidArguments
        }

        let vaults = try manager.listVaults()

        print("NAME\tID\tSTATUS")

        for vault in vaults {
            let status = vault.enabled ? "enabled" : "disabled"

            print(
                "\(vault.name)\t\(vault.id)\t\(status)"
            )
        }
    }

    private func showVault(
        arguments: ArraySlice<String>
    ) throws {
        guard arguments.count == 1 else {
            throw CommandError.invalidArguments
        }

        let name = arguments[arguments.startIndex]

        let vault = try manager.findVault(
            named: name
        )

        let status = vault.enabled ? "enabled" : "disabled"

        print("Name:              \(vault.name)")
        print("ID:                \(vault.id)")
        print("Status:             \(status)")
        print("Local path:         \(vault.localPath.path)")
        print("Local watch path:   \(vault.localWatchPath.path)")
        print("Cloud path:         \(vault.cloudPath.path)")
        print("Cloud watch path:   \(vault.cloudWatchPath.path)")
        print("Keyfile path:       \(vault.keyfilePath.path)")
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
