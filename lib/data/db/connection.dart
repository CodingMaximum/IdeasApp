// lib/data/db/connection.dart
//
// Conditional export: Der Web-Compiler sieht connection_native.dart nie.
// Auf Mobile/Desktop wird connection_native.dart verwendet.
// Auf Web wird connection_stub.dart verwendet.
//
// Beide Dateien exportieren eine Funktion: openConnection()
// AppDatabase ruft openConnection() auf – nie direkt connection_native.dart.

export 'connection_stub.dart'
    if (dart.library.io) 'connection_native.dart';
