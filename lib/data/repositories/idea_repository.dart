import 'package:ideas_app/data/db/seed_ids.dart';
import 'package:ideas_app/data/enums/idea_module_type.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';

import '../db/app_database.dart';

class IdeaRepository {
  final AppDatabase db;
  final String userId;
  final uuid = const Uuid();

  IdeaRepository(this.db, this.userId);

  Future<void> createIdea(String title) async {
    final now = DateTime.now();

    await db.insertIdea(
      IdeasCompanion(
        id: Value(uuid.v4()),
        title: Value(title),
        statusId: const Value(SeedIds.planningStatus),
        createdAt: Value(now),
        updatedAt: Value(now),
        createdBy: Value(userId),
      ),
    );
  }

  Future<void> updateIdea({
    required String id,
    required String title,
    required String description,
  }) async {
    final now = DateTime.now();

    await db.updateIdea(
      id: id,
      title: title,
      description: description.isEmpty ? null : description,
      updatedAt: now,
    );
  }

  Future<void> renameIdea(String id, String title) async {
    final existing = await db.getIdeaById(id);
    if (existing == null) return;

    await db.updateIdea(
      id: id,
      title: title,
      description: existing.description,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> deleteIdea(String id) async {
    await db.softDeleteIdea(id);
  }

  Future<void> deleteIdeaPermanently(String id) async {
    await db.deleteIdea(id);
  }

  Stream<Idea?> watchIdeaById(String id) {
    return db.watchIdeaById(id);
  }

  Future<Idea?> getIdeaById(String id) {
    return db.getIdeaById(id);
  }

  Stream<List<Idea>> watchIdeas() => db.watchIdeas();

  Stream<List<Category>> watchCategories() => db.watchCategories();

  Stream<List<IdeaStatuse>> watchIdeaStatuses() => db.watchIdeaStatuses();

  Future<void> updateIdeaCategory(String id, String categoryId) async {
    await db.updateIdeaCategory(id, categoryId);
  }

  Future<void> updateIdeaStatus(String id, String statusId) async {
    await db.updateIdeaStatus(id, statusId);
  }

  Future<void> restoreIdea(String id) async {
    await db.restoreIdea(id);
  }

  Stream<List<Idea>> watchArchivedIdeas() => db.watchArchivedIdeas();

  Future<void> archiveIdea(String id) async {
    await db.updateIdeaArchived(id, DateTime.now());
  }

  Future<void> unarchiveIdea(String id) async {
    await db.updateIdeaArchived(id, null);
  }

  Stream<List<IdeaModule>> watchModulesForIdea(String ideaId) {
    final query = db.select(db.ideaModules)
      ..where((tbl) => tbl.ideaId.equals(ideaId))
      ..orderBy([
        (tbl) => OrderingTerm.asc(tbl.sortOrder),
        (tbl) => OrderingTerm.asc(tbl.createdAt),
      ]);

    return query.watch();
  }

  Stream<List<IdeaChecklistItem>> watchChecklistItems(String moduleId) {
    final query = db.select(db.ideaChecklistItems)
      ..where((tbl) => tbl.moduleId.equals(moduleId))
      ..orderBy([
        (tbl) => OrderingTerm.asc(tbl.sortOrder),
        (tbl) => OrderingTerm.asc(tbl.createdAt),
      ]);

    return query.watch();
  }

  Stream<List<IdeaLinkItem>> watchLinkItems(String moduleId) {
    final query = db.select(db.ideaLinkItems)
      ..where((tbl) => tbl.moduleId.equals(moduleId))
      ..orderBy([
        (tbl) => OrderingTerm.asc(tbl.sortOrder),
        (tbl) => OrderingTerm.asc(tbl.createdAt),
      ]);

    return query.watch();
  }

  Future<void> addChecklistModule(String ideaId) async {
    final now = DateTime.now();
    final sortOrder = await _nextModuleSortOrder(ideaId);

    await db.into(db.ideaModules).insert(
      IdeaModulesCompanion.insert(
        id: uuid.v4(),
        ideaId: ideaId,
        type: IdeaModuleType.checklist,
        title: 'Neue Checkliste',
        sortOrder: Value(sortOrder),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> addLinksModule(String ideaId) async {
    final now = DateTime.now();
    final sortOrder = await _nextModuleSortOrder(ideaId);

    await db.into(db.ideaModules).insert(
      IdeaModulesCompanion.insert(
        id: uuid.v4(),
        ideaId: ideaId,
        type: IdeaModuleType.links,
        title: 'Neue Links',
        sortOrder: Value(sortOrder),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> addChecklistItem(String moduleId) async {
    final now = DateTime.now();
    final sortOrder = await _nextChecklistItemSortOrder(moduleId);

    await db.into(db.ideaChecklistItems).insert(
      IdeaChecklistItemsCompanion.insert(
        id: uuid.v4(),
        moduleId: moduleId,
        content: 'Neuer Punkt',
        sortOrder: Value(sortOrder),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> addLinkItem({
    required String moduleId,
    required String url,
    String? label,
  }) async {
    final now = DateTime.now();
    final sortOrder = await _nextLinkItemSortOrder(moduleId);

    await db.into(db.ideaLinkItems).insert(
      IdeaLinkItemsCompanion.insert(
        id: uuid.v4(),
        moduleId: moduleId,
        url: url,
        label: Value(label),
        sortOrder: Value(sortOrder),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> deleteModule(String moduleId) async {
    await (db.delete(db.ideaModules)..where((tbl) => tbl.id.equals(moduleId)))
        .go();
  }

  Future<int> _nextModuleSortOrder(String ideaId) async {
    final modules = await (db.select(db.ideaModules)
          ..where((tbl) => tbl.ideaId.equals(ideaId)))
        .get();

    if (modules.isEmpty) return 0;

    final maxSortOrder = modules
        .map((module) => module.sortOrder)
        .reduce((a, b) => a > b ? a : b);

    return maxSortOrder + 1;
  }

  Future<int> _nextChecklistItemSortOrder(String moduleId) async {
    final items = await (db.select(db.ideaChecklistItems)
          ..where((tbl) => tbl.moduleId.equals(moduleId)))
        .get();

    if (items.isEmpty) return 0;

    final maxSortOrder = items
        .map((item) => item.sortOrder)
        .reduce((a, b) => a > b ? a : b);

    return maxSortOrder + 1;
  }

  Future<int> _nextLinkItemSortOrder(String moduleId) async {
    final items = await (db.select(db.ideaLinkItems)
          ..where((tbl) => tbl.moduleId.equals(moduleId)))
        .get();

    if (items.isEmpty) return 0;

    final maxSortOrder = items
        .map((item) => item.sortOrder)
        .reduce((a, b) => a > b ? a : b);

    return maxSortOrder + 1;
  }
}