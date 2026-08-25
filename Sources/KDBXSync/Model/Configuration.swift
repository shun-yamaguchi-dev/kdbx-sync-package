import Foundation

struct GlobalConfiguration: Decodable {
    var keepassxc: URL
    var fswatch: URL

    var pushDebounce: Int
    var pullDebounce: Int
    var ignoreWindow: Int
}

struct Configuration: Decodable {
    var global: GlobalConfiguration
    var vaults: [Vault]
}
