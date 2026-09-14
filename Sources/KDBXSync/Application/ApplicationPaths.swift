import Foundation

struct ApplicationPaths {
    let bundleURL: URL

    init(bundleURL: URL = Bundle.main.bundleURL) {
        self.bundleURL = bundleURL
    }

    var runtimeDirectory: URL {
        bundleURL
            .appendingPathComponent("Contents")
            .appendingPathComponent("Resources")
            .appendingPathComponent("Runtime")
    }

    func runtimeScript(_ name: String) -> URL {
        runtimeDirectory.appendingPathComponent(name)
    }
}
