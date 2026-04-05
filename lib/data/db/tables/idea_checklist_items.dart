import 'package:drift/drift.dart';
import 'idea_modules.dart';

class IdeaChecklistItems extends Table {
  TextColumn get id => text()();
  TextColumn get moduleId => text().references(IdeaModules, #id)();

  TextColumn get content => text()();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}