import 'package:ideas_app/data/db/app_database.dart';
import 'package:ideas_app/data/db/seed_ids.dart';
import 'package:ideas_app/data/enums/idea_module_type.dart';
import 'package:ideas_app/data/repositories/idea_repository_interface.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseIdeaRepository implements IIdeaRepository {
  final SupabaseClient _client;
  final String userId;
  final _uuid = const Uuid();

  SupabaseIdeaRepository(this._client, this.userId);

  // ─── Ideas ───────────────────────────────────────────────

  @override
  Stream<List<Idea>> watchIdeas() {
    return _client
        .from('ideas')
        .stream(primaryKey: ['id'])
        .eq('created_by', userId)
        .order('created_at', ascending: false)
        .map((rows) => rows
            .where((r) => r['deleted_at'] == null && r['archived_at'] == null)
            .map(_rowToIdea)
            .toList());
  }

  @override
  Stream<List<Idea>> watchArchivedIdeas() {
    return _client
        .from('ideas')
        .stream(primaryKey: ['id'])
        .eq('created_by', userId)
        .order('archived_at', ascending: false)
        .map((rows) => rows
            .where((r) => r['archived_at'] != null && r['deleted_at'] == null)
            .map(_rowToIdea)
            .toList());
  }

  @override
  Stream<Idea?> watchIdeaById(String id) {
    return _client
        .from('ideas')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((rows) => rows.isEmpty ? null : _rowToIdea(rows.first));
  }

  @override
  Future<Idea?> getIdeaById(String id) async {
    final res = await _client
        .from('ideas')
        .select()
        .eq('id', id)
        .maybeSingle();
    return res == null ? null : _rowToIdea(res);
  }

  @override
  Future<void> createIdea(String title) async {
    final now = DateTime.now().toIso8601String();
    await _client.from('ideas').insert({
      'id': _uuid.v4(),
      'title': title,
      'status_id': SeedIds.planningStatus,
      'created_by': userId,
      'created_at': now,
      'updated_at': now,
    });
  }

  @override
  Future<void> createIdeaFromCapture({
    required String description,
    String? title,
  }) async {
    final clean = description.trim();
    if (clean.isEmpty) return;
    final now = DateTime.now().toIso8601String();
    await _client.from('ideas').insert({
      'id': _uuid.v4(),
      'title': _buildFallbackTitle(explicitTitle: title, description: clean),
      'description': clean,
      'status_id': SeedIds.planningStatus,
      'created_by': userId,
      'created_at': now,
      'updated_at': now,
    });
  }

  @override
  Future<void> updateIdea({
    required String id,
    required String title,
    required String description,
  }) async {
    await _client.from('ideas').update({
      'title': title,
      'description': description.isEmpty ? null : description,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<void> renameIdea(String id, String title) async {
    await _client.from('ideas').update({
      'title': title,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<void> deleteIdea(String id) async {
    await _client.from('ideas').update({
      'deleted_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<void> deleteIdeaPermanently(String id) async {
    await _client.from('ideas').delete().eq('id', id);
  }

  @override
  Future<void> restoreIdea(String id) async {
    await _client.from('ideas').update({
      'deleted_at': null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<void> archiveIdea(String id) async {
    await _client.from('ideas').update({
      'archived_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<void> unarchiveIdea(String id) async {
    await _client.from('ideas').update({
      'archived_at': null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<void> updateIdeaCategory(String id, String categoryId) async {
    await _client.from('ideas').update({
      'category_id': categoryId,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<void> updateIdeaStatus(String id, String statusId) async {
    await _client.from('ideas').update({
      'status_id': statusId,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  // ─── Categories & Statuses ───────────────────────────────

  @override
  Stream<List<Category>> watchCategories() {
    return _client
        .from('categories')
        .stream(primaryKey: ['id'])
        .order('sort_order')
        .map((rows) => rows.map(_rowToCategory).toList());
  }

  @override
  Stream<List<IdeaStatuse>> watchIdeaStatuses() {
    return _client
        .from('idea_statuses')
        .stream(primaryKey: ['id'])
        .order('sort_order')
        .map((rows) => rows.map(_rowToStatus).toList());
  }

  // ─── Modules ─────────────────────────────────────────────

  @override
  Stream<List<IdeaModule>> watchModulesForIdea(String ideaId) {
    return _client
        .from('idea_modules')
        .stream(primaryKey: ['id'])
        .eq('idea_id', ideaId)
        .order('sort_order')
        .map((rows) => rows.map(_rowToModule).toList());
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
    final sortOrder = await _nextModuleSortOrder(ideaId);
    final now = DateTime.now().toIso8601String();
    await _client.from('idea_modules').insert({
      'id': _uuid.v4(),
      'idea_id': ideaId,
      'type': IdeaModuleType.checklist.name,
      'title': title.trim().isEmpty ? 'Neue Checkliste' : title.trim(),
      'sort_order': sortOrder,
      'created_at': now,
      'updated_at': now,
    });
  }

  @override
  Future<void> addLinksModuleWithTitle({
    required String ideaId,
    required String title,
  }) async {
    final sortOrder = await _nextModuleSortOrder(ideaId);
    final now = DateTime.now().toIso8601String();
    await _client.from('idea_modules').insert({
      'id': _uuid.v4(),
      'idea_id': ideaId,
      'type': IdeaModuleType.links.name,
      'title': title.trim().isEmpty ? 'Neue Links' : title.trim(),
      'sort_order': sortOrder,
      'created_at': now,
      'updated_at': now,
    });
  }

  @override
  Future<void> renameModule(String moduleId, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    await _client.from('idea_modules').update({
      'title': trimmed,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', moduleId);
  }

  @override
  Future<void> deleteModule(String moduleId) async {
    // cascade delete via FK in Supabase — nur Modul löschen reicht
    await _client.from('idea_modules').delete().eq('id', moduleId);
  }

  @override
  Future<void> reorderModules({
    required List<IdeaModule> modules,
    required int oldIndex,
    required int newIndex,
  }) async {
    final reordered = List<IdeaModule>.from(modules);
    final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(adjusted, moved);

    for (var i = 0; i < reordered.length; i++) {
      await _client.from('idea_modules').update({
        'sort_order': i,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', reordered[i].id);
    }
  }

  // ─── Checklist Items ─────────────────────────────────────

  @override
  Stream<List<IdeaChecklistItem>> watchChecklistItems(String moduleId) {
    return _client
        .from('idea_checklist_items')
        .stream(primaryKey: ['id'])
        .eq('module_id', moduleId)
        .order('sort_order')
        .map((rows) => rows.map(_rowToChecklistItem).toList());
  }

  @override
  Future<void> addChecklistItem(String moduleId) =>
      addChecklistItemWithContent(moduleId: moduleId, content: 'Neuer Punkt');

  @override
  Future<void> addChecklistItemWithContent({
    required String moduleId,
    required String content,
  }) async {
    final sortOrder = await _nextChecklistItemSortOrder(moduleId);
    final now = DateTime.now().toIso8601String();
    await _client.from('idea_checklist_items').insert({
      'id': _uuid.v4(),
      'module_id': moduleId,
      'content': content.trim().isEmpty ? 'Neuer Punkt' : content.trim(),
      'sort_order': sortOrder,
      'created_at': now,
      'updated_at': now,
    });
  }

  @override
  Future<void> updateChecklistItem({
    required String itemId,
    required String content,
    required bool isDone,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;
    await _client.from('idea_checklist_items').update({
      'content': trimmed,
      'is_done': isDone,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', itemId);
  }

  @override
  Future<void> toggleChecklistItem({
    required String itemId,
    required bool isDone,
  }) async {
    await _client.from('idea_checklist_items').update({
      'is_done': isDone,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', itemId);
  }

  @override
  Future<void> deleteChecklistItem(String itemId) async {
    await _client.from('idea_checklist_items').delete().eq('id', itemId);
  }

  @override
  Future<void> reorderChecklistItems({
    required List<IdeaChecklistItem> items,
    required int oldIndex,
    required int newIndex,
  }) async {
    final reordered = List<IdeaChecklistItem>.from(items);
    final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(adjusted, moved);

    for (var i = 0; i < reordered.length; i++) {
      await _client.from('idea_checklist_items').update({
        'sort_order': i,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', reordered[i].id);
    }
  }

  // ─── Link Items ───────────────────────────────────────────

  @override
  Stream<List<IdeaLinkItem>> watchLinkItems(String moduleId) {
    return _client
        .from('idea_link_items')
        .stream(primaryKey: ['id'])
        .eq('module_id', moduleId)
        .order('sort_order')
        .map((rows) => rows.map(_rowToLinkItem).toList());
  }

  @override
  Future<void> addLinkItem({
    required String moduleId,
    required String url,
    String? label,
  }) async {
    final sortOrder = await _nextLinkItemSortOrder(moduleId);
    final now = DateTime.now().toIso8601String();
    await _client.from('idea_link_items').insert({
      'id': _uuid.v4(),
      'module_id': moduleId,
      'url': url.trim(),
      'label': label?.trim().isEmpty ?? true ? null : label!.trim(),
      'sort_order': sortOrder,
      'created_at': now,
      'updated_at': now,
    });
  }

  @override
  Future<void> updateLinkItem({
    required String itemId,
    required String url,
    String? label,
  }) async {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) return;
    await _client.from('idea_link_items').update({
      'url': trimmedUrl,
      'label': label?.trim().isEmpty ?? true ? null : label!.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', itemId);
  }

  @override
  Future<void> deleteLinkItem(String itemId) async {
    await _client.from('idea_link_items').delete().eq('id', itemId);
  }

  @override
  Future<void> reorderLinkItems({
    required List<IdeaLinkItem> items,
    required int oldIndex,
    required int newIndex,
  }) async {
    final reordered = List<IdeaLinkItem>.from(items);
    final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(adjusted, moved);

    for (var i = 0; i < reordered.length; i++) {
      await _client.from('idea_link_items').update({
        'sort_order': i,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', reordered[i].id);
    }
  }

  // ─── Sort Order Helpers ───────────────────────────────────

  Future<int> _nextModuleSortOrder(String ideaId) async {
    final res = await _client
        .from('idea_modules')
        .select('sort_order')
        .eq('idea_id', ideaId)
        .order('sort_order', ascending: false)
        .limit(1);
    if (res.isEmpty) return 0;
    return (res.first['sort_order'] as int) + 1;
  }

  Future<int> _nextChecklistItemSortOrder(String moduleId) async {
    final res = await _client
        .from('idea_checklist_items')
        .select('sort_order')
        .eq('module_id', moduleId)
        .order('sort_order', ascending: false)
        .limit(1);
    if (res.isEmpty) return 0;
    return (res.first['sort_order'] as int) + 1;
  }

  Future<int> _nextLinkItemSortOrder(String moduleId) async {
    final res = await _client
        .from('idea_link_items')
        .select('sort_order')
        .eq('module_id', moduleId)
        .order('sort_order', ascending: false)
        .limit(1);
    if (res.isEmpty) return 0;
    return (res.first['sort_order'] as int) + 1;
  }

  // ─── Row Mappers ──────────────────────────────────────────

  Idea _rowToIdea(Map<String, dynamic> r) => Idea(
        id: r['id'],
        title: r['title'],
        description: r['description'],
        statusId: r['status_id'],
        categoryId: r['category_id'],
        createdBy: r['created_by'],
        createdAt: DateTime.parse(r['created_at']),
        updatedAt: DateTime.parse(r['updated_at']),
        deletedAt: r['deleted_at'] != null ? DateTime.parse(r['deleted_at']) : null,
        archivedAt: r['archived_at'] != null ? DateTime.parse(r['archived_at']) : null,
      );

  Category _rowToCategory(Map<String, dynamic> r) => Category(
        id: r['id'],
        name: r['name'],
        isSystem: r['is_system'] ?? false,
        sortOrder: r['sort_order'] ?? 0,
        createdAt: DateTime.parse(r['created_at']),
        updatedAt: DateTime.parse(r['updated_at']),
      );

  IdeaStatuse _rowToStatus(Map<String, dynamic> r) => IdeaStatuse(
        id: r['id'],
        name: r['name'],
        isSystem: r['is_system'] ?? false,
        sortOrder: r['sort_order'] ?? 0,
        createdAt: DateTime.parse(r['created_at']),
        updatedAt: DateTime.parse(r['updated_at']),
      );

  IdeaModule _rowToModule(Map<String, dynamic> r) => IdeaModule(
        id: r['id'],
        ideaId: r['idea_id'],
        type: IdeaModuleType.values.byName(r['type']),
        title: r['title'],
        sortOrder: r['sort_order'] ?? 0,
        createdAt: DateTime.parse(r['created_at']),
        updatedAt: DateTime.parse(r['updated_at']),
      );

  IdeaChecklistItem _rowToChecklistItem(Map<String, dynamic> r) =>
      IdeaChecklistItem(
        id: r['id'],
        moduleId: r['module_id'],
        content: r['content'],
        isDone: r['is_done'] ?? false,
        sortOrder: r['sort_order'] ?? 0,
        createdAt: DateTime.parse(r['created_at']),
        updatedAt: DateTime.parse(r['updated_at']),
      );

  IdeaLinkItem _rowToLinkItem(Map<String, dynamic> r) => IdeaLinkItem(
        id: r['id'],
        moduleId: r['module_id'],
        url: r['url'],
        label: r['label'],
        sortOrder: r['sort_order'] ?? 0,
        createdAt: DateTime.parse(r['created_at']),
        updatedAt: DateTime.parse(r['updated_at']),
      );

  // ─── Helpers ─────────────────────────────────────────────

  String _buildFallbackTitle({String? explicitTitle, required String description}) {
    final clean = explicitTitle?.trim();
    if (clean != null && clean.isNotEmpty) return clean;
    final normalized = description.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) return 'Neue Idee';
    const maxLength = 60;
    if (normalized.length <= maxLength) return normalized;
    return '${normalized.substring(0, maxLength).trim()}…';
  }
}