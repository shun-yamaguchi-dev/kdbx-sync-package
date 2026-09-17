import Foundation

struct LaunchctlResult {
    let status: Int32
    let message: String
}

protocol LaunchctlRunning {
    func run(arguments: [String]) throws

    func inspect(arguments: [String]) throws -> LaunchctlResult
}

struct LaunchctlExecutor: LaunchctlRunning {
    private let executableURL: URL

    init(
        executableURL: URL = URL(fileURLWithPath: "/bin/launchctl")
    ) {
        self.executableURL = executableURL
    }

    func run(arguments: [String]) throws {
        let result = try execute(
            arguments: arguments
        )

        guard result.status == 0 else {
            throw LaunchdError.commandFailed(
                status: result.status,
                message: result.message
            )
        }
    }

    func inspect(arguments: [String]) throws -> LaunchctlResult {
        try execute(
            arguments: arguments
        )
    }

    private func execute(
        arguments: [String]
    ) throws -> LaunchctlResult {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments

        let errorPipe = Pipe()

        process.standardOutput = FileHandle.standardOutput
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let errorOutput = errorPipe.fileHandleForReading
            .readDataToEndOfFile()

        let message = String(
            data: errorOutput,
            encoding: .utf8
        )?
        .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? ""

        return LaunchctlResult(
            status: process.terminationStatus,
            message: message
        )
    }
}
