import Foundation

struct CommandHandler {
    let manager: ConfigurationManager

    func execute(arguments: ArraySlice<String>) throws {
        guard let resource = arguments.first else {
            throw CommandError.invalidArguments
        }

        switch resource {
        case "init":
            try initializeConfiguration(
                arguments: arguments.dropFirst()
            )

        case "vault":
            try executeVaultCommand(
                arguments: arguments.dropFirst()
            )

        default:
            throw CommandError.unknownCommand(resource)
        }
    }

    private func initializeConfiguration(
        arguments: ArraySlice<String>
    ) throws {
        var remaining = Array(arguments)
        var options: [String: String] = [:]

        while !remaining.isEmpty {
            let option = remaining.removeFirst()

            guard option.hasPrefix("--"),
                  !remaining.isEmpty,
                  options[option] == nil
            else {
                throw CommandError.invalidArguments
            }

            let value = remaining.removeFirst()

            guard !value.hasPrefix("--") else {
                throw CommandError.invalidArguments
            }

            options[option] = value
        }

        guard
            let keepassxc = options.removeValue(forKey: "--keepassxc"),
            let fswatch = options.removeValue(forKey: "--fswatch")
        else {
            throw CommandError.invalidArguments
        }

        let pushDebounce = try integerOption(
            "--push-debounce",
            from: &options,
            defaultValue: 2
        )
        let pullDebounce = try integerOption(
            "--pull-debounce",
            from: &options,
            defaultValue: 2
        )
        let ignoreWindow = try integerOption(
            "--ignore-window",
            from: &options,
            defaultValue: 5
        )

        guard options.isEmpty else {
            throw CommandError.invalidArguments
        }

        try manager.initializeConfiguration(
            keepassxc: keepassxc,
            fswatch: fswatch,
            pushDebounce: pushDebounce,
            pullDebounce: pullDebounce,
            ignoreWindow: ignoreWindow
        )

        print("Created configuration. Add a vault with 'kdbx-sync vault add'.")
    }

    private func integerOption(
        _ name: String,
        from options: inout [String: String],
        defaultValue: Int
    ) throws -> Int {
        guard let value = options.removeValue(forKey: name) else {
            return defaultValue
        }

        guard let integer = Int(value) else {
            throw CommandError.invalidArguments
        }

        return integer
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
        
        case "enable":
            try setVaultEnabled(
                arguments: arguments.dropFirst(),
                enabled: true
            )

        case "disable":
            try setVaultEnabled(
                arguments: arguments.dropFirst(),
                enabled: false
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

            guard options[option] == nil else {
            throw CommandError.invalidArguments
            }

            options[option] = value
        }
        
        guard
            let localPath = options["--local-path"],
            let localWatchPath = options["--local-watch-path"],
            let remotePath = options["--remote-path"],
            let remoteWatchPath = options["--remote-watch-path"],
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
            remotePath: remotePath,
            remoteWatchPath: remoteWatchPath,
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
        print("remote path:         \(vault.remotePath.path)")
        print("remote watch path:   \(vault.remoteWatchPath.path)")
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

        private func setVaultEnabled(
        arguments: ArraySlice<String>,
        enabled: Bool
    ) throws {
        guard arguments.count == 1 else {
            throw CommandError.invalidArguments
        }

        let name = arguments[arguments.startIndex]

        try manager.setVaultEnabled(
            name: name,
            enabled: enabled
        )
 
        let action = enabled ? "Enabled" : "Disabled"

        print("\(action) vault '\(name)'.")
    }
}
