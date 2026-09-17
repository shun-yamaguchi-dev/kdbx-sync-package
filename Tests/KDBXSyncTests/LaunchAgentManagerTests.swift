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

    @Test
    func installWritesBothPlistsAndBootstrapsBothAgents() throws {
        let directory = try makeTemporaryDirectory()

        defer {
            try? FileManager.default.removeItem(
                at: directory
            )
        }

        let launchctl = RecordingLaunchctl(
            inspectStatuses: [:]
        )

        let manager = LaunchAgentManager(
            launchAgentsDirectory: directory,
            launchctl: launchctl
        )

        let vault = makeVault(
            in: directory
        )

        try manager.install(
            vault: vault,
            configuration: makeConfiguration(),
            applicationPaths: makeApplicationPaths(
                in: directory
            )
        )

        let pushPlistURL = manager.pushPlistURL(
            for: vault
        )

        let pullPlistURL = manager.pullPlistURL(
            for: vault
        )

        #expect(
            FileManager.default.fileExists(
                atPath: pushPlistURL.path
            )
        )

        #expect(
            FileManager.default.fileExists(
                atPath: pullPlistURL.path
            )
        )

        let pushPlist = try readPlist(
            at: pushPlistURL
        )

        let pullPlist = try readPlist(
            at: pullPlistURL
        )

        #expect(
            pushPlist["Label"] as? String == pushLabel
        )

        #expect(
            pullPlist["Label"] as? String == pullLabel
        )

        #expect(
            launchctl.runArguments == [
                [
                    "bootstrap",
                    "gui/\(getuid())",
                    pushPlistURL.path
                ],
                [
                    "bootstrap",
                    "gui/\(getuid())",
                    pullPlistURL.path
                ]
            ]
        )
    }

        @Test
    func installRollsBackWhenPullBootstrapFails() throws {
        let directory = try makeTemporaryDirectory()

        defer {
            try? FileManager.default.removeItem(
                at: directory
            )
        }

        let vault = makeVault(
            in: directory
        )

        let pushPlistURL = directory
            .appendingPathComponent(
                "\(pushLabel).plist"
            )

        let pullPlistURL = directory
            .appendingPathComponent(
                "\(pullLabel).plist"
            )

        let pullBootstrapArguments = [
            "bootstrap",
            "gui/\(getuid())",
            pullPlistURL.path
        ]

        let launchctl = RecordingLaunchctl(
            inspectStatuses: [:],
            runResults: [
                pullBootstrapArguments: .failure(
                    LaunchdError.commandFailed(
                        status: 5,
                        message: "Simulated pull bootstrap failure."
                    )
                )
            ]
        )

        let manager = LaunchAgentManager(
            launchAgentsDirectory: directory,
            launchctl: launchctl
        )

        #expect(throws: LaunchdError.self) {
            try manager.install(
                vault: vault,
                configuration: makeConfiguration(),
                applicationPaths: makeApplicationPaths(
                    in: directory
                )
            )
        }

        #expect(
            !FileManager.default.fileExists(
                atPath: pushPlistURL.path
            )
        )

        #expect(
            !FileManager.default.fileExists(
                atPath: pullPlistURL.path
            )
        )

        #expect(
            launchctl.runArguments == [
                [
                    "bootstrap",
                    "gui/\(getuid())",
                    pushPlistURL.path
                ],
                pullBootstrapArguments,
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

    @Test
    func removeDeletesBothPlists() throws {
        let directory = try makeTemporaryDirectory()

        defer {
            try? FileManager.default.removeItem(
                at: directory
            )
        }

        let launchctl = RecordingLaunchctl(
            inspectStatuses: [
                pushLabel: 0,
                pullLabel: 0
            ]
        )

        let manager = LaunchAgentManager(
            launchAgentsDirectory: directory,
            launchctl: launchctl
        )

        let vault = makeVault(
            in: directory
        )

        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        try Data().write(
            to: manager.pushPlistURL(for: vault)
        )

        try Data().write(
            to: manager.pullPlistURL(for: vault)
        )

        try manager.remove(
            vault: vault
        )

        #expect(
            !FileManager.default.fileExists(
                atPath: manager.pushPlistURL(for: vault).path
            )
        )

        #expect(
            !FileManager.default.fileExists(
                atPath: manager.pullPlistURL(for: vault).path
            )
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

        @Test
    func removeTreatsBootoutStatus3AsAlreadyAbsent() throws {
        let directory = try makeTemporaryDirectory()

        defer {
            try? FileManager.default.removeItem(
                at: directory
            )
        }

        let launchctl = RecordingLaunchctl(
            inspectStatuses: [:],
            runResults: [
                [
                    "bootout",
                    "gui/\(getuid())/\(pushLabel)"
                ]: .failure(
                    LaunchdError.commandFailed(
                        status: 3,
                        message: "Could not find service."
                    )
                ),
                [
                    "bootout",
                    "gui/\(getuid())/\(pullLabel)"
                ]: .failure(
                    LaunchdError.commandFailed(
                        status: 3,
                        message: "Could not find service."
                    )
                )
            ]
        )

        let manager = LaunchAgentManager(
            launchAgentsDirectory: directory,
            launchctl: launchctl
        )

        let vault = makeVault(
            in: directory
        )

        let pushPlistURL = manager.pushPlistURL(
            for: vault
        )

        let pullPlistURL = manager.pullPlistURL(
            for: vault
        )

        try Data().write(
            to: pushPlistURL
        )

        try Data().write(
            to: pullPlistURL
        )

        try manager.remove(
            vault: vault
        )

        #expect(
            !FileManager.default.fileExists(
                atPath: pushPlistURL.path
            )
        )

        #expect(
            !FileManager.default.fileExists(
                atPath: pullPlistURL.path
            )
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

    private func makeVault(
        in directory: URL? = nil
    ) -> Vault {
        let directory = directory ?? temporaryDirectory

        return Vault(
            id: vaultID,
            name: "test",
            enabled: false,
            localPath: directory
                .appendingPathComponent("local.kdbx"),
            localWatchPath: directory,
            remotePath: directory
                .appendingPathComponent("remote.kdbx"),
            remoteWatchPath: directory,
            keyfilePath: directory
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

    private func makeApplicationPaths(
        in directory: URL? = nil
    ) -> ApplicationPaths {
        ApplicationPaths(
            bundleURL: directory ?? temporaryDirectory
        )
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "KDBXSyncTests-\(UUID().uuidString)"
            )

        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        return directory
    }

    private func readPlist(
        at url: URL
    ) throws -> [String: Any] {
        let data = try Data(
            contentsOf: url
        )

        return try #require(
            PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            ) as? [String: Any]
        )
    }
}

private final class RecordingLaunchctl: LaunchctlRunning {
    private let inspectStatuses: [String: Int32]
    private var runResults: [[String]: Result<Void, LaunchdError>]

    private(set) var inspectedArguments: [[String]] = []
    private(set) var runArguments: [[String]] = []

    init(
        inspectStatuses: [String: Int32],
        runResults: [[String]: Result<Void, LaunchdError>] = [:]
    ) {
        self.inspectStatuses = inspectStatuses
        self.runResults = runResults
    }

    func run(
        arguments: [String]
    ) throws {
        runArguments.append(arguments)

        guard let result = runResults[arguments] else {
            return
        }

        switch result {
        case .success:
            return

        case let .failure(error):
            throw error
        }
    }

    func inspect(
        arguments: [String]
    ) throws -> LaunchctlResult {
        inspectedArguments.append(arguments)

        guard let label = arguments.last?
            .split(separator: "/")
            .last
            .map(String.init) else {
            fatalError(
                "Expected launchctl print target."
            )
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
