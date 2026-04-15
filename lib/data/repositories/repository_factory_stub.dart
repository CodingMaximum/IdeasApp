import 'package:ideas_app/data/repositories/idea_repository_interface.dart';

// Auf Web wird diese Datei geladen — kein Drift, kein sqlite3, kein FFI
IIdeaRepository createLocalRepository(dynamic db, String userId) {
  throw UnsupportedError('Lokales Repository nicht verfügbar auf Web.');
}

dynamic createDatabase() {
  throw UnsupportedError('Drift nicht verfügbar auf Web.');
}