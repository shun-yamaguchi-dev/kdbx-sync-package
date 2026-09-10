import Foundation

struct DecodedGlobalConfiguration: Codable {
    var keepassxc: String
    var fswatch: String

    var pushDebounce: Int
    var pullDebounce: Int
    var ignoreWindow: Int

    enum CodingKeys: String, CodingKey {
        case keepassxc
        case fswatch
        case pushDebounce = "push_debounce"
        case pullDebounce = "pull_debounce"
        case ignoreWindow = "ignore_window"
    }
}

struct DecodedConfiguration: Codable {
    var global: DecodedGlobalConfiguration
    var vaults: [DecodedVault]
}

struct GlobalConfiguration {
    var keepassxc: URL
    var fswatch: URL

    var pushDebounce: Int
    var pullDebounce: Int
    var ignoreWindow: Int
}

struct Configuration {
    var global: GlobalConfiguration
    var vaults: [Vault]
}
