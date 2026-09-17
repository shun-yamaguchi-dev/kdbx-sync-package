import Foundation
import Testing
@testable import KDBXSync

struct LaunchAgentManagerTests {
    @Test
    func printSuccessMeansAgentIsLoaded() throws {
        let launchctl = RecordingLaunchctl(
            inspectStatuses: [
                "com.kdbx.push.test": 0
            ]
        )

        let manager = LaunchAgentManager(
            launchAgentsDirectory: temporaryDirectory,
            launchctl: launchctl
        )

        let loaded = try manager.isLoaded(
            label: "com.kdbx.push.test"
        )

        #expect(loaded == true)
        #expect(
            launchctl.inspectedArguments == [
                [
                    "print",
                    "gui/\(getuid())/com.kdbx.push.test"
                ]
            ]
        )
    }

    @Test
    func printStatus113MeansAgentIsNotLoaded() throws {
        let launchctl = RecordingLaunchctl(
            inspectStatuses: [
                "com.kdbx.push.test": 113
            ]
        )

        let manager = LaunchAgentManager(
            launchAgentsDirectory: temporaryDirectory,
            launchctl: launchctl
        )

        let loaded = try manager.isLoaded(
            label: "com.kdbx.push.test"
        )

        #expect(loaded == false)
    }

    @Test
    func unexpectedPrintFailureIsPropagated() throws {
        let launchctl = RecordingLaunchctl(
            inspectStatuses: [
                "com.kdbx.push.test": 1
            ]
        )

        let manager = LaunchAgentManager(
            launchAgentsDirectory: temporaryDirectory,
            launchctl: launchctl
        )

        #expect(throws: LaunchdError.self) {
            try manager.isLoaded(
                label: "com.kdbx.push.test"
            )
        }
    }

    @Test
    func reconcileEnabledVaultWithBothAgentsLoadedDoesNothing() throws {
        let launchctl = RecordingLaunchctl(
            inspectStatuses: [
                pushLabel: 0,
                pullLabel: 0
            ]
        )

        let manager = LaunchAgentManager(
            launchAgentsDirectory: temporaryDirectory,
            launchctl: launchctl
        )

        try manager.reconcile(
            vault: makeVault(),
            enabled: true,
            configuration: makeConfiguration(),
            applicationPaths: makeApplicationPaths()
        )

        #expect(launchctl.runArguments.isEmpty)
    }

    @Test
    func reconcileEnabledVaultWithMissingPushInstallsOnlyPush() throws {
        let launchctl = RecordingLaunchctl(
            inspectStatuses: [
                pushLabel: 113,
                pullLabel: 0
            ]
        )

        let manager = LaunchAgentManager(
            launchAgentsDirectory: temporaryDirectory,
            launchctl: launchctl
        )

        try manager.reconcile(
            vault: makeVault(),
            enabled: true,
            configuration: makeConfiguration(),
            applicationPaths: makeApplicationPaths()
        )

        #expect(
            launchctl.runArguments == [
                [
                    "bootstrap",
                    "gui/\(getuid())",
                    manager.pushPlistURL(for: makeVault()).path
                ]
            ]
        )
    }

    @Test
    func reconcileEnabledVaultWithMissingPullInstallsOnlyPull() throws {
        let launchctl = RecordingLaunchctl(
            inspectStatuses: [
                pushLabel: 0,
                pullLabel: 113
            ]
        )

        let manager = LaunchAgentManager(
            launchAgentsDirectory: temporaryDirectory,
            launchctl: launchctl
        )

        try manager.reconcile(
            vault: makeVault(),
            enabled: true,
            configuration: makeConfiguration(),
            applicationPaths: makeApplicationPaths()
        )

        #expect(
            launchctl.runArguments == [
                [
                    "bootstrap",
                    "gui/\(getuid())",
                    manager.pullPlistURL(for: makeVault()).path
                ]
            ]
        )
    }

    @Test
    func reconcileEnabledVaultWithBothAgentsMissingInstallsBoth() throws {
        let launchctl = RecordingLaunchctl(
            inspectStatuses: [
                pushLabel: 113,
                pullLabel: 113
            ]
        )

        let manager = LaunchAgentManager(
            launchAgentsDirectory: temporaryDirectory,
            launchctl: launchctl
        )

        try manager.reconcile(
            vault: makeVault(),
            enabled: true,
            configuration: makeConfiguration(),
            applicationPaths: makeApplicationPaths()
        )

        #expect(
            launchctl.runArguments == [
                [
                    "bootstrap",
                    "gui/\(getuid())",
                    manager.pushPlistURL(for: makeVault()).path
                ],
                [
                    "bootstrap",
                    "gui/\(getuid())",
                    manager.pullPlistURL(for: makeVault()).path
                ]
            ]
        )
    }

    @Test
    func reconcileDisabledVaultWithBothAgentsMissingDoesNothing() throws {
        let launchctl = RecordingLaunchctl(
            inspectStatuses: [
                pushLabel: 113,
                pullLabel: 113
            ]
        )

        let manager = LaunchAgentManager(
            launchAgentsDirectory: temporaryDirectory,
            launchctl: launchctl
        )

        try manager.reconcile(
            vault: makeVault(),
            enabled: false,
            configuration: makeConfiguration(),
            applicationPaths: makeApplicationPaths()
        )

        #expect(launchctl.runArguments.isEmpty)
    }

    @Test
    func reconcileDisabledVaultWithOnlyPushLoadedRemovesOnlyPush() throws {
        let launchctl = RecordingLaunchctl(
            inspectStatuses: [
                pushLabel: 0,
                pullLabel: 113
            ]
        )

        let manager = LaunchAgentManager(
            launchAgentsDirectory: temporaryDirectory,
            launchctl: launchctl
        )

        try manager.reconcile(
            vault: makeVault(),
            enabled: false,
            configuration: makeConfiguration(),
            applicationPaths: makeApplicationPaths()
        )

        #expect(
            launchctl.runArguments == [
                [
                    "bootout",
                    "gui/\(getuid())/\(pushLabel)"
                ]
            ]
        )
    }

    @Test
    func reconcileDisabledVaultWithOnlyPullLoadedRemovesOnlyPull() throws {
        let launchctl = RecordingLaunchctl(
            inspectStatuses: [
                pushLabel: 113,
                pullLabel: 0
            ]
        )

        let manager = LaunchAgentManager(
            launchAgentsDirectory: temporaryDirectory,
            launchctl: launchctl
        )

        try manager.reconcile(
            vault: makeVault(),
            enabled: false,
            configuration: makeConfiguration(),
            applicationPaths: makeApplicationPaths()
        )

        #expect(
            launchctl.runArguments == [
                [
                    "bootout",
                    "gui/\(getuid())/\(pullLabel)"
                ]
            ]
        )
    }

    @Test
    func reconcileDisabledVaultWithBothAgentsLoadedRemovesBoth() throws {
        let launchctl = RecordingLaunchctl(
            inspectStatuses: [
                pushLabel: 0,
                pullLabel: 0
            ]
        )

        let manager = LaunchAgentManager(
            launchAgentsDirectory: temporaryDirectory,
            launchctl: launchctl
        )

        try manager.reconcile(
            vault: makeVault(),
            enabled: false,
            configuration: makeConfiguration(),
            applicationPaths: makeApplicationPaths()
        )

        #expect(
            launchctl.runArguments == [
                [
                    "bootout",
                    "gui/\(getuid())/\(pushLabel)"
                ],
                [
                    "bootout",
                    "gui/\(getuid())/\(pullLabel)"
                ]
            ]
        )
    }

    private var temporaryDirectory: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "KDBXSyncTests-\(UUID().uuidString)"
            )
    }

    private var pushLabel: String {
        "com.kdbx.push.\(vaultID.uuidString)"
    }

    private var pullLabel: String {
        "com.kdbx.pull.\(vaultID.uuidString)"
    }

    private var vaultID: UUID {
        UUID(
            uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"
        )!
    }

    private func makeVault() -> Vault {
        Vault(
            id: vaultID,
            name: "test",
            enabled: false,
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

    private func makeConfiguration() -> Configuration {
        Configuration(
            global: GlobalConfiguration(
                keepassxc: URL(
                    fileURLWithPath: "/usr/local/bin/keepassxc"
                ),
                fswatch: URL(
                    fileURLWithPath: "/usr/local/bin/fswatch"
                ),
                pushDebounce: 2,
                pullDebounce: 2,
                ignoreWindow: 5
            ),
            vaults: []
        )
    }

    private func makeApplicationPaths() -> ApplicationPaths {
        ApplicationPaths(
            bundleURL: temporaryDirectory
        )
    }
}

private final class RecordingLaunchctl: LaunchctlRunning {
    private let inspectStatuses: [String: Int32]

    private(set) var inspectedArguments: [[String]] = []
    private(set) var runArguments: [[String]] = []

    init(inspectStatuses: [String: Int32]) {
        self.inspectStatuses = inspectStatuses
    }

    func run(arguments: [String]) throws {
        runArguments.append(arguments)
    }

    func inspect(arguments: [String]) throws -> LaunchctlResult {
        inspectedArguments.append(arguments)

        guard let label = arguments.last?
            .split(separator: "/")
            .last
            .map(String.init) else {
            fatalError("Expected launchctl print target.")
        }

        let status = inspectStatuses[label] ?? 113

        return LaunchctlResult(
            status: status,
            message: status == 0
                ? ""
                : "Could not find service."
        )
    }
}
