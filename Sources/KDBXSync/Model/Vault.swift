import Foundation

struct DecodedVault: Codable {
    var id: UUID
    var name: String
    var enabled: Bool

    var localPath: String
    var localWatchPath: String

    var remotePath: String
    var remoteWatchPath: String

    var keyfilePath: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case enabled

        case localPath = "local_path"
        case localWatchPath = "local_watch_path"

        case remotePath = "remote_path"
        case remoteWatchPath = "remote_watch_path"

        case keyfilePath = "keyfile_path"
    }
}

struct Vault {
    var id: UUID
    var name: String
    var enabled: Bool

    var localPath: URL
    var localWatchPath: URL

    var remotePath: URL
    var remoteWatchPath: URL

    var keyfilePath: URL
}
