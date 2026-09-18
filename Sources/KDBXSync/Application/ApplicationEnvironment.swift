import Foundation

struct ApplicationEnvironment {
    let configurationURL: URL
    let launchAgentsDirectory: URL
    let stateDirectory: URL

    static var production: ApplicationEnvironment {
        let homeDirectory = FileManager.default
            .homeDirectoryForCurrentUser

        return ApplicationEnvironment(
            configurationURL: homeDirectory
                .appendingPathComponent(
                    ".config/kdbx-sync/config.toml"
                ),
            launchAgentsDirectory: homeDirectory
                .appendingPathComponent(
                    "Library/LaunchAgents"
                ),
            stateDirectory: homeDirectory
                .appendingPathComponent(
                    ".local/state/kdbx-sync"
                )
        )
    }
}
