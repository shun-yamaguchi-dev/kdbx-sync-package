import Foundation

struct Vault: Decodable {
    let id: UUID
    var name: String
    var enabled: Bool
    
    let localPath: URL
    let localWatchPath: URL

    let cloudPath: URL
    let cloudWatchPath: URL

    let keyfilePath: URL
}
