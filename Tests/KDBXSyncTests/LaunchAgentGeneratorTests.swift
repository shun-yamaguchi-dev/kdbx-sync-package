import Foundation
import XCTest
@testable import KDBXSync

final class LaunchAgentGeneratorTests: XCTestCase {
    func testPushAgentContainsExpectedProgramArguments() throws {
        let vault = Vault(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "personal",
            enabled: false,
            localPath: URL(fileURLWithPath: "/vault/local.kdbx"),
            localWatchPath: URL(fileURLWithPath: "/vault"),
            remotePath: URL(fileURLWithPath: "/remote/remote.kdbx"),
            remoteWatchPath: URL(fileURLWithPath: "/remote"),
            keyfilePath: URL(fileURLWithPath: "/keys/vault.key")
        )
        let configuration = Configuration(
            global: GlobalConfiguration(
                keepassxc: URL(fileURLWithPath: "/usr/local/bin/keepassxc"),
                fswatch: URL(fileURLWithPath: "/usr/local/bin/fswatch"),
                pushDebounce: 2,
                pullDebounce: 3,
                ignoreWindow: 5
            ),
            vaults: [vault]
        )
        let paths = ApplicationPaths(
            bundleURL: URL(fileURLWithPath: "/Applications/KDBX Sync.app")
        )

        let data = try LaunchAgentGenerator().generatePush(
            vault: vault,
            configuration: configuration,
            applicationPaths: paths
        )
        let plist = try XCTUnwrap(
            PropertyListSerialization.propertyList(
                from: data,
                format: nil
            ) as? [String: Any]
        )
        let arguments = try XCTUnwrap(plist["ProgramArguments"] as? [String])

        XCTAssertEqual(
            plist["Label"] as? String,
            "com.kdbx.push.00000000-0000-0000-0000-000000000001"
        )
        XCTAssertEqual(
            arguments.first,
            "/Applications/KDBX Sync.app/Contents/Resources/Runtime/kdbx-push-runner.sh"
        )
        XCTAssertTrue(arguments.contains("--local-path"))
        XCTAssertTrue(arguments.contains("/vault/local.kdbx"))
        XCTAssertTrue(arguments.contains("--remote-path"))
        XCTAssertTrue(arguments.contains("/remote/remote.kdbx"))
        XCTAssertTrue(arguments.contains("--debounce"))
        XCTAssertTrue(arguments.contains("2"))
    }
}
