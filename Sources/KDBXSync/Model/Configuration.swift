import Foundation

struct DecodedGlobalConfiguration: Decodable {
    let keepassxc: String
    let fswatch: String

    let pushDebounce: Int
    let pullDebounce: Int
    let ignoreWindow: Int

    enum CodingKeys: String, CodingKey {
        case keepassxc
        case fswatch
        case pushDebounce = "push_debounce"
        case pullDebounce = "pull_debounce"
        case ignoreWindow = "ignore_window"
    }
}

struct DecodedConfiguration: Decodable {
    let global: DecodedGlobalConfiguration
    let vaults: [DecodedVault]
}

struct GlobalConfiguration {
    let keepassxc: URL
    let fswatch: URL

    let pushDebounce: Int
    let pullDebounce: Int
    let ignoreWindow: Int
}

struct Configuration {
    let global: GlobalConfiguration
    let vaults: [Vault]
}
