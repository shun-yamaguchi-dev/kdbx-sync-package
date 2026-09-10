import Foundation

let configurationURL = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".config/kdbx-sync/config.toml")

do {
    let store = ConfigurationStore(
        configurationURL: configurationURL
    )

    let validator = ConfigurationValidator()

    let manager = ConfigurationManager(
        store: store,
        validator: validator
    )

    let commandHandler = CommandHandler(
        manager: manager
    )

    try commandHandler.execute(
        arguments: CommandLine.arguments.dropFirst()
    )
} catch {
    print("Error: \(error.localizedDescription)")
    exit(1)
}
