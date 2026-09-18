import Foundation
import Testing
@testable import KDBXSync

struct CommandHandlerTests {
    @Test
    func loginItemStatusReportsNotRegistered() throws {
        let loginItemManager = RecordingLoginItemManager()

        let handler = makeHandler(
            loginItemManager: loginItemManager
        )

        try handler.execute(
            arguments: ["login-item", "status"]
        )
    }

    @Test
    func loginItemEnableRegistersLoginItem() throws {
        let loginItemManager = RecordingLoginItemManager()

        let handler = makeHandler(
            loginItemManager: loginItemManager
        )

        try handler.execute(
            arguments: ["login-item", "enable"]
        )

        #expect(
            loginItemManager.registerCount == 1
        )

        #expect(
            loginItemManager.unregisterCount == 0
        )

        #expect(
            loginItemManager.status == .enabled
        )
    }

    @Test
    func loginItemDisableUnregistersLoginItem() throws {
        let loginItemManager = RecordingLoginItemManager()

        let handler = makeHandler(
            loginItemManager: loginItemManager
        )

        try loginItemManager.register()

        try handler.execute(
            arguments: ["login-item", "disable"]
        )

        #expect(
            loginItemManager.registerCount == 1
        )

        #expect(
            loginItemManager.unregisterCount == 1
        )

        #expect(
            loginItemManager.status == .notRegistered
        )
    }

    @Test
    func loginItemRequiresAnAction() {
        let loginItemManager = RecordingLoginItemManager()

        let handler = makeHandler(
            loginItemManager: loginItemManager
        )

        #expect(throws: CommandError.invalidArguments) {
            try handler.execute(
                arguments: ["login-item"]
            )
        }
    }

    @Test
    func loginItemRejectsUnknownAction() {
        let loginItemManager = RecordingLoginItemManager()

        let handler = makeHandler(
            loginItemManager: loginItemManager
        )

        #expect(
            throws: CommandError.unknownCommand(
                "login-item unknown"
            )
        ) {
            try handler.execute(
                arguments: ["login-item", "unknown"]
            )
        }
    }

    @Test
    func loginItemRejectsAdditionalArguments() {
        let loginItemManager = RecordingLoginItemManager()

        let handler = makeHandler(
            loginItemManager: loginItemManager
        )

        #expect(throws: CommandError.invalidArguments) {
            try handler.execute(
                arguments: [
                    "login-item",
                    "enable",
                    "extra"
                ]
            )
        }
    }

    private func makeHandler(
        loginItemManager: LoginItemManaging
    ) -> CommandHandler {
        let store = ConfigurationStore(
            configurationURL: URL(
                fileURLWithPath:
                    "/tmp/kdbx-sync-command-handler-test.toml"
            )
        )

        let validator = ConfigurationValidator()

        let launchAgentManager = UnusedLaunchAgentManager()

        let initialSynchronizer = UnusedInitialSynchronizer()

        let applicationPaths = ApplicationPaths(
            bundleURL: URL(
                fileURLWithPath: "/tmp/KDBX Sync.app"
            )
        )

        let manager = ConfigurationManager(
            store: store,
            validator: validator,
            launchAgentManager: launchAgentManager,
            initialSynchronizer: initialSynchronizer,
            applicationPaths: applicationPaths
        )

        return CommandHandler(
            manager: manager,
            loginItemManager: loginItemManager
        )
    }
}
