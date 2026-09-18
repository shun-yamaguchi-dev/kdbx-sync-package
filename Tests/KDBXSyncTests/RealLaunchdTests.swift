import Foundation
import XCTest
@testable import KDBXSync

final class RealLaunchdTests: XCTestCase {
    func testInstallAndRemoveRealLaunchAgents() throws {
        try requireRealLaunchdTestsEnabled()

        let temporaryDirectory = try makeTemporaryDirectory()

        defer {
            try? FileManager.default.removeItem(
                at: temporaryDirectory
            )
        }

        let launchAgentsDirectory = temporaryDirectory
            .appendingPathComponent("LaunchAgents")

        let stateDirectory = temporaryDirectory
            .appendingPathComponent("state")

        try FileManager.default.createDirectory(
            at: launchAgentsDirectory,
            withIntermediateDirectories: true
        )

        let vaultID = UUID()

        let vault = makeVault(
            id: vaultID,
            temporaryDirectory: temporaryDirectory
        )

        let applicationPaths = try makeApplicationPaths()

        let configuration = makeConfiguration(
            vault: vault
        )

        let manager = LaunchAgentManager(
            launchAgentsDirectory: launchAgentsDirectory,
            stateDirectory: stateDirectory
        )

        let pushLabel =
            "com.kdbx.push.\(vaultID.uuidString)"

        let pullLabel =
            "com.kdbx.pull.\(vaultID.uuidString)"

        defer {
            try? manager.remove(
                vault: vault
            )
        }

        XCTAssertFalse(
            try manager.isLoaded(
                label: pushLabel
            )
        )

        XCTAssertFalse(
            try manager.isLoaded(
                label: pullLabel
            )
        )

        try manager.install(
            vault: vault,
            configuration: configuration,
            applicationPaths: applicationPaths
        )

        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: manager.pushPlistURL(
                    for: vault
                ).path
            )
        )

        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: manager.pullPlistURL(
                    for: vault
                ).path
            )
        )

        XCTAssertTrue(
            try manager.isLoaded(
                label: pushLabel
            )
        )

        XCTAssertTrue(
            try manager.isLoaded(
                label: pullLabel
            )
        )

        try manager.remove(
            vault: vault
        )

        XCTAssertFalse(
            try manager.isLoaded(
                label: pushLabel
            )
        )

        XCTAssertFalse(
            try manager.isLoaded(
                label: pullLabel
            )
        )

        XCTAssertFalse(
            FileManager.default.fileExists(
                atPath: manager.pushPlistURL(
                    for: vault
                ).path
            )
        )

        XCTAssertFalse(
            FileManager.default.fileExists(
                atPath: manager.pullPlistURL(
                    for: vault
                ).path
            )
        )
    }

    func testReconcileConvergesRealLaunchdToDesiredState() throws {
        try requireRealLaunchdTestsEnabled()

        let temporaryDirectory = try makeTemporaryDirectory()

        defer {
            try? FileManager.default.removeItem(
                at: temporaryDirectory
            )
        }

        let launchAgentsDirectory = temporaryDirectory
            .appendingPathComponent("LaunchAgents")

        let stateDirectory = temporaryDirectory
            .appendingPathComponent("state")

        try FileManager.default.createDirectory(
            at: launchAgentsDirectory,
            withIntermediateDirectories: true
        )

        let vaultID = UUID()

        let vault = makeVault(
            id: vaultID,
            temporaryDirectory: temporaryDirectory
        )

        let applicationPaths = try makeApplicationPaths()

        let configuration = makeConfiguration(
            vault: vault
        )

        let manager = LaunchAgentManager(
            launchAgentsDirectory: launchAgentsDirectory,
            stateDirectory: stateDirectory
        )

        let pushLabel =
            "com.kdbx.push.\(vaultID.uuidString)"

        let pullLabel =
            "com.kdbx.pull.\(vaultID.uuidString)"

        defer {
            try? manager.remove(
                vault: vault
            )
        }

        // Initial state:
        // desired = enabled
        // actual  = absent
        XCTAssertFalse(
            try manager.isLoaded(
                label: pushLabel
            )
        )

        XCTAssertFalse(
            try manager.isLoaded(
                label: pullLabel
            )
        )

        try manager.reconcile(
            vault: vault,
            enabled: true,
            configuration: configuration,
            applicationPaths: applicationPaths
        )

        // Reconciliation should install both agents.
        XCTAssertTrue(
            try manager.isLoaded(
                label: pushLabel
            )
        )

        XCTAssertTrue(
            try manager.isLoaded(
                label: pullLabel
            )
        )

        // Desired state is still enabled and actual state is already
        // correct. A second reconciliation should therefore be a no-op.
        try manager.reconcile(
            vault: vault,
            enabled: true,
            configuration: configuration,
            applicationPaths: applicationPaths
        )

        XCTAssertTrue(
            try manager.isLoaded(
                label: pushLabel
            )
        )

        XCTAssertTrue(
            try manager.isLoaded(
                label: pullLabel
            )
        )

        // Change the desired state to disabled.
        // Reconciliation should remove both agents.
        try manager.reconcile(
            vault: vault,
            enabled: false,
            configuration: configuration,
            applicationPaths: applicationPaths
        )

        XCTAssertFalse(
            try manager.isLoaded(
                label: pushLabel
            )
        )

        XCTAssertFalse(
            try manager.isLoaded(
                label: pullLabel
            )
        )

        XCTAssertFalse(
            FileManager.default.fileExists(
                atPath: manager.pushPlistURL(
                    for: vault
                ).path
            )
        )

        XCTAssertFalse(
            FileManager.default.fileExists(
                atPath: manager.pullPlistURL(
                    for: vault
                ).path
            )
        )

        // Desired state is still disabled and actual state is already
        // correct. A second reconciliation should again be a no-op.
        try manager.reconcile(
            vault: vault,
            enabled: false,
            configuration: configuration,
            applicationPaths: applicationPaths
        )

        XCTAssertFalse(
            try manager.isLoaded(
                label: pushLabel
            )
        )

        XCTAssertFalse(
            try manager.isLoaded(
                label: pullLabel
            )
        )
    }

    private func requireRealLaunchdTestsEnabled() throws {
        guard ProcessInfo.processInfo.environment[
            "KDBX_SYNC_REAL_LAUNCHD_TESTS"
        ] == "1" else {
            throw XCTSkip(
                """
                Real launchd integration tests are disabled. \
                Set KDBX_SYNC_REAL_LAUNCHD_TESTS=1 to enable them.
                """
            )
        }
    }

    private func makeApplicationPaths() throws -> ApplicationPaths {
        let applicationPaths = ApplicationPaths(
            bundleURL: URL(
                fileURLWithPath:
                    "\(NSHomeDirectory())/Applications/KDBX Sync.app"
            )
        )

        try applicationPaths.validateRuntime()

        return applicationPaths
    }

    private func makeConfiguration(
        vault: Vault
    ) -> Configuration {
        Configuration(
            global: GlobalConfiguration(
                keepassxc: URL(
                    fileURLWithPath: "/usr/bin/true"
                ),
                fswatch: URL(
                    fileURLWithPath: "/usr/bin/true"
                ),
                pushDebounce: 0,
                pullDebounce: 0,
                ignoreWindow: 0
            ),
            vaults: [vault]
        )
    }

    private func makeVault(
        id: UUID,
        temporaryDirectory: URL
    ) -> Vault {
        Vault(
            id: id,
            name: "real-launchd-test",
            enabled: true,
            localPath: temporaryDirectory
                .appendingPathComponent("local.kdbx"),
            localWatchPath: temporaryDirectory,
            remotePath: temporaryDirectory
                .appendingPathComponent("remote.kdbx"),
            remoteWatchPath: temporaryDirectory,
            keyfilePath: temporaryDirectory
                .appendingPathComponent("keyfile")
        )
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "KDBXSyncRealLaunchdTests-\(UUID().uuidString)"
            )

        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        return directory
    }
}
