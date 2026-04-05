import 'package:ideas_app/data/db/seed_ids.dart';
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
}
