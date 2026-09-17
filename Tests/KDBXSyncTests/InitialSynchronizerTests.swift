import Foundation
import XCTest
@testable import KDBXSync

final class InitialSynchronizerTests: XCTestCase {
    private var temporaryDirectory: URL!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        try FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: temporaryDirectory)
    }

    func testBothFilesMissingThrowsError() throws {
        let vault = makeVault()
        let synchronizer = InitialSynchronizer()

        XCTAssertThrowsError(
            try synchronizer.synchronize(vault: vault)
        ) { error in
            XCTAssertEqual(
                error as? SynchronizationError,
                .bothFilesMissing
            )
        }
    }

    func testLocalExistsRemoteMissingCopiesLocalToRemote() throws {
        let vault = makeVault()
        let localContents = Data("local contents".utf8)

        try localContents.write(to: vault.localPath)

        let synchronizer = InitialSynchronizer()

        let result = try synchronizer.synchronize(vault: vault)

        XCTAssertEqual(
            result.action,
            .copiedLocalToRemote
        )

        XCTAssertEqual(
            try Data(contentsOf: vault.remotePath),
            localContents
        )
    }

    func testLocalMissingRemoteExistsCopiesRemoteToLocal() throws {
        let vault = makeVault()
        let remoteContents = Data("remote contents".utf8)

        try remoteContents.write(to: vault.remotePath)

        let synchronizer = InitialSynchronizer()

        let result = try synchronizer.synchronize(vault: vault)

        XCTAssertEqual(
            result.action,
            .copiedRemoteToLocal
        )

        XCTAssertEqual(
            try Data(contentsOf: vault.localPath),
            remoteContents
        )
    }

    func testBothFilesIdenticalDoesNothing() throws {
        let vault = makeVault()
        let contents = Data("identical contents".utf8)

        try contents.write(to: vault.localPath)
        try contents.write(to: vault.remotePath)

        let synchronizer = InitialSynchronizer()

        let result = try synchronizer.synchronize(vault: vault)

        XCTAssertEqual(
            result.action,
            .noChange
        )

        XCTAssertEqual(
            try Data(contentsOf: vault.localPath),
            contents
        )

        XCTAssertEqual(
            try Data(contentsOf: vault.remotePath),
            contents
        )
    }

    func testBothFilesDifferentThrowsConflict() throws {
        let vault = makeVault()

        try Data("local contents".utf8)
            .write(to: vault.localPath)

        try Data("remote contents".utf8)
            .write(to: vault.remotePath)

        let synchronizer = InitialSynchronizer()

        XCTAssertThrowsError(
            try synchronizer.synchronize(vault: vault)
        ) { error in
            XCTAssertEqual(
                error as? SynchronizationError,
                .conflict
            )
        }
    }

    func testRollbackAfterCopyingLocalToRemoteRemovesRemoteFile() throws {
        let vault = makeVault()
        let localContents = Data("local contents".utf8)

        try localContents.write(to: vault.localPath)

        let synchronizer = InitialSynchronizer()

        let result = try synchronizer.synchronize(vault: vault)

        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: vault.remotePath.path
            )
        )

        try synchronizer.rollback(
            result: result,
            vault: vault
        )

        XCTAssertFalse(
            FileManager.default.fileExists(
                atPath: vault.remotePath.path
            )
        )

        XCTAssertEqual(
            try Data(contentsOf: vault.localPath),
            localContents
        )
    }

    func testRollbackAfterCopyingRemoteToLocalRemovesLocalFile() throws {
        let vault = makeVault()
        let remoteContents = Data("remote contents".utf8)

        try remoteContents.write(to: vault.remotePath)

        let synchronizer = InitialSynchronizer()

        let result = try synchronizer.synchronize(vault: vault)

        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: vault.localPath.path
            )
        )

        try synchronizer.rollback(
            result: result,
            vault: vault
        )

        XCTAssertFalse(
            FileManager.default.fileExists(
                atPath: vault.localPath.path
            )
        )

        XCTAssertEqual(
            try Data(contentsOf: vault.remotePath),
            remoteContents
        )
    }

    func testRollbackAfterNoChangeDoesNothing() throws {
        let vault = makeVault()
        let contents = Data("identical contents".utf8)

        try contents.write(to: vault.localPath)
        try contents.write(to: vault.remotePath)

        let synchronizer = InitialSynchronizer()

        let result = try synchronizer.synchronize(vault: vault)

        try synchronizer.rollback(
            result: result,
            vault: vault
        )

        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: vault.localPath.path
            )
        )

        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: vault.remotePath.path
            )
        )

        XCTAssertEqual(
            try Data(contentsOf: vault.localPath),
            contents
        )

        XCTAssertEqual(
            try Data(contentsOf: vault.remotePath),
            contents
        )
    }

    private func makeVault() -> Vault {
        Vault(
            id: UUID(),
            name: "test",
            enabled: false,
            localPath: temporaryDirectory
                .appendingPathComponent("local.kdbx"),
            localWatchPath: temporaryDirectory
                .appendingPathComponent("local"),
            remotePath: temporaryDirectory
                .appendingPathComponent("remote.kdbx"),
            remoteWatchPath: temporaryDirectory
                .appendingPathComponent("remote"),
            keyfilePath: temporaryDirectory
                .appendingPathComponent("keyfile.key")
        )
    }
}
