import Foundation

protocol InitialSynchronizing {
    func synchronize(
        vault: Vault
    ) throws -> InitialSynchronizationResult

    func rollback(
        result: InitialSynchronizationResult,
        vault: Vault
    ) throws
}

struct InitialSynchronizer: InitialSynchronizing {
    func synchronize(
        vault: Vault
    ) throws -> InitialSynchronizationResult {
        let localExists = FileManager.default.fileExists(
            atPath: vault.localPath.path
        )

        let remoteExists = FileManager.default.fileExists(
            atPath: vault.remotePath.path
        )

        switch (localExists, remoteExists) {
        case (false, false):
            throw SynchronizationError.bothFilesMissing

        case (true, false):
            try FileManager.default.copyItem(
                at: vault.localPath,
                to: vault.remotePath
            )

            return InitialSynchronizationResult(
                action: .copiedLocalToRemote
            )

        case (false, true):
            try FileManager.default.copyItem(
                at: vault.remotePath,
                to: vault.localPath
            )

            return InitialSynchronizationResult(
                action: .copiedRemoteToLocal
            )

        case (true, true):
            let localContents = try Data(
                contentsOf: vault.localPath
            )

            let remoteContents = try Data(
                contentsOf: vault.remotePath
            )

            guard localContents == remoteContents else {
                throw SynchronizationError.conflict
            }

            return InitialSynchronizationResult(
                action: .noChange
            )
        }
    }

    func rollback(
        result: InitialSynchronizationResult,
        vault: Vault
    ) throws {
        switch result.action {
        case .noChange:
            return

        case .copiedLocalToRemote:
            try FileManager.default.removeItem(
                at: vault.remotePath
            )

        case .copiedRemoteToLocal:
            try FileManager.default.removeItem(
                at: vault.localPath
            )
        }
    }
}
