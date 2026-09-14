import Foundation

struct Application {
    let configurationURL: URL
    let launchAgentManager: LaunchAgentManaging

    init(
        configurationURL: URL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/kdbx-sync/config.toml"),
        launchAgentManager: LaunchAgentManaging = LaunchAgentManager()
    ) {
        self.configurationURL = configurationURL
        self.launchAgentManager = launchAgentManager
    }

    func run(
        arguments: ArraySlice<String>
    ) throws {
        let store = ConfigurationStore(
            configurationURL: configurationURL
        )

        let validator = ConfigurationValidator()

        let applicationPaths = ApplicationPaths()

        let manager = ConfigurationManager(
            store: store,
            validator: validator,
            launchAgentManager: launchAgentManager,
            applicationPaths: applicationPaths
        )

        let commandHandler = CommandHandler(
            manager: manager
        )

        try commandHandler.execute(
            arguments: arguments
        )
    }
}
