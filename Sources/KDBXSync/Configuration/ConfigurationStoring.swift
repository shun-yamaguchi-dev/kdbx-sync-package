import Foundation

protocol ConfigurationStoring {
    var exists: Bool { get }

    func loadDecoded() throws -> DecodedConfiguration

    func save(
        _ configuration: DecodedConfiguration
    ) throws

    func initialize(
        _ configuration: DecodedConfiguration
    ) throws
}
