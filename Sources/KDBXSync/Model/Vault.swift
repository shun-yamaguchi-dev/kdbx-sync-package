import Foundation

struct DecodedVault: Codable {
    var id: UUID
    var name: String
    var enabled: Bool

    var localPath: String
    var localWatchPath: String

    var cloudPath: String
    var cloudWatchPath: String

    var keyfilePath: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case enabled

        case localPath = "local_path"
        case localWatchPath = "local_watch_path"

        case cloudPath = "cloud_path"
        case cloudWatchPath = "cloud_watch_path"

        case keyfilePath = "keyfile_path"
    }
}

struct Vault {
    var id: UUID
    var name: String
    var enabled: Bool

    var localPath: URL
    var localWatchPath: URL

    var cloudPath: URL
    var cloudWatchPath: URL

    var keyfilePath: URL
}
