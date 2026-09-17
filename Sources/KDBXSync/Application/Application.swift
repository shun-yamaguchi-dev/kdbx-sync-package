import Foundation

struct Application {
    let commandHandler: CommandHandler
    let configurationManager: ConfigurationManager
    let applicationPaths: ApplicationPaths

    init(
        configurationURL: URL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/kdbx-sync/config.toml"),
        applicationBundleURL: URL = Bundle.main.bundleURL,
        launchAgentManager: LaunchAgentManaging = LaunchAgentManager(),
        initialSynchronizer: InitialSynchronizing = InitialSynchronizer()
    ) {
        let store = ConfigurationStore(
            configurationURL: configurationURL
        )

        let validator = ConfigurationValidator()

        let paths = ApplicationPaths(
            bundleURL: applicationBundleURL
        )

        let manager = ConfigurationManager(
            store: store,
            validator: validator,
            launchAgentManager: launchAgentManager,
            initialSynchronizer: initialSynchronizer,
            applicationPaths: paths
        )

        configurationManager = manager
        applicationPaths = paths

        commandHandler = CommandHandler(
            manager: manager
        )
    }

    func run(arguments: ArraySlice<String>) throws {
        if arguments.first == "--reconcile" {
            guard arguments.count == 1 else {
                throw CommandError.invalidArguments
            }

            try reconcile()

            return
        }

        try commandHandler.execute(
            arguments: arguments
        )
    }

    private func reconcile() throws {
        let store = configurationManager.store

        guard store.exists else {
            return
        }

        _ = try configurationManager.loadConfiguration()

        try applicationPaths.validateRuntime()

        try configurationManager.reconcile()
    }
}
