import Foundation
import XCTest
@testable import KDBXSync

final class ConfigurationManagerTests: XCTestCase {
    private var temporaryDirectory: URL!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        try FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: temporaryDirectory)
    }

    func testInitializeCreatesConfigurationWithDefaults() throws {
        let store = ConfigurationStore(
            configurationURL: temporaryDirectory
                .appendingPathComponent("config.toml")
        )
        let manager = makeManager(store: store)

        try manager.initializeConfiguration(
            keepassxc: "/usr/local/bin/keepassxc",
            fswatch: "/usr/local/bin/fswatch",
            pushDebounce: 2,
            pullDebounce: 2,
            ignoreWindow: 5
        )

        XCTAssertTrue(store.exists)

        let configuration = try store.loadDecoded()

        XCTAssertEqual(
            configuration.global.keepassxc,
            "/usr/local/bin/keepassxc"
        )
        XCTAssertEqual(
            configuration.global.fswatch,
            "/usr/local/bin/fswatch"
        )
        XCTAssertEqual(
            configuration.global.pushDebounce,
            2
        )
        XCTAssertEqual(
            configuration.global.pullDebounce,
            2
        )
        XCTAssertEqual(
            configuration.global.ignoreWindow,
            5
        )
        XCTAssertTrue(configuration.vaults.isEmpty)
    }

    func testInitializeDoesNotOverwriteExistingConfiguration() throws {
        let store = ConfigurationStore(
            configurationURL: temporaryDirectory
                .appendingPathComponent("config.toml")
        )
        let manager = makeManager(store: store)

        try manager.initializeConfiguration(
            keepassxc: "/usr/local/bin/keepassxc",
            fswatch: "/usr/local/bin/fswatch",
            pushDebounce: 2,
            pullDebounce: 2,
            ignoreWindow: 5
        )

        XCTAssertThrowsError(
            try manager.initializeConfiguration(
                keepassxc: "/different/keepassxc",
                fswatch: "/different/fswatch",
                pushDebounce: 1,
                pullDebounce: 1,
                ignoreWindow: 1
            )
        ) { error in
            XCTAssertEqual(
                error.localizedDescription,
                "configuration already exists."
            )
        }

        let configuration = try store.loadDecoded()

        XCTAssertEqual(
            configuration.global.keepassxc,
            "/usr/local/bin/keepassxc"
        )
    }

    func testInitializeRejectsInvalidGlobalConfiguration() {
        let store = ConfigurationStore(
            configurationURL: temporaryDirectory
                .appendingPathComponent("config.toml")
        )
        let manager = makeManager(store: store)

        XCTAssertThrowsError(
            try manager.initializeConfiguration(
                keepassxc: "relative/keepassxc",
                fswatch: "/usr/local/bin/fswatch",
                pushDebounce: 2,
                pullDebounce: 2,
                ignoreWindow: 5
            )
        ) { error in
            XCTAssertEqual(
                error.localizedDescription,
                "path must be a non-empty absolute path: 'relative/keepassxc'."
            )
        }

        XCTAssertFalse(store.exists)
    }

    func testInitializeRejectsNegativeTiming() {
        let store = ConfigurationStore(
            configurationURL: temporaryDirectory
                .appendingPathComponent("config.toml")
        )
        let manager = makeManager(store: store)

        XCTAssertThrowsError(
            try manager.initializeConfiguration(
                keepassxc: "/usr/local/bin/keepassxc",
                fswatch: "/usr/local/bin/fswatch",
                pushDebounce: -1,
                pullDebounce: 2,
                ignoreWindow: 5
            )
        ) { error in
            XCTAssertEqual(
                error.localizedDescription,
                "'push_debounce' must be greater than or equal to 0."
            )
        }

        XCTAssertFalse(store.exists)
    }

    func testEnableSynchronizesBeforeInstallingLaunchAgents() throws {
        let store = ConfigurationStore(
            configurationURL: temporaryDirectory
                .appendingPathComponent("config.toml")
        )

        let synchronizer = RecordingInitialSynchronizer()
        let launchAgentManager = RecordingLaunchAgentManager()

        let manager = makeManager(
            store: store,
            launchAgentManager: launchAgentManager,
            initialSynchronizer: synchronizer
        )

        try manager.initializeConfiguration(
            keepassxc: "/usr/local/bin/keepassxc",
            fswatch: "/usr/local/bin/fswatch",
            pushDebounce: 2,
            pullDebounce: 2,
            ignoreWindow: 5
        )

        try manager.addVault(
            name: "personal",
            localPath: "/vault/local.kdbx",
            localWatchPath: "/vault",
            remotePath: "/remote/remote.kdbx",
            remoteWatchPath: "/remote",
            keyfilePath: "/keys/vault.key"
        )

        try manager.setVaultEnabled(
            name: "personal",
            enabled: true
        )

        XCTAssertEqual(
            synchronizer.events,
            [.synchronize]
        )

        XCTAssertEqual(
            launchAgentManager.events,
            [.install]
        )

        let configuration = try store.loadDecoded()

        XCTAssertTrue(
            configuration.vaults[0].enabled
        )
    }

    func testReconcileDelegatesEveryVaultToLaunchAgentManager() throws {
        let store = ConfigurationStore(
            configurationURL: temporaryDirectory
                .appendingPathComponent("config.toml")
        )

        let launchAgentManager = RecordingLaunchAgentManager()

        let manager = makeManager(
            store: store,
            launchAgentManager: launchAgentManager
        )

        try manager.initializeConfiguration(
            keepassxc: "/usr/local/bin/keepassxc",
            fswatch: "/usr/local/bin/fswatch",
            pushDebounce: 2,
            pullDebounce: 2,
            ignoreWindow: 5
        )

        try manager.addVault(
            name: "enabled",
            localPath: "/vault/enabled-local.kdbx",
            localWatchPath: "/vault",
            remotePath: "/remote/enabled-remote.kdbx",
            remoteWatchPath: "/remote",
            keyfilePath: "/keys/enabled.key"
        )

        try manager.addVault(
            name: "disabled",
            localPath: "/vault/disabled-local.kdbx",
            localWatchPath: "/vault",
            remotePath: "/remote/disabled-remote.kdbx",
            remoteWatchPath: "/remote",
            keyfilePath: "/keys/disabled.key"
        )

        var decoded = try store.loadDecoded()

        decoded.vaults[0].enabled = true

        try store.save(decoded)

        try manager.reconcile()

        XCTAssertEqual(
            launchAgentManager.reconciliationEvents,
            [
                .reconcile(
                    name: "enabled",
                    enabled: true
                ),
                .reconcile(
                    name: "disabled",
                    enabled: false
                )
            ]
        )
    }

    private func makeManager(
        store: ConfigurationStore,
        launchAgentManager: LaunchAgentManaging = UnusedLaunchAgentManager(),
        initialSynchronizer: InitialSynchronizing = UnusedInitialSynchronizer()
    ) -> ConfigurationManager {
        ConfigurationManager(
            store: store,
            validator: ConfigurationValidator(),
            launchAgentManager: launchAgentManager,
            initialSynchronizer: initialSynchronizer,
            applicationPaths: ApplicationPaths(
                bundleURL: temporaryDirectory
            )
        )
    }
}
