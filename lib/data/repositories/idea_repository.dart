import 'package:drift/drift.dart';
import 'package:ideas_app/data/db/seed_ids.dart';
import 'package:ideas_app/data/enums/idea_module_type.dart';
import 'package:uuid/uuid.dart';

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
    await addChecklistModuleWithTitle(ideaId: ideaId, title: 'Neue Checkliste');
  }

  Future<void> addLinksModule(String ideaId) async {
    await addLinksModuleWithTitle(ideaId: ideaId, title: 'Neue Links');
  }

  Future<void> addChecklistModuleWithTitle({
    required String ideaId,
    required String title,
  }) async {
    final now = DateTime.now();
    final sortOrder = await _nextModuleSortOrder(ideaId);
    final trimmed = title.trim();

    await db
        .into(db.ideaModules)
        .insert(
          IdeaModulesCompanion.insert(
            id: uuid.v4(),
            ideaId: ideaId,
            type: IdeaModuleType.checklist,
            title: trimmed.isEmpty ? 'Neue Checkliste' : trimmed,
            sortOrder: Value(sortOrder),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> addLinksModuleWithTitle({
    required String ideaId,
    required String title,
  }) async {
    final now = DateTime.now();
    final sortOrder = await _nextModuleSortOrder(ideaId);
    final trimmed = title.trim();

    await db
        .into(db.ideaModules)
        .insert(
          IdeaModulesCompanion.insert(
            id: uuid.v4(),
            ideaId: ideaId,
            type: IdeaModuleType.links,
            title: trimmed.isEmpty ? 'Neue Links' : trimmed,
            sortOrder: Value(sortOrder),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> renameModule(String moduleId, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;

    await (db.update(
      db.ideaModules,
    )..where((tbl) => tbl.id.equals(moduleId))).write(
      IdeaModulesCompanion(
        title: Value(trimmed),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> addChecklistItem(String moduleId) async {
    await addChecklistItemWithContent(
      moduleId: moduleId,
      content: 'Neuer Punkt',
    );
  }

  Future<void> addChecklistItemWithContent({
    required String moduleId,
    required String content,
  }) async {
    final now = DateTime.now();
    final sortOrder = await _nextChecklistItemSortOrder(moduleId);
    final trimmed = content.trim();

    await db
        .into(db.ideaChecklistItems)
        .insert(
          IdeaChecklistItemsCompanion.insert(
            id: uuid.v4(),
            moduleId: moduleId,
            content: trimmed.isEmpty ? 'Neuer Punkt' : trimmed,
            sortOrder: Value(sortOrder),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> updateChecklistItem({
    required String itemId,
    required String content,
    required bool isDone,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    await (db.update(
      db.ideaChecklistItems,
    )..where((tbl) => tbl.id.equals(itemId))).write(
      IdeaChecklistItemsCompanion(
        content: Value(trimmed),
        isDone: Value(isDone),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> toggleChecklistItem({
    required String itemId,
    required bool isDone,
  }) async {
    await (db.update(
      db.ideaChecklistItems,
    )..where((tbl) => tbl.id.equals(itemId))).write(
      IdeaChecklistItemsCompanion(
        isDone: Value(isDone),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteChecklistItem(String itemId) async {
    await (db.delete(
      db.ideaChecklistItems,
    )..where((tbl) => tbl.id.equals(itemId))).go();
  }

  Future<void> addLinkItem({
    required String moduleId,
    required String url,
    String? label,
  }) async {
    final now = DateTime.now();
    final sortOrder = await _nextLinkItemSortOrder(moduleId);

    await db
        .into(db.ideaLinkItems)
        .insert(
          IdeaLinkItemsCompanion.insert(
            id: uuid.v4(),
            moduleId: moduleId,
            url: url.trim(),
            label: Value(
              label == null || label.trim().isEmpty ? null : label.trim(),
            ),
            sortOrder: Value(sortOrder),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> updateLinkItem({
    required String itemId,
    required String url,
    String? label,
  }) async {
    final trimmedUrl = url.trim();
    final trimmedLabel = label?.trim();

    if (trimmedUrl.isEmpty) return;

    await (db.update(
      db.ideaLinkItems,
    )..where((tbl) => tbl.id.equals(itemId))).write(
      IdeaLinkItemsCompanion(
        url: Value(trimmedUrl),
        label: Value(
          trimmedLabel == null || trimmedLabel.isEmpty ? null : trimmedLabel,
        ),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteLinkItem(String itemId) async {
    await (db.delete(
      db.ideaLinkItems,
    )..where((tbl) => tbl.id.equals(itemId))).go();
  }

  Future<void> deleteModule(String moduleId) async {
    await db.transaction(() async {
      await (db.delete(
        db.ideaChecklistItems,
      )..where((tbl) => tbl.moduleId.equals(moduleId))).go();

      await (db.delete(
        db.ideaLinkItems,
      )..where((tbl) => tbl.moduleId.equals(moduleId))).go();

      await (db.delete(
        db.ideaModules,
      )..where((tbl) => tbl.id.equals(moduleId))).go();
    });
  }

  Future<int> _nextModuleSortOrder(String ideaId) async {
    final modules = await (db.select(
      db.ideaModules,
    )..where((tbl) => tbl.ideaId.equals(ideaId))).get();

    if (modules.isEmpty) return 0;

    final maxSortOrder = modules
        .map((module) => module.sortOrder)
        .reduce((a, b) => a > b ? a : b);

    return maxSortOrder + 1;
  }

  Future<int> _nextChecklistItemSortOrder(String moduleId) async {
    final items = await (db.select(
      db.ideaChecklistItems,
    )..where((tbl) => tbl.moduleId.equals(moduleId))).get();

    if (items.isEmpty) return 0;

    final maxSortOrder = items
        .map((item) => item.sortOrder)
        .reduce((a, b) => a > b ? a : b);

    return maxSortOrder + 1;
  }

  Future<int> _nextLinkItemSortOrder(String moduleId) async {
    final items = await (db.select(
      db.ideaLinkItems,
    )..where((tbl) => tbl.moduleId.equals(moduleId))).get();

    if (items.isEmpty) return 0;

    final maxSortOrder = items
        .map((item) => item.sortOrder)
        .reduce((a, b) => a > b ? a : b);

    return maxSortOrder + 1;
  }

  Future<void> reorderModules({
    required List<IdeaModule> modules,
    required int oldIndex,
    required int newIndex,
  }) async {
    if (oldIndex < 0 || oldIndex >= modules.length) return;
    if (newIndex < 0 || newIndex > modules.length) return;

    final reordered = List<IdeaModule>.from(modules);

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    await db.batch((batch) {
      for (var i = 0; i < reordered.length; i++) {
        final module = reordered[i];

        batch.update(
          db.ideaModules,
          IdeaModulesCompanion(
            sortOrder: Value(i),
            updatedAt: Value(DateTime.now()),
          ),
          where: (tbl) => tbl.id.equals(module.id),
        );
      }
    });
  }

  Future<void> reorderChecklistItems({
    required List<IdeaChecklistItem> items,
    required int oldIndex,
    required int newIndex,
  }) async {
    if (oldIndex < 0 || oldIndex >= items.length) return;
    if (newIndex < 0 || newIndex > items.length) return;

    final reordered = List<IdeaChecklistItem>.from(items);

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    final now = DateTime.now();

    await db.batch((batch) {
      for (var i = 0; i < reordered.length; i++) {
        final item = reordered[i];

        batch.update(
          db.ideaChecklistItems,
          IdeaChecklistItemsCompanion(
            sortOrder: Value(i),
            updatedAt: Value(now),
          ),
          where: (tbl) => tbl.id.equals(item.id),
        );
      }
    });
  }

  Future<void> reorderLinkItems({
    required List<IdeaLinkItem> items,
    required int oldIndex,
    required int newIndex,
  }) async {
    if (oldIndex < 0 || oldIndex >= items.length) return;
    if (newIndex < 0 || newIndex > items.length) return;

    final reordered = List<IdeaLinkItem>.from(items);

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    final now = DateTime.now();

    await db.batch((batch) {
      for (var i = 0; i < reordered.length; i++) {
        final item = reordered[i];

        batch.update(
          db.ideaLinkItems,
          IdeaLinkItemsCompanion(sortOrder: Value(i), updatedAt: Value(now)),
          where: (tbl) => tbl.id.equals(item.id),
        );
      }
    });
  }

  Future<void> createIdeaFromCapture({
    required String description,
    String? title,
  }) async {
    final cleanDescription = description.trim();
    if (cleanDescription.isEmpty) return;

    final now = DateTime.now();
    final resolvedTitle = _buildFallbackTitle(
      explicitTitle: title,
      description: cleanDescription,
    );

    await db.insertIdea(
      IdeasCompanion(
        id: Value(uuid.v4()),
        title: Value(resolvedTitle),
        description: Value(cleanDescription),
        statusId: const Value(SeedIds.planningStatus),
        createdAt: Value(now),
        updatedAt: Value(now),
        createdBy: Value(userId),
      ),
    );
  }

  String _buildFallbackTitle({
    String? explicitTitle,
    required String description,
  }) {
    final cleanTitle = explicitTitle?.trim();
    if (cleanTitle != null && cleanTitle.isNotEmpty) {
      return cleanTitle;
    }

    final normalized = description
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (normalized.isEmpty) {
      return 'Neue Idee';
    }

    const maxLength = 60;
    if (normalized.length <= maxLength) {
      return normalized;
    }

    return '${normalized.substring(0, maxLength).trim()}…';
  }
}
