import Foundation
import TOML

struct ConfigurationStore: ConfigurationStoring {
    let configurationURL: URL

    var exists: Bool {
        FileManager.default.fileExists(atPath: configurationURL.path)
    }

    func loadDecoded() throws -> DecodedConfiguration {
        let toml = try String(
            contentsOf: configurationURL,
            encoding: .utf8
        )

        let decoder = TOMLDecoder()

        return try decoder.decode(
            DecodedConfiguration.self,
            from: toml
        )
    }

    func save(_ configuration: DecodedConfiguration) throws {
        let encoder = TOMLEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        let data = try encoder.encode(configuration)

        try data.write(
            to: configurationURL,
            options: .atomic
        )
    }

    func initialize(_ configuration: DecodedConfiguration) throws {
        guard !exists else {
            throw ConfigurationError.configurationAlreadyExists
        }

        try FileManager.default.createDirectory(
            at: configurationURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        try save(configuration)
    }
}
