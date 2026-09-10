import Foundation
import TOML

let configurationURL = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".config/kdbx-sync/config.toml")

do {
    let store = ConfigurationStore(
        configurationURL: configurationURL
    )

    let loader = ConfigurationLoader(
        store: store
    )

    let configuration = try loader.load()

    print("KeepassXC: \(configuration.global.keepassxc.path)")
    print("fswatch: \(configuration.global.fswatch.path)")
    print("Push debounce: \(configuration.global.pushDebounce)")
    print("Pull debounce: \(configuration.global.pullDebounce)")
    print("Ignore window: \(configuration.global.ignoreWindow)")

    for vault in configuration.vaults {
        print("")
        print("Vault:")
        print("  ID: \(vault.id)")
        print("  Name: \(vault.name)")
        print("  Enabled: \(vault.enabled)")
        print("  Local: \(vault.localPath.path)")
        print("  Cloud: \(vault.cloudPath.path)")
        print("  Keyfile: \(vault.keyfilePath.path)")
    }

} catch {
    print("Failed to load configuration:")
    print("Configuration error: \(error.localizedDescription)")
    exit(1)
}
