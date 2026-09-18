import Foundation

do {
    let application = Application()

    if CommandLine.arguments.count == 1 {
        try application.runStartup()
    } else {
        try application.run(
            arguments: CommandLine.arguments.dropFirst()
        )
    }
} catch {
    print("Error: \(error.localizedDescription)")
    exit(1)
}
