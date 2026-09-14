import Foundation

struct LaunchAgentGenerator {
    func generatePush(
        vault: Vault,
        configuration: Configuration,
        applicationPaths: ApplicationPaths
    ) throws -> Data {
        let agent = LaunchAgent(
            label: "com.kdbx.push.\(vault.id.uuidString)",
            program: applicationPaths.runtimeScript("kdbx-push-runner.sh").path,
            arguments: [
                "--id",
                vault.id.uuidString,
                "--watch-path",
                vault.localWatchPath.path,
                "--fswatch",
                configuration.global.fswatch.path,
                "--debounce",
                String(configuration.global.pushDebounce),
                "--ignore-window",
                String(configuration.global.ignoreWindow),
                "--state-dir",
                stateDirectory(for: vault).path,
                "--operation",
                applicationPaths.runtimeScript("kdbx-push.sh").path,
                "--local-path",
                vault.localPath.path,
                "--remote-path",
                vault.remotePath.path,
                "--keyfile-path",
                vault.keyfilePath.path,
                "--keepassxc",
                configuration.global.keepassxc.path
            ],
            runAtLoad: true
        )

        return try generate(agent)
    }

    func generatePull(
        vault: Vault,
        configuration: Configuration,
        applicationPaths: ApplicationPaths
    ) throws -> Data {
        let agent = LaunchAgent(
            label: "com.kdbx.pull.\(vault.id.uuidString)",
            program: applicationPaths.runtimeScript("kdbx-pull-runner.sh").path,
            arguments: [
                "--id",
                vault.id.uuidString,
                "--watch-path",
                vault.remoteWatchPath.path,
                "--fswatch",
                configuration.global.fswatch.path,
                "--debounce",
                String(configuration.global.pullDebounce),
                "--ignore-window",
                String(configuration.global.ignoreWindow),
                "--state-dir",
                stateDirectory(for: vault).path,
                "--operation",
                applicationPaths.runtimeScript("kdbx-pull.sh").path,
                "--local-path",
                vault.localPath.path,
                "--remote-path",
                vault.remotePath.path,
                "--keyfile-path",
                vault.keyfilePath.path,
                "--keepassxc",
                configuration.global.keepassxc.path
            ],
            runAtLoad: true
        )

        return try generate(agent)
    }

    private func generate(_ agent: LaunchAgent) throws -> Data {
        let dictionary = agent.plistDictionary()

        guard PropertyListSerialization.propertyList(
            dictionary,
            isValidFor: .xml
        ) else {
            throw LaunchdError.plistSerializationFailed
        }

        return try PropertyListSerialization.data(
            fromPropertyList: dictionary,
            format: .xml,
            options: 0
        )
    }

    private func stateDirectory(for vault: Vault) -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".local/state/kdbx-sync")
            .appendingPathComponent(vault.id.uuidString)
    }
}
