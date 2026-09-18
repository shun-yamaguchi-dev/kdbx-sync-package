import Foundation
import Testing
@testable import KDBXSync

struct LoginItemTests {
    @Test
    func recordingLoginItemManagerStartsNotRegistered() {
        let manager = RecordingLoginItemManager()

        #expect(
            manager.status == .notRegistered
        )

        #expect(
            manager.registerCount == 0
        )

        #expect(
            manager.unregisterCount == 0
        )
    }

    @Test
    func recordingLoginItemManagerRegisters() throws {
        let manager = RecordingLoginItemManager()

        try manager.register()

        #expect(
            manager.status == .enabled
        )

        #expect(
            manager.registerCount == 1
        )

        #expect(
            manager.unregisterCount == 0
        )
    }

    @Test
    func recordingLoginItemManagerUnregisters() throws {
        let manager = RecordingLoginItemManager()

        try manager.register()
        try manager.unregister()

        #expect(
            manager.status == .notRegistered
        )

        #expect(
            manager.registerCount == 1
        )

        #expect(
            manager.unregisterCount == 1
        )
    }

    @Test
    func recordingLoginItemManagerCanBeUsedThroughProtocol() throws {
        let manager: any LoginItemManaging =
            RecordingLoginItemManager()

        #expect(
            manager.status == .notRegistered
        )

        try manager.register()

        #expect(
            manager.status == .enabled
        )
    }
}
