import Foundation

struct Application {
    let commandHandler: CommandHandler
    let configurationManager: ConfigurationManager
    let applicationPaths: ApplicationPaths

    init(
        environment: ApplicationEnvironment = .production,
        applicationBundleURL: URL = Bundle.main.bundleURL,
        launchAgentManager: LaunchAgentManaging? = nil,
        initialSynchronizer: InitialSynchronizing = InitialSynchronizer(),
        loginItemManager: LoginItemManaging? = nil
    ) {
        let store = ConfigurationStore(
            configurationURL: environment.configurationURL
        )

        let validator = ConfigurationValidator()

        let paths = ApplicationPaths(
            bundleURL: applicationBundleURL
        )

        let resolvedLaunchAgentManager =
            launchAgentManager
            ?? LaunchAgentManager(
                launchAgentsDirectory: environment.launchAgentsDirectory,
                stateDirectory: environment.stateDirectory
            )

        let manager = ConfigurationManager(
            store: store,
            validator: validator,
            launchAgentManager: resolvedLaunchAgentManager,
            initialSynchronizer: initialSynchronizer,
            applicationPaths: paths
        )

        let resolvedLoginItemManager =
            loginItemManager
            ?? SMAppLoginItemManager()

        configurationManager = manager
        applicationPaths = paths

        commandHandler = CommandHandler(
            manager: manager,
            loginItemManager: resolvedLoginItemManager
        )
    }

    init(
        configurationURL: URL,
        applicationBundleURL: URL = Bundle.main.bundleURL,
        launchAgentManager: LaunchAgentManaging? = nil,
        initialSynchronizer: InitialSynchronizing = InitialSynchronizer(),
        loginItemManager: LoginItemManaging? = nil
    ) {
        self.init(
            environment: ApplicationEnvironment(
                configurationURL: configurationURL,
                launchAgentsDirectory: FileManager.default
                    .homeDirectoryForCurrentUser
                    .appendingPathComponent(
                        "Library/LaunchAgents"
                    ),
                stateDirectory: FileManager.default
                    .homeDirectoryForCurrentUser
                    .appendingPathComponent(
                        ".local/state/kdbx-sync"
                    )
            ),
            applicationBundleURL: applicationBundleURL,
            launchAgentManager: launchAgentManager,
            initialSynchronizer: initialSynchronizer,
            loginItemManager: loginItemManager
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

    func runStartup() throws {
        try reconcile()
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
