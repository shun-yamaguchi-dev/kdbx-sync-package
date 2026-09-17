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
}
