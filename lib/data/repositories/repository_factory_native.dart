import 'package:ideas_app/data/db/app_database.dart';
import 'package:ideas_app/data/repositories/local/drift_idea_repository.dart';
import 'package:ideas_app/data/repositories/idea_repository_interface.dart';

IIdeaRepository createLocalRepository(AppDatabase db, String userId) {
  return DriftIdeaRepository(db, userId);
}

AppDatabase createDatabase() => AppDatabase();