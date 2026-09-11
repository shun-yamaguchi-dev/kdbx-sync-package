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
        case "add":
            try addVault(
            arguments: arguments.dropFirst()
        )

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
        
        case "remove":
            try removeVault(
                arguments: arguments.dropFirst()
            )

        default:
            throw CommandError.unknownCommand(
                "vault \(action)"
            )
        }
    }

    private func addVault(
        arguments: ArraySlice<String>
    ) throws {
        var arguments = Array(arguments)

        guard let name = arguments.first else {
            throw CommandError.invalidArguments
        }

        arguments.removeFirst()

        var options: [String: String] = [:]

        while !arguments.isEmpty {
            let option = arguments.removeFirst()

            guard option.hasPrefix("--") else {
                throw CommandError.invalidArguments
            }

            guard !arguments.isEmpty else {
                throw CommandError.invalidArguments
            }

            let value = arguments.removeFirst()

            guard !value.hasPrefix("--") else {
                throw CommandError.invalidArguments
            }

            options[option] = value
        }

        guard
            let localPath = options["--local-path"],
            let localWatchPath = options["--local-watch-path"],
            let cloudPath = options["--cloud-path"],
            let cloudWatchPath = options["--cloud-watch-path"],
            let keyfilePath = options["--keyfile-path"]
        else {
            throw CommandError.invalidArguments
        }

        guard options.count == 5 else {
            throw CommandError.invalidArguments
        }

        try manager.addVault(
            name: name,
            localPath: localPath,
            localWatchPath: localWatchPath,
            cloudPath: cloudPath,
            cloudWatchPath: cloudWatchPath,
            keyfilePath: keyfilePath
        )

        print("Added vault '\(name)'.")
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

    private func removeVault(
        arguments: ArraySlice<String>
    ) throws {
        guard arguments.count == 1 else {
            throw CommandError.invalidArguments
        }

        let name = arguments[arguments.startIndex]

        try manager.removeVault(
            name: name
        )

        print("Removed vault '\(name)'.")
    }
}
