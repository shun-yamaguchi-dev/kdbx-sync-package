struct InitialSynchronizationResult {
    enum Action: Equatable {
        case noChange
        case copiedLocalToRemote
        case copiedRemoteToLocal
    }

    let action: Action
}
