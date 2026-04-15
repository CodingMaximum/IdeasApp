// lib/data/db/connection_stub.dart
//
// Wird auf Web kompiliert. Enthält kein FFI, kein sqlite3.
// AppDatabase wird auf Web nie instanziiert – dieser Stub
// ist nur da, damit der Compiler zufrieden ist.
import 'package:drift/drift.dart';

QueryExecutor openConnection() {
  throw UnsupportedError(
    'Native SQLite-Datenbank ist auf Web nicht verfügbar. '
    'Verwende stattdessen das Supabase-Repository.',
  );
}
