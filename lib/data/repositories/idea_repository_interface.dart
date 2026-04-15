import 'package:ideas_app/domain/models/idea_model.dart';
import 'package:ideas_app/domain/models/category_model.dart';
import 'package:ideas_app/domain/models/idea_status_model.dart';
import 'package:ideas_app/domain/models/idea_module_model.dart';
import 'package:ideas_app/domain/models/idea_checklist_item_model.dart';
import 'package:ideas_app/domain/models/idea_link_item_model.dart';

// ignore_for_file: one_member_abstracts
abstract class IIdeaRepository {
  // ── Ideas ──────────────────────────────────────────────────────────────────
  Stream<List<IdeaModel>> watchIdeas();
  Stream<List<IdeaModel>> watchArchivedIdeas();
  Stream<IdeaModel?> watchIdeaById(String id);
  Future<IdeaModel?> getIdeaById(String id);

  Future<void> createIdea(String title);
  Future<void> createIdeaFromCapture({
    required String description,
    String? title,
  });
  Future<void> updateIdea({
    required String id,
    required String title,
    required String description,
  });
  Future<void> renameIdea(String id, String title);
  Future<void> deleteIdea(String id);
  Future<void> deleteIdeaPermanently(String id);
  Future<void> restoreIdea(String id);
  Future<void> archiveIdea(String id);
  Future<void> unarchiveIdea(String id);

  Future<void> updateIdeaCategory(String id, String categoryId);
  Future<void> updateIdeaStatus(String id, String statusId);

  // ── Categories & Statuses ──────────────────────────────────────────────────
  Stream<List<CategoryModel>> watchCategories();
  Stream<List<IdeaStatusModel>> watchIdeaStatuses();

  // ── Modules ────────────────────────────────────────────────────────────────
  Stream<List<IdeaModuleModel>> watchModulesForIdea(String ideaId);
  Future<void> addChecklistModule(String ideaId);
  Future<void> addLinksModule(String ideaId);
  Future<void> addChecklistModuleWithTitle({
    required String ideaId,
    required String title,
  });
  Future<void> addLinksModuleWithTitle({
    required String ideaId,
    required String title,
  });
  Future<void> renameModule(String moduleId, String title);
  Future<void> deleteModule(String moduleId);
  Future<void> reorderModules({
    required List<IdeaModuleModel> modules,
    required int oldIndex,
    required int newIndex,
  });

  // ── Checklist Items ────────────────────────────────────────────────────────
  Stream<List<IdeaChecklistItemModel>> watchChecklistItems(String moduleId);
  Future<void> addChecklistItem(String moduleId);
  Future<void> addChecklistItemWithContent({
    required String moduleId,
    required String content,
  });
  Future<void> updateChecklistItem({
    required String itemId,
    required String content,
    required bool isDone,
  });
  Future<void> toggleChecklistItem({
    required String itemId,
    required bool isDone,
  });
  Future<void> deleteChecklistItem(String itemId);
  Future<void> reorderChecklistItems({
    required List<IdeaChecklistItemModel> items,
    required int oldIndex,
    required int newIndex,
  });

  // ── Link Items ─────────────────────────────────────────────────────────────
  Stream<List<IdeaLinkItemModel>> watchLinkItems(String moduleId);
  Future<void> addLinkItem({
    required String moduleId,
    required String url,
    String? label,
  });
  Future<void> updateLinkItem({
    required String itemId,
    required String url,
    String? label,
  });
  Future<void> deleteLinkItem(String itemId);
  Future<void> reorderLinkItems({
    required List<IdeaLinkItemModel> items,
    required int oldIndex,
    required int newIndex,
  });
}
