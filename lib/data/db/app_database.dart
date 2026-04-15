import 'package:drift/drift.dart';
import 'package:ideas_app/data/db/seed_defaults.dart';
import 'connection.dart'; // conditional export – Web sieht nie FFI
import 'tables/ideas.dart';
import 'tables/categories.dart';
import 'tables/idea_statuses.dart';
import 'tables/idea_modules.dart';
import 'tables/idea_link_items.dart';
import 'tables/idea_checklist_items.dart';
import 'package:ideas_app/data/enums/idea_module_type.dart';
part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Ideas,
    Categories,
    IdeaStatuses,
    IdeaModules,
    IdeaLinkItems,
    IdeaChecklistItems,
  ],
)
class AppDatabase extends _$AppDatabase {
  // openConnection() kommt via conditional export aus connection.dart
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await seedDefaults();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(categories);
        await m.createTable(ideaStatuses);
        await m.createTable(ideaModules);
        await m.createTable(ideaLinkItems);
        await m.createTable(ideaChecklistItems);

        await m.addColumn(ideas, ideas.categoryId);
        await m.addColumn(ideas, ideas.statusId);
        await m.addColumn(ideas, ideas.archivedAt);

        await seedDefaults();
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> seedDefaults() async {
    await transaction(() async {
      for (final cat in SeedDefaults.categories) {
        await into(categories).insertOnConflictUpdate(cat);
      }

      for (final status in SeedDefaults.ideaStatuses) {
        await into(ideaStatuses).insertOnConflictUpdate(status);
      }
    });
  }

  Future<void> resetDatabaseContent() async {
    await transaction(() async {
      final tables = allTables.toList().reversed;

      for (final table in tables) {
        await delete(table).go();
      }

      await seedDefaults();
    });
  }

  Future<int> insertIdea(IdeasCompanion idea) {
    return into(ideas).insert(idea);
  }

  Future<List<Idea>> getAllIdeas() {
    return (select(ideas)
          ..where((tbl) => tbl.deletedAt.isNull())
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Stream<List<Idea>> watchIdeas() {
    return (select(ideas)
          ..where((tbl) => tbl.deletedAt.isNull() & tbl.archivedAt.isNull())
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Stream<List<Idea>> watchArchivedIdeas() {
    return (select(ideas)
          ..where((tbl) => tbl.deletedAt.isNull() & tbl.archivedAt.isNotNull())
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Stream<Idea?> watchIdeaById(String id) {
    return (select(ideas)
          ..where((tbl) => tbl.id.equals(id) & tbl.deletedAt.isNull()))
        .watchSingleOrNull();
  }

  Future<Idea?> getIdeaById(String id) {
    return (select(ideas)
          ..where((tbl) => tbl.id.equals(id) & tbl.deletedAt.isNull()))
        .getSingleOrNull();
  }

  Future<int> updateIdea({
    required String id,
    required String title,
    required String? description,
    required DateTime updatedAt,
  }) {
    return (update(ideas)..where((tbl) => tbl.id.equals(id))).write(
      IdeasCompanion(
        title: Value(title),
        description: Value(description),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<int> softDeleteIdea(String id) {
    final now = DateTime.now();

    return (update(ideas)..where((tbl) => tbl.id.equals(id))).write(
      IdeasCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  Future<int> restoreIdea(String id) {
    final now = DateTime.now();

    return (update(ideas)..where((tbl) => tbl.id.equals(id))).write(
      IdeasCompanion(deletedAt: const Value(null), updatedAt: Value(now)),
    );
  }

  Stream<List<Category>> watchCategories() {
    return (select(
      categories,
    )..orderBy([(t) => OrderingTerm(expression: t.sortOrder)])).watch();
  }

  Stream<List<IdeaStatuse>> watchIdeaStatuses() {
    return (select(
      ideaStatuses,
    )..orderBy([(t) => OrderingTerm(expression: t.sortOrder)])).watch();
  }

  Future<int> updateIdeaCategory(String id, String categoryId) {
    return (update(ideas)..where((tbl) => tbl.id.equals(id))).write(
      IdeasCompanion(
        categoryId: Value(categoryId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> updateIdeaStatus(String id, String statusId) {
    return (update(ideas)..where((tbl) => tbl.id.equals(id))).write(
      IdeasCompanion(
        statusId: Value(statusId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> updateIdeaArchived(String id, DateTime? archivedAt) {
    return (update(ideas)..where((tbl) => tbl.id.equals(id))).write(
      IdeasCompanion(
        archivedAt: Value(archivedAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteIdea(String id) =>
      (delete(ideas)..where((tbl) => tbl.id.equals(id))).go();
}
