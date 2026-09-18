import Foundation
import Testing
@testable import KDBXSync

struct ApplicationTests {
    @Test
    func reconcileWithoutConfigurationDoesNothing() throws {
        let temporaryDirectory = try makeTemporaryDirectory()

        defer {
            try? FileManager.default.removeItem(
                at: temporaryDirectory
            )
        }

        let configurationURL = temporaryDirectory
            .appendingPathComponent("config.toml")

        let application = Application(
            configurationURL: configurationURL,
            applicationBundleURL: temporaryDirectory
        )

        try application.run(
            arguments: ["--reconcile"]
        )

        #expect(
            !FileManager.default.fileExists(
                atPath: configurationURL.path
            )
        )
    }

    @Test
    func reconcileWithInvalidConfigurationThrows() throws {
        let temporaryDirectory = try makeTemporaryDirectory()

        defer {
            try? FileManager.default.removeItem(
                at: temporaryDirectory
            )
        }

        let configurationURL = temporaryDirectory
            .appendingPathComponent("config.toml")

        let store = ConfigurationStore(
            configurationURL: configurationURL
        )

        let configuration = DecodedConfiguration(
            global: DecodedGlobalConfiguration(
                keepassxc: "/usr/bin/true",
                fswatch: "/usr/bin/true",
                pushDebounce: -1,
                pullDebounce: 2,
                ignoreWindow: 5
            ),
            vaults: []
        )

        try store.initialize(configuration)

        let application = Application(
            configurationURL: configurationURL,
            applicationBundleURL: temporaryDirectory
        )

        #expect(throws: ConfigurationError.self) {
            try application.run(
                arguments: ["--reconcile"]
            )
        }
    }

    @Test
    func reconcileWithMissingRuntimeThrowsApplicationError() throws {
        let temporaryDirectory = try makeTemporaryDirectory()

        defer {
            try? FileManager.default.removeItem(
                at: temporaryDirectory
            )
        }

        let configurationURL = temporaryDirectory
            .appendingPathComponent("config.toml")

        let store = ConfigurationStore(
            configurationURL: configurationURL
        )

        let configuration = DecodedConfiguration(
            global: DecodedGlobalConfiguration(
                keepassxc: "/usr/bin/true",
                fswatch: "/usr/bin/true",
                pushDebounce: 2,
                pullDebounce: 2,
                ignoreWindow: 5
            ),
            vaults: [
                makeDecodedVault()
            ]
        )

        try store.initialize(configuration)

        let application = Application(
            configurationURL: configurationURL,
            applicationBundleURL: temporaryDirectory
        )

        #expect(throws: ApplicationError.self) {
            try application.run(
                arguments: ["--reconcile"]
            )
        }
    }

    @Test
    func reconcileRejectsAdditionalArguments() throws {
        let temporaryDirectory = try makeTemporaryDirectory()

        defer {
            try? FileManager.default.removeItem(
                at: temporaryDirectory
            )
        }

        let application = Application(
            configurationURL: temporaryDirectory
                .appendingPathComponent("config.toml"),
            applicationBundleURL: temporaryDirectory
        )

        #expect(throws: CommandError.self) {
            try application.run(
                arguments: ["--reconcile", "unexpected"]
            )
        }
    }

    @Test
    func reconcileUsesInstalledApplicationBundleRuntime() throws {
        let temporaryDirectory = try makeTemporaryDirectory()

        defer {
            try? FileManager.default.removeItem(
                at: temporaryDirectory
            )
        }

        let configurationURL = temporaryDirectory
            .appendingPathComponent("config.toml")

        let store = ConfigurationStore(
            configurationURL: configurationURL
        )

        let configuration = DecodedConfiguration(
            global: DecodedGlobalConfiguration(
                keepassxc: "/usr/bin/true",
                fswatch: "/usr/bin/true",
                pushDebounce: 2,
                pullDebounce: 2,
                ignoreWindow: 5
            ),
            vaults: [
                makeDecodedVault()
            ]
        )

        try store.initialize(configuration)

        let launchAgentManager = RecordingLaunchAgentManager()

        let application = Application(
            configurationURL: configurationURL,
            applicationBundleURL: URL(
                fileURLWithPath:
                    "\(NSHomeDirectory())/Applications/KDBX Sync.app"
            ),
            launchAgentManager: launchAgentManager,
            initialSynchronizer: UnusedInitialSynchronizer()
        )

        try application.run(
            arguments: ["--reconcile"]
        )

        #expect(
            launchAgentManager.reconciliationEvents.count == 1
        )
    }

    @Test
    func startupReconcilesLaunchAgents() throws {
        let temporaryDirectory = try makeTemporaryDirectory()

        defer {
            try? FileManager.default.removeItem(
                at: temporaryDirectory
            )
        }

        try makeRuntimeResources(
            in: temporaryDirectory
        )

        let configurationURL = temporaryDirectory
            .appendingPathComponent("config.toml")

        let store = ConfigurationStore(
            configurationURL: configurationURL
        )

        let configuration = DecodedConfiguration(
            global: DecodedGlobalConfiguration(
                keepassxc: "/usr/bin/true",
                fswatch: "/usr/bin/true",
                pushDebounce: 2,
                pullDebounce: 2,
                ignoreWindow: 5
            ),
            vaults: [
                makeDecodedVault()
            ]
        )

        try store.initialize(configuration)

        let launchAgentManager = RecordingLaunchAgentManager()

        let application = Application(
            configurationURL: configurationURL,
            applicationBundleURL: temporaryDirectory,
            launchAgentManager: launchAgentManager,
            initialSynchronizer: UnusedInitialSynchronizer()
        )

        try application.runStartup()

        #expect(
            launchAgentManager.reconciliationEvents.count == 1
        )

        #expect(
            launchAgentManager.reconciliationEvents[0]
                == .reconcile(
                    name: "Test",
                    enabled: true
                )
        )
    }

    private func makeDecodedVault() -> DecodedVault {
        DecodedVault(
            id: UUID(),
            name: "Test",
            enabled: true,
            localPath: "/tmp/local.kdbx",
            localWatchPath: "/tmp",
            remotePath: "/tmp/remote.kdbx",
            remoteWatchPath: "/tmp",
            keyfilePath: "/tmp/keyfile"
        )
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "KDBXSyncTests-\(UUID().uuidString)",
                isDirectory: true
            )

        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        return directory
    }

    private func makeRuntimeResources(
        in applicationBundleURL: URL
    ) throws {
        let runtimeDirectory = applicationBundleURL
            .appendingPathComponent(
                "Contents/Resources/Runtime",
                isDirectory: true
            )

        try FileManager.default.createDirectory(
            at: runtimeDirectory,
            withIntermediateDirectories: true
        )

        let runtimeFiles = [
            "kdbx-push-runner.sh",
            "kdbx-push.sh",
            "kdbx-pull-runner.sh",
            "kdbx-pull.sh",
            "lib.sh"
        ]

        for filename in runtimeFiles {
            let fileURL = runtimeDirectory
                .appendingPathComponent(filename)

            let contents = "#!/bin/bash\n"

            try contents.write(
                to: fileURL,
                atomically: true,
                encoding: .utf8
            )

            try FileManager.default.setAttributes(
                [
                    .posixPermissions: 0o755
                ],
                ofItemAtPath: fileURL.path
            )
        }
    }
}
