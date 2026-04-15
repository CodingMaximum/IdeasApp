// lib/data/db/connection.dart
//
// Conditional export: Der Web-Compiler sieht connection_native.dart nie.
// Auf Web wird connection_stub.dart verwendet, die AppDatabase wird
// auf Web ohnehin nicht instanziiert.
import 'package:drift/drift.dart';

export 'connection_stub.dart'
    if (dart.library.io) 'connection_native.dart';

// Damit connection.dart selbst importierbar bleibt:
QueryExecutor connect() => _connect();

// Wird durch den export oben bereitgestellt:
QueryExecutor _connect();
