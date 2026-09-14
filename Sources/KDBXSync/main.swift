import Foundation

do {
    let application = Application()

    try application.run(
        arguments: CommandLine.arguments.dropFirst()
    )
} catch {
    print("Error: \(error.localizedDescription)")
    exit(1)
}
