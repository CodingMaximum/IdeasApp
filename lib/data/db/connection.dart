// lib/data/db/connection.dart
import 'package:drift/drift.dart';

// Nur native — Web instanziiert AppDatabase gar nicht
import 'connection_native.dart';

QueryExecutor connect() => openConnection();