import Foundation
import XCTest
@testable import KDBXSync

final class IntegrationTests: XCTestCase {
    private var temporaryDirectory: URL!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "KDBXSyncIntegrationTests-\(UUID().uuidString)"
            )

        try FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(
            at: temporaryDirectory
        )
    }

    func testEnableVaultSynchronizesLocalVaultToRemote() throws {
        let configurationURL = temporaryDirectory
            .appendingPathComponent("config.toml")

        let localDirectory = temporaryDirectory
            .appendingPathComponent("local")

        let remoteDirectory = temporaryDirectory
            .appendingPathComponent("remote")

        try FileManager.default.createDirectory(
            at: localDirectory,
            withIntermediateDirectories: true
        )

        try FileManager.default.createDirectory(
            at: remoteDirectory,
            withIntermediateDirectories: true
        )

        let localVault = localDirectory
            .appendingPathComponent("personal.kdbx")

        let remoteVault = remoteDirectory
            .appendingPathComponent("personal.kdbx")

        let keyfile = localDirectory
            .appendingPathComponent("personal.key")

        let contents = Data(
            "integration-test-vault".utf8
        )

        try contents.write(
            to: localVault
        )

        try Data("test-keyfile".utf8).write(
            to: keyfile
        )

        let decodedConfiguration = makeConfiguration(
            configurationURL: configurationURL,
            localVault: localVault,
            localDirectory: localDirectory,
            remoteVault: remoteVault,
            remoteDirectory: remoteDirectory,
            keyfile: keyfile
        )

        let store = ConfigurationStore(
            configurationURL: configurationURL
        )

        try store.initialize(
            decodedConfiguration
        )

        let launchAgentManager =
            RecordingLaunchAgentManager()

        let application = Application(
            configurationURL: configurationURL,
            applicationBundleURL: temporaryDirectory,
            launchAgentManager: launchAgentManager
        )

        try application.run(
            arguments: [
                "vault",
                "enable",
                "personal"
            ]
        )

        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: remoteVault.path
            )
        )

        XCTAssertEqual(
            try Data(contentsOf: remoteVault),
            contents
        )

        XCTAssertEqual(
            launchAgentManager.events,
            [.install]
        )

        let configuration =
            try store.loadDecoded()

        XCTAssertTrue(
            configuration.vaults[0].enabled
        )
    }

    func testEnableVaultSynchronizesRemoteVaultToLocal() throws {
        let configurationURL = temporaryDirectory
            .appendingPathComponent("config.toml")

        let localDirectory = temporaryDirectory
            .appendingPathComponent("local")

        let remoteDirectory = temporaryDirectory
            .appendingPathComponent("remote")

        try FileManager.default.createDirectory(
            at: localDirectory,
            withIntermediateDirectories: true
        )

        try FileManager.default.createDirectory(
            at: remoteDirectory,
            withIntermediateDirectories: true
        )

        let localVault = localDirectory
            .appendingPathComponent("personal.kdbx")

        let remoteVault = remoteDirectory
            .appendingPathComponent("personal.kdbx")

        let keyfile = localDirectory
            .appendingPathComponent("personal.key")

        let contents = Data(
            "integration-test-remote-vault".utf8
        )

        try contents.write(
            to: remoteVault
        )

        try Data("test-keyfile".utf8).write(
            to: keyfile
        )

        let decodedConfiguration = makeConfiguration(
            configurationURL: configurationURL,
            localVault: localVault,
            localDirectory: localDirectory,
            remoteVault: remoteVault,
            remoteDirectory: remoteDirectory,
            keyfile: keyfile
        )

        let store = ConfigurationStore(
            configurationURL: configurationURL
        )

        try store.initialize(
            decodedConfiguration
        )

        let launchAgentManager =
            RecordingLaunchAgentManager()

        let application = Application(
            configurationURL: configurationURL,
            applicationBundleURL: temporaryDirectory,
            launchAgentManager: launchAgentManager
        )

        try application.run(
            arguments: [
                "vault",
                "enable",
                "personal"
            ]
        )

        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: localVault.path
            )
        )

        XCTAssertEqual(
            try Data(contentsOf: localVault),
            contents
        )

        XCTAssertEqual(
            launchAgentManager.events,
            [.install]
        )

        let configuration =
            try store.loadDecoded()

        XCTAssertTrue(
            configuration.vaults[0].enabled
        )
    }

    func testEnableVaultRejectsConflictWithoutChangingFilesOrInstallingAgents() throws {
        let configurationURL = temporaryDirectory
            .appendingPathComponent("config.toml")

        let localDirectory = temporaryDirectory
            .appendingPathComponent("local")

        let remoteDirectory = temporaryDirectory
            .appendingPathComponent("remote")

        try FileManager.default.createDirectory(
            at: localDirectory,
            withIntermediateDirectories: true
        )

        try FileManager.default.createDirectory(
            at: remoteDirectory,
            withIntermediateDirectories: true
        )

        let localVault = localDirectory
            .appendingPathComponent("personal.kdbx")

        let remoteVault = remoteDirectory
            .appendingPathComponent("personal.kdbx")

        let keyfile = localDirectory
            .appendingPathComponent("personal.key")

        let localContents = Data(
            "local-version".utf8
        )

        let remoteContents = Data(
            "remote-version".utf8
        )

        try localContents.write(
            to: localVault
        )

        try remoteContents.write(
            to: remoteVault
        )

        try Data("test-keyfile".utf8).write(
            to: keyfile
        )

        let decodedConfiguration = makeConfiguration(
            configurationURL: configurationURL,
            localVault: localVault,
            localDirectory: localDirectory,
            remoteVault: remoteVault,
            remoteDirectory: remoteDirectory,
            keyfile: keyfile
        )

        let store = ConfigurationStore(
            configurationURL: configurationURL
        )

        try store.initialize(
            decodedConfiguration
        )

        let launchAgentManager =
            RecordingLaunchAgentManager()

        let application = Application(
            configurationURL: configurationURL,
            applicationBundleURL: temporaryDirectory,
            launchAgentManager: launchAgentManager
        )

        XCTAssertThrowsError(
            try application.run(
                arguments: [
                    "vault",
                    "enable",
                    "personal"
                ]
            )
        ) { error in
            XCTAssertEqual(
                error as? SynchronizationError,
                .conflict
            )
        }

        XCTAssertEqual(
            try Data(contentsOf: localVault),
            localContents
        )

        XCTAssertEqual(
            try Data(contentsOf: remoteVault),
            remoteContents
        )

        XCTAssertTrue(
            launchAgentManager.events.isEmpty
        )

        let configuration =
            try store.loadDecoded()

        XCTAssertFalse(
            configuration.vaults[0].enabled
        )
    }

    private func makeConfiguration(
        configurationURL: URL,
        localVault: URL,
        localDirectory: URL,
        remoteVault: URL,
        remoteDirectory: URL,
        keyfile: URL
    ) -> DecodedConfiguration {
        DecodedConfiguration(
            global: DecodedGlobalConfiguration(
                keepassxc: "/usr/bin/true",
                fswatch: "/usr/bin/true",
                pushDebounce: 2,
                pullDebounce: 2,
                ignoreWindow: 5
            ),
            vaults: [
                DecodedVault(
                    id: UUID(
                        uuidString:
                            "00000000-0000-0000-0000-000000000001"
                    )!,
                    name: "personal",
                    enabled: false,
                    localPath: localVault.path,
                    localWatchPath: localDirectory.path,
                    remotePath: remoteVault.path,
                    remoteWatchPath: remoteDirectory.path,
                    keyfilePath: keyfile.path
                )
            ]
        )
    }
}
