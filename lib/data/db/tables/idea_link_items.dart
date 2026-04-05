import 'package:drift/drift.dart';
import 'idea_modules.dart';

class IdeaLinkItems extends Table {
  TextColumn get id => text()();
  TextColumn get moduleId => text().references(IdeaModules, #id)();

  TextColumn get label => text().nullable()();
  TextColumn get url => text()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}