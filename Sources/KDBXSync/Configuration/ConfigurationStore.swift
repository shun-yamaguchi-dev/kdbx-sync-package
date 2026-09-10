import Foundation
import TOML

struct ConfigurationStore {
    let configurationURL: URL

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

        let temporaryURL = configurationURL
            .deletingLastPathComponent()
            .appendingPathComponent(
                ".\(configurationURL.lastPathComponent).tmp"
            )

        try data.write(
            to: temporaryURL,
            options: .atomic
        )

        _ = try FileManager.default.replaceItemAt(
            configurationURL,
            withItemAt: temporaryURL
        )
    }
}
