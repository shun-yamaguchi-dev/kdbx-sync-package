import Foundation

struct DecodedVault: Decodable {
    let id: UUID
    let name: String
    let enabled: Bool

    let localPath: String
    let localWatchPath: String

    let cloudPath: String
    let cloudWatchPath: String

    let keyfilePath: String

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
    let id: UUID
    let name: String
    let enabled: Bool

    let localPath: URL
    let localWatchPath: URL

    let cloudPath: URL
    let cloudWatchPath: URL

    let keyfilePath: URL
}
