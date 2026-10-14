/// Two versions of the same record: what is on the device and what the server has.
class Versioned<T> {
  const Versioned(this.value, this.updatedAt);
  final T value;
  final DateTime updatedAt;
}

class Resolution<T> {
  const Resolution(this.winner, {this.needsUserDecision = false});
  final Versioned<T> winner;

  /// True when the app should ask the user instead of silently picking one.
  final bool needsUserDecision;
}

/// Last write wins: the newer timestamp wins. Fine for low-stakes data such as preferences.
/// Weakness: clocks differ between devices, and the loser's change is silently lost.
Resolution<T> lastWriteWins<T>(Versioned<T> local, Versioned<T> remote) =>
    Resolution(local.updatedAt.isAfter(remote.updatedAt) ? local : remote);

/// Server authoritative: if the server changed after the local copy was last synced, the server wins
/// and the user is told. [lastSyncedAt] is when the device last agreed with the server.
Resolution<T> serverAuthoritative<T>(Versioned<T> local, Versioned<T> remote, {required DateTime lastSyncedAt}) {
  final serverChanged = remote.updatedAt.isAfter(lastSyncedAt);
  final localChanged = local.updatedAt.isAfter(lastSyncedAt);
  if (serverChanged && localChanged) return Resolution(remote, needsUserDecision: true);
  return Resolution(serverChanged ? remote : local);
}
