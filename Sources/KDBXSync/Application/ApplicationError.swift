import Foundation

enum ApplicationError: Error, LocalizedError {
    case runtimeResourceMissing(URL)

    var errorDescription: String? {
        switch self {
        case let .runtimeResourceMissing(url):
            return """
            Required application runtime resource is missing or not executable: \(url.path)
            """
        }
    }
}
