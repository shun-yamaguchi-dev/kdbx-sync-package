import Foundation

struct LaunchAgent {
    let label: String
    let program: String
    let arguments: [String]
    let runAtLoad: Bool

    func plistDictionary() -> [String: Any] {
        [
            "Label": label,
            "ProgramArguments": [program] + arguments,
            "RunAtLoad": runAtLoad
        ]
    }
}
