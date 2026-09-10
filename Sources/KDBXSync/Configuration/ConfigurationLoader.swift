import Foundation

struct ConfigurationLoader {
    let store: ConfigurationStore

    func load() throws -> Configuration {
        let decoded = try store.loadDecoded()

        let validator = ConfigurationValidator()

        return try validator.validate(decoded)
    }
}
