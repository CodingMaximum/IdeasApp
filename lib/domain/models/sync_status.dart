/// Synchronisierungsstatus eines lokalen Datensatzes.
/// Wird für späteren Offline-Sync (PowerSync / manuell) vorbereitet.
enum SyncStatus {
  /// Datensatz ist mit dem Backend synchronisiert.
  synced,

  /// Lokale Änderung wartet auf Upload.
  pending,

  /// Konflikt zwischen lokaler und remote Version.
  conflict,
}
