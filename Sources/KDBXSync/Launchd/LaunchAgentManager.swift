import Foundation

struct LaunchAgentManager: LaunchAgentManaging {
    private let launchAgentsDirectory: URL
    private let launchctl: LaunchctlRunning

    init(
        launchAgentsDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents"),
        launchctl: LaunchctlRunning = LaunchctlExecutor()
    ) {
        self.launchAgentsDirectory = launchAgentsDirectory
        self.launchctl = launchctl
    }

    private var launchdDomain: String {
        "gui/\(getuid())"
    }

    private func plistURL(label: String) -> URL {
        launchAgentsDirectory
            .appendingPathComponent("\(label).plist")
    }

    func pushPlistURL(for vault: Vault) -> URL {
        plistURL(
            label: "com.kdbx.push.\(vault.id.uuidString)"
        )
    }

    func pullPlistURL(for vault: Vault) -> URL {
        plistURL(
            label: "com.kdbx.pull.\(vault.id.uuidString)"
        )
    }

    func isLoaded(label: String) throws -> Bool {
        let result = try launchctl.inspect(
            arguments: [
                "print",
                "\(launchdDomain)/\(label)"
            ]
        )

        switch result.status {
        case 0:
            return true

        case 113:
            return false

        default:
            throw LaunchdError.commandFailed(
                status: result.status,
                message: result.message
            )
        }
    }

    func reconcile(
        vault: Vault,
        enabled: Bool,
        configuration: Configuration,
        applicationPaths: ApplicationPaths
    ) throws {
        let pushLabel = "com.kdbx.push.\(vault.id.uuidString)"
        let pullLabel = "com.kdbx.pull.\(vault.id.uuidString)"

        let pushLoaded = try isLoaded(
            label: pushLabel
        )

        let pullLoaded = try isLoaded(
            label: pullLabel
        )

        if enabled {
            if !pushLoaded {
                try installPush(
                    vault: vault,
                    configuration: configuration,
                    applicationPaths: applicationPaths
                )
            }

            if !pullLoaded {
                try installPull(
                    vault: vault,
                    configuration: configuration,
                    applicationPaths: applicationPaths
                )
            }
        } else {
            if pushLoaded {
                try bootout(
                    label: pushLabel
                )
            }

            if pullLoaded {
                try bootout(
                    label: pullLabel
                )
            }
        }
    }

    func install(
        vault: Vault,
        configuration: Configuration,
        applicationPaths: ApplicationPaths
    ) throws {
        try FileManager.default.createDirectory(
            at: launchAgentsDirectory,
            withIntermediateDirectories: true
        )

        do {
            try installPush(
                vault: vault,
                configuration: configuration,
                applicationPaths: applicationPaths
            )

            try installPull(
                vault: vault,
                configuration: configuration,
                applicationPaths: applicationPaths
            )
        } catch {
            let installationError = error

            do {
                try remove(vault: vault)
            } catch {
                throw LaunchdError.installationRollbackFailed(
                    installationError: installationError,
                    rollbackError: error
                )
            }

            throw installationError
        }
    }

    func remove(vault: Vault) throws {
        var firstError: Error?

        do {
            try bootout(
                label: "com.kdbx.push.\(vault.id.uuidString)"
            )
        } catch {
            firstError = error
        }

        do {
            try bootout(
                label: "com.kdbx.pull.\(vault.id.uuidString)"
            )
        } catch {
            if firstError == nil {
                firstError = error
            }
        }

        do {
            try removePlist(
                at: pushPlistURL(for: vault)
            )
        } catch {
            if firstError == nil {
                firstError = error
            }
        }

        do {
            try removePlist(
                at: pullPlistURL(for: vault)
            )
        } catch {
            if firstError == nil {
                firstError = error
            }
        }

        if let firstError {
            throw firstError
        }
    }

    private func installPush(
        vault: Vault,
        configuration: Configuration,
        applicationPaths: ApplicationPaths
    ) throws {
        try FileManager.default.createDirectory(
            at: launchAgentsDirectory,
            withIntermediateDirectories: true
        )

        let generator = LaunchAgentGenerator()

        let data = try generator.generatePush(
            vault: vault,
            configuration: configuration,
            applicationPaths: applicationPaths
        )

        let url = pushPlistURL(for: vault)

        try data.write(
            to: url,
            options: .atomic
        )

        try launchctl.run(
            arguments: [
                "bootstrap",
                launchdDomain,
                url.path
            ]
        )
    }

    private func installPull(
        vault: Vault,
        configuration: Configuration,
        applicationPaths: ApplicationPaths
    ) throws {
        try FileManager.default.createDirectory(
            at: launchAgentsDirectory,
            withIntermediateDirectories: true
        )

        let generator = LaunchAgentGenerator()

        let data = try generator.generatePull(
            vault: vault,
            configuration: configuration,
            applicationPaths: applicationPaths
        )

        let url = pullPlistURL(for: vault)

        try data.write(
            to: url,
            options: .atomic
        )

        try launchctl.run(
            arguments: [
                "bootstrap",
                launchdDomain,
                url.path
            ]
        )
    }

    private func bootout(label: String) throws {
        do {
            try launchctl.run(
                arguments: [
                    "bootout",
                    "\(launchdDomain)/\(label)"
                ]
            )
        } catch let error as LaunchdError {
            if case let .commandFailed(status, _) = error,
               status == 3 {
                return
            }

            throw error
        }
    }

    private func removePlist(at url: URL) throws {
        do {
            try FileManager.default.removeItem(at: url)
        } catch let error as CocoaError
            where error.code == .fileNoSuchFile {
            return
        }
    }
}
