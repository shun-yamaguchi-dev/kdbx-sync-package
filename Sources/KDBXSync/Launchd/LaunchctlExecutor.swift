import Foundation

protocol LaunchctlRunning {
    func run(arguments: [String]) throws
}

struct LaunchctlExecutor: LaunchctlRunning {
    private let executableURL: URL

    init(
        executableURL: URL = URL(fileURLWithPath: "/bin/launchctl")
    ) {
        self.executableURL = executableURL
    }

    func run(arguments: [String]) throws {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments

        let errorPipe = Pipe()

        process.standardOutput = FileHandle.standardOutput
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errorOutput = errorPipe.fileHandleForReading.readDataToEndOfFile()

            let message = String(
                data: errorOutput,
                encoding: .utf8
            )?
            .trimmingCharacters(in: .whitespacesAndNewlines)

            throw LaunchdError.commandFailed(
                status: process.terminationStatus,
                message: message ?? "launchctl failed."
            )
        }
    }
}
