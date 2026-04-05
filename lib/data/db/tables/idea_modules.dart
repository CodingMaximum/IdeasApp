import 'package:drift/drift.dart';
import '../../enums/idea_module_type.dart';

import 'ideas.dart';

class IdeaModules extends Table {
  TextColumn get id => text()();
  TextColumn get ideaId => text().references(Ideas, #id)();

  TextColumn get type => textEnum<IdeaModuleType>()();
  TextColumn get title => text()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
