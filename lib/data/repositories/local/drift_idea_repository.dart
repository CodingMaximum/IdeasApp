import 'package:drift/drift.dart';
import 'package:ideas_app/data/db/seed_ids.dart';
import 'package:ideas_app/domain/enums/idea_module_type.dart';
import 'package:uuid/uuid.dart';
import 'package:ideas_app/data/repositories/idea_repository_interface.dart';
import 'package:ideas_app/domain/models/idea_model.dart';
import 'package:ideas_app/domain/models/category_model.dart';
import 'package:ideas_app/domain/models/idea_status_model.dart';
import 'package:ideas_app/domain/models/idea_module_model.dart';
import 'package:ideas_app/domain/models/idea_checklist_item_model.dart';
import 'package:ideas_app/domain/models/idea_link_item_model.dart';
import 'package:ideas_app/domain/models/sync_status.dart';

import '../../db/app_database.dart';

class DriftIdeaRepository implements IIdeaRepository {
  final AppDatabase db;
  final String userId;
  final uuid = const Uuid();

  DriftIdeaRepository(this.db, this.userId);

  // ─── Mapper: Drift → Domain ───────────────────────────────

  IdeaModel _toIdea(Idea r) => IdeaModel(
        id: r.id,
        title: r.title,
        description: r.description,
        categoryId: r.categoryId,
        statusId: r.statusId,
        archivedAt: r.archivedAt,
        deletedAt: r.deletedAt,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
        createdBy: r.createdBy,
        syncStatus: SyncStatus.synced,
      );

  CategoryModel _toCategory(Category r) => CategoryModel(
        id: r.id,
        name: r.name,
        isSystem: r.isSystem,
        sortOrder: r.sortOrder,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  IdeaStatusModel _toStatus(IdeaStatuse r) => IdeaStatusModel(
        id: r.id,
        name: r.name,
        isSystem: r.isSystem,
        sortOrder: r.sortOrder,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  IdeaModuleModel _toModule(IdeaModule r) => IdeaModuleModel(
        id: r.id,
        ideaId: r.ideaId,
        type: r.type,
        title: r.title,
        sortOrder: r.sortOrder,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  IdeaChecklistItemModel _toChecklistItem(IdeaChecklistItem r) =>
      IdeaChecklistItemModel(
        id: r.id,
        moduleId: r.moduleId,
        content: r.content,
        isDone: r.isDone,
        sortOrder: r.sortOrder,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  IdeaLinkItemModel _toLinkItem(IdeaLinkItem r) => IdeaLinkItemModel(
        id: r.id,
        moduleId: r.moduleId,
        label: r.label,
        url: r.url,
        sortOrder: r.sortOrder,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  // ─── Ideas ───────────────────────────────────────────────

  @override
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

  @override
  Future<void> updateIdea({
    required String id,
    required String title,
    required String description,
  }) async {
    await db.updateIdea(
      id: id,
      title: title,
      description: description.isEmpty ? null : description,
      updatedAt: DateTime.now(),
    );
  }

  @override
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

  @override
  Future<void> deleteIdea(String id) async => db.softDeleteIdea(id);

  @override
  Future<void> deleteIdeaPermanently(String id) async => db.deleteIdea(id);

  @override
  Stream<IdeaModel?> watchIdeaById(String id) =>
      db.watchIdeaById(id).map((r) => r == null ? null : _toIdea(r));

  @override
  Future<IdeaModel?> getIdeaById(String id) async {
    final r = await db.getIdeaById(id);
    return r == null ? null : _toIdea(r);
  }

  @override
  Stream<List<IdeaModel>> watchIdeas() =>
      db.watchIdeas().map((list) => list.map(_toIdea).toList());

  @override
  Stream<List<IdeaModel>> watchArchivedIdeas() =>
      db.watchArchivedIdeas().map((list) => list.map(_toIdea).toList());

  @override
  Future<void> restoreIdea(String id) async => db.restoreIdea(id);

  @override
  Future<void> archiveIdea(String id) async =>
      db.updateIdeaArchived(id, DateTime.now());

  @override
  Future<void> unarchiveIdea(String id) async =>
      db.updateIdeaArchived(id, null);

  @override
  Future<void> updateIdeaCategory(String id, String categoryId) async =>
      db.updateIdeaCategory(id, categoryId);

  @override
  Future<void> updateIdeaStatus(String id, String statusId) async =>
      db.updateIdeaStatus(id, statusId);

  // ─── Categories & Statuses ───────────────────────────────

  @override
  Stream<List<CategoryModel>> watchCategories() =>
      db.watchCategories().map((list) => list.map(_toCategory).toList());

  @override
  Stream<List<IdeaStatusModel>> watchIdeaStatuses() =>
      db.watchIdeaStatuses().map((list) => list.map(_toStatus).toList());

  // ─── Modules ─────────────────────────────────────────────

  @override
  Stream<List<IdeaModuleModel>> watchModulesForIdea(String ideaId) {
    final query = db.select(db.ideaModules)
      ..where((tbl) => tbl.ideaId.equals(ideaId))
      ..orderBy([
        (tbl) => OrderingTerm.asc(tbl.sortOrder),
        (tbl) => OrderingTerm.asc(tbl.createdAt),
      ]);
    return query.watch().map((list) => list.map(_toModule).toList());
  }

  @override
  Future<void> addChecklistModule(String ideaId) =>
      addChecklistModuleWithTitle(ideaId: ideaId, title: 'Neue Checkliste');

  @override
  Future<void> addLinksModule(String ideaId) =>
      addLinksModuleWithTitle(ideaId: ideaId, title: 'Neue Links');

  @override
  Future<void> addChecklistModuleWithTitle({
    required String ideaId,
    required String title,
  }) async {
    final now = DateTime.now();
    final sortOrder = await _nextModuleSortOrder(ideaId);
    final trimmed = title.trim();
    await db.into(db.ideaModules).insert(
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

  @override
  Future<void> addLinksModuleWithTitle({
    required String ideaId,
    required String title,
  }) async {
    final now = DateTime.now();
    final sortOrder = await _nextModuleSortOrder(ideaId);
    final trimmed = title.trim();
    await db.into(db.ideaModules).insert(
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

  @override
  Future<void> renameModule(String moduleId, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    await (db.update(db.ideaModules)
          ..where((tbl) => tbl.id.equals(moduleId)))
        .write(
      IdeaModulesCompanion(
        title: Value(trimmed),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteModule(String moduleId) async {
    await db.transaction(() async {
      await (db.delete(db.ideaChecklistItems)
            ..where((tbl) => tbl.moduleId.equals(moduleId)))
          .go();
      await (db.delete(db.ideaLinkItems)
            ..where((tbl) => tbl.moduleId.equals(moduleId)))
          .go();
      await (db.delete(db.ideaModules)
            ..where((tbl) => tbl.id.equals(moduleId)))
          .go();
    });
  }

  @override
  Future<void> reorderModules({
    required List<IdeaModuleModel> modules,
    required int oldIndex,
    required int newIndex,
  }) async {
    if (oldIndex < 0 || oldIndex >= modules.length) return;
    if (newIndex < 0 || newIndex > modules.length) return;
    final reordered = List<IdeaModuleModel>.from(modules);
    final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(adjusted, moved);
    await db.batch((batch) {
      for (var i = 0; i < reordered.length; i++) {
        batch.update(
          db.ideaModules,
          IdeaModulesCompanion(
            sortOrder: Value(i),
            updatedAt: Value(DateTime.now()),
          ),
          where: (tbl) => tbl.id.equals(reordered[i].id),
        );
      }
    });
  }

  // ─── Checklist Items ─────────────────────────────────────

  @override
  Stream<List<IdeaChecklistItemModel>> watchChecklistItems(String moduleId) {
    final query = db.select(db.ideaChecklistItems)
      ..where((tbl) => tbl.moduleId.equals(moduleId))
      ..orderBy([
        (tbl) => OrderingTerm.asc(tbl.sortOrder),
        (tbl) => OrderingTerm.asc(tbl.createdAt),
      ]);
    return query.watch().map((list) => list.map(_toChecklistItem).toList());
  }

  @override
  Future<void> addChecklistItem(String moduleId) =>
      addChecklistItemWithContent(moduleId: moduleId, content: 'Neuer Punkt');

  @override
  Future<void> addChecklistItemWithContent({
    required String moduleId,
    required String content,
  }) async {
    final now = DateTime.now();
    final sortOrder = await _nextChecklistItemSortOrder(moduleId);
    final trimmed = content.trim();
    await db.into(db.ideaChecklistItems).insert(
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

  @override
  Future<void> updateChecklistItem({
    required String itemId,
    required String content,
    required bool isDone,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;
    await (db.update(db.ideaChecklistItems)
          ..where((tbl) => tbl.id.equals(itemId)))
        .write(
      IdeaChecklistItemsCompanion(
        content: Value(trimmed),
        isDone: Value(isDone),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> toggleChecklistItem({
    required String itemId,
    required bool isDone,
  }) async {
    await (db.update(db.ideaChecklistItems)
          ..where((tbl) => tbl.id.equals(itemId)))
        .write(
      IdeaChecklistItemsCompanion(
        isDone: Value(isDone),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteChecklistItem(String itemId) async {
    await (db.delete(db.ideaChecklistItems)
          ..where((tbl) => tbl.id.equals(itemId)))
        .go();
  }

  @override
  Future<void> reorderChecklistItems({
    required List<IdeaChecklistItemModel> items,
    required int oldIndex,
    required int newIndex,
  }) async {
    if (oldIndex < 0 || oldIndex >= items.length) return;
    if (newIndex < 0 || newIndex > items.length) return;
    final reordered = List<IdeaChecklistItemModel>.from(items);
    final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(adjusted, moved);
    await db.batch((batch) {
      for (var i = 0; i < reordered.length; i++) {
        batch.update(
          db.ideaChecklistItems,
          IdeaChecklistItemsCompanion(
            sortOrder: Value(i),
            updatedAt: Value(DateTime.now()),
          ),
          where: (tbl) => tbl.id.equals(reordered[i].id),
        );
      }
    });
  }

  // ─── Link Items ───────────────────────────────────────────

  @override
  Stream<List<IdeaLinkItemModel>> watchLinkItems(String moduleId) {
    final query = db.select(db.ideaLinkItems)
      ..where((tbl) => tbl.moduleId.equals(moduleId))
      ..orderBy([
        (tbl) => OrderingTerm.asc(tbl.sortOrder),
        (tbl) => OrderingTerm.asc(tbl.createdAt),
      ]);
    return query.watch().map((list) => list.map(_toLinkItem).toList());
  }

  @override
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

  @override
  Future<void> updateLinkItem({
    required String itemId,
    required String url,
    String? label,
  }) async {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) return;
    await (db.update(db.ideaLinkItems)
          ..where((tbl) => tbl.id.equals(itemId)))
        .write(
      IdeaLinkItemsCompanion(
        url: Value(trimmedUrl),
        label: Value(
          label == null || label.trim().isEmpty ? null : label.trim(),
        ),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteLinkItem(String itemId) async {
    await (db.delete(db.ideaLinkItems)
          ..where((tbl) => tbl.id.equals(itemId)))
        .go();
  }

  @override
  Future<void> reorderLinkItems({
    required List<IdeaLinkItemModel> items,
    required int oldIndex,
    required int newIndex,
  }) async {
    if (oldIndex < 0 || oldIndex >= items.length) return;
    if (newIndex < 0 || newIndex > items.length) return;
    final reordered = List<IdeaLinkItemModel>.from(items);
    final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(adjusted, moved);
    await db.batch((batch) {
      for (var i = 0; i < reordered.length; i++) {
        batch.update(
          db.ideaLinkItems,
          IdeaLinkItemsCompanion(
            sortOrder: Value(i),
            updatedAt: Value(DateTime.now()),
          ),
          where: (tbl) => tbl.id.equals(reordered[i].id),
        );
      }
    });
  }

  // ─── Sort Order Helpers ───────────────────────────────────

  Future<int> _nextModuleSortOrder(String ideaId) async {
    final modules = await (db.select(db.ideaModules)
          ..where((tbl) => tbl.ideaId.equals(ideaId)))
        .get();
    if (modules.isEmpty) return 0;
    return modules.map((m) => m.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<int> _nextChecklistItemSortOrder(String moduleId) async {
    final items = await (db.select(db.ideaChecklistItems)
          ..where((tbl) => tbl.moduleId.equals(moduleId)))
        .get();
    if (items.isEmpty) return 0;
    return items.map((i) => i.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<int> _nextLinkItemSortOrder(String moduleId) async {
    final items = await (db.select(db.ideaLinkItems)
          ..where((tbl) => tbl.moduleId.equals(moduleId)))
        .get();
    if (items.isEmpty) return 0;
    return items.map((i) => i.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
  }

  // ─── Helpers ─────────────────────────────────────────────

  @override
  Future<void> createIdeaFromCapture({
    required String description,
    String? title,
  }) async {
    final clean = description.trim();
    if (clean.isEmpty) return;
    final now = DateTime.now();
    await db.insertIdea(
      IdeasCompanion(
        id: Value(uuid.v4()),
        title: Value(_buildFallbackTitle(explicitTitle: title, description: clean)),
        description: Value(clean),
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
    final clean = explicitTitle?.trim();
    if (clean != null && clean.isNotEmpty) return clean;
    final normalized = description
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) return 'Neue Idee';
    const maxLength = 60;
    if (normalized.length <= maxLength) return normalized;
    return '${normalized.substring(0, maxLength).trim()}\u2026';
  }
}
