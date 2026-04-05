import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ideas_app/data/db/app_database.dart';
import 'package:ideas_app/data/repositories/idea_repository.dart';

final userIdProvider = Provider<String>((ref) => throw UnimplementedError());

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final ideaRepositoryProvider = Provider<IdeaRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final userId = ref.watch(userIdProvider);
  return IdeaRepository(db, userId);
});

final ideasProvider = StreamProvider<List<Idea>>((ref) {
  final repo = ref.watch(ideaRepositoryProvider);
  return repo.watchIdeas();
});

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final repo = ref.watch(ideaRepositoryProvider);
  return repo.watchCategories();
});

final ideaStatusesProvider = StreamProvider<List<IdeaStatuse>>((ref) {
  final repo = ref.watch(ideaRepositoryProvider);
  return repo.watchIdeaStatuses();
});

final ideaByIdProvider = StreamProvider.family<Idea?, String>((ref, ideaId) {
  final repo = ref.watch(ideaRepositoryProvider);
  return repo.watchIdeaById(ideaId);
});

final archivedIdeasProvider = StreamProvider<List<Idea>>((ref) {
  final repo = ref.watch(ideaRepositoryProvider);
  return repo.watchArchivedIdeas();
});

final archivedIdeasCountProvider = Provider<int>((ref) {
  final archivedIdeasAsync = ref.watch(archivedIdeasProvider);
  return archivedIdeasAsync.maybeWhen(
    data: (ideas) => ideas.length,
    orElse: () => 0,
  );
});