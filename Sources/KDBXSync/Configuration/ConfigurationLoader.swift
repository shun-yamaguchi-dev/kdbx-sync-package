import Foundation
import TOML

struct ConfigurationLoader {
    let configurationURL: URL

    func load() throws -> Configuration {
        let toml = try String(
            contentsOf: configurationURL,
            encoding: .utf8
        )

        let decoder = TOMLDecoder()

        let decoded = try decoder.decode(
            DecodedConfiguration.self,
            from: toml
        )

        let validator = ConfigurationValidator()

        return try validator.validate(decoded)
    }
}
