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

    func validateRuntime() throws {
        let requiredScripts = [
            "kdbx-push-runner.sh",
            "kdbx-push.sh",
            "kdbx-pull-runner.sh",
            "kdbx-pull.sh"
        ]

        for script in requiredScripts {
            let url = runtimeScript(script)

            guard FileManager.default.isExecutableFile(
                atPath: url.path
            ) else {
                throw ApplicationError.runtimeResourceMissing(url)
            }
        }
    }
}
