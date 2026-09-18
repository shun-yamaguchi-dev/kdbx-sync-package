import Foundation
@testable import KDBXSync

final class RecordingInitialSynchronizer: InitialSynchronizing {
    enum Event: Equatable {
        case synchronize
        case rollback
    }

    var events: [Event] = []

    func synchronize(
        vault: Vault
    ) throws -> InitialSynchronizationResult {
        events.append(.synchronize)

        return InitialSynchronizationResult(
            action: .noChange
        )
    }

    func rollback(
        result: InitialSynchronizationResult,
        vault: Vault
    ) throws {
        events.append(.rollback)
    }
}

final class RecordingLaunchAgentManager: LaunchAgentManaging {
    enum Event: Equatable {
        case install
        case remove
        case reconcile(
            name: String,
            enabled: Bool
        )
    }

    var events: [Event] = []
    var reconciliationEvents: [Event] = []

    func install(
        vault: Vault,
        configuration: Configuration,
        applicationPaths: ApplicationPaths
    ) throws {
        events.append(.install)
    }

    func remove(
        vault: Vault
    ) throws {
        events.append(.remove)
    }

    func reconcile(
        vault: Vault,
        enabled: Bool,
        configuration: Configuration,
        applicationPaths: ApplicationPaths
    ) throws {
        let event = Event.reconcile(
            name: vault.name,
            enabled: enabled
        )

        events.append(event)
        reconciliationEvents.append(event)
    }
}

struct UnusedLaunchAgentManager: LaunchAgentManaging {
    func install(
        vault: Vault,
        configuration: Configuration,
        applicationPaths: ApplicationPaths
    ) throws {
        fatalError("LaunchAgent manager should not be called.")
    }

    func remove(
        vault: Vault
    ) throws {
        fatalError("LaunchAgent manager should not be called.")
    }

    func reconcile(
        vault: Vault,
        enabled: Bool,
        configuration: Configuration,
        applicationPaths: ApplicationPaths
    ) throws {
        fatalError("LaunchAgent manager should not be called.")
    }
}

struct UnusedInitialSynchronizer: InitialSynchronizing {
    func synchronize(
        vault: Vault
    ) throws -> InitialSynchronizationResult {
        fatalError("Initial synchronizer should not be called.")
    }

    func rollback(
        result: InitialSynchronizationResult,
        vault: Vault
    ) throws {
        fatalError("Initial synchronizer should not be called.")
    }
}

final class RecordingLoginItemManager: LoginItemManaging {
    var currentStatus: LoginItemStatus = .notRegistered

    var registerCount = 0
    var unregisterCount = 0

    var status: LoginItemStatus {
        currentStatus
    }

    func register() throws {
        registerCount += 1
        currentStatus = .enabled
    }

    func unregister() throws {
        unregisterCount += 1
        currentStatus = .notRegistered
    }
}
