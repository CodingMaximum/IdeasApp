import 'package:drift/drift.dart';
import 'categories.dart';
import 'idea_statuses.dart';

class Ideas extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();

  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get statusId => text().references(IdeaStatuses, #id)();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get createdBy => text()();

  @override
  Set<Column> get primaryKey => {id};

  
}