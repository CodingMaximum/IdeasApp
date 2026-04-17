import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ideas_app/domain/models/idea_model.dart';
import 'package:ideas_app/domain/models/category_model.dart';
import 'package:ideas_app/domain/models/idea_status_model.dart';
import 'package:ideas_app/domain/models/idea_module_model.dart';
import 'package:ideas_app/domain/models/idea_checklist_item_model.dart';
import 'package:ideas_app/domain/models/idea_link_item_model.dart';
import 'package:ideas_app/data/repositories/local/drift_idea_repository.dart';
import 'package:ideas_app/features/ideas/application/quick_capture_controller.dart';
import 'package:ideas_app/features/ideas/application/quick_capture_state.dart';
import 'package:ideas_app/features/ideas/data/speech/speech_recognition_service.dart';
import 'package:ideas_app/features/ideas/data/speech/speech_to_text_service.dart';
import 'package:ideas_app/core/services/speech_settings_service.dart';
import 'package:ideas_app/features/ideas/data/speech/speech_locale_option.dart';
import 'package:ideas_app/data/repositories/idea_repository_interface.dart';
import 'package:ideas_app/core/utils/platform.dart';
import 'package:ideas_app/data/repositories/remote/supabase_idea_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ideas_app/data/repositories/repository_factory.dart';

final userIdProvider = Provider<String>((ref) => throw UnimplementedError());

final databaseProvider = Provider<dynamic>((ref) {
  if (usesRemoteRepository) return null;
  final db = createDatabase();
  ref.keepAlive();                    // ← niemals disposen
  ref.onDispose(() => db.close());    // trotzdem cleanup wenn App beendet
  return db;
});
final ideaRepositoryProvider = Provider<IIdeaRepository>((ref) {
  ref.keepAlive();                    // ← Repository-Instanz stabil halten
  final userId = ref.watch(userIdProvider);
  if (usesRemoteRepository) {
    return SupabaseIdeaRepository(Supabase.instance.client, userId);
  }
  final db = ref.watch(databaseProvider);
  return createLocalRepository(db, userId);
});

final ideasProvider = StreamProvider<List<IdeaModel>>((ref) {
  final repo = ref.watch(ideaRepositoryProvider);
  return repo.watchIdeas();
});

final categoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  final repo = ref.watch(ideaRepositoryProvider);
  return repo.watchCategories();
});

final ideaStatusesProvider = StreamProvider<List<IdeaStatusModel>>((ref) {
  final repo = ref.watch(ideaRepositoryProvider);
  return repo.watchIdeaStatuses();
});

final ideaByIdProvider = StreamProvider.family<IdeaModel?, String>((ref, ideaId) {
  final repo = ref.watch(ideaRepositoryProvider);
  return repo.watchIdeaById(ideaId);
});

final archivedIdeasProvider = StreamProvider<List<IdeaModel>>((ref) {
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

final ideaModulesProvider =
    StreamProvider.family<List<IdeaModuleModel>, String>((ref, ideaId) {
  final repo = ref.watch(ideaRepositoryProvider);
  return repo.watchModulesForIdea(ideaId);
});

final ideaChecklistItemsProvider =
    StreamProvider.family<List<IdeaChecklistItemModel>, String>(
        (ref, moduleId) {
  final repo = ref.watch(ideaRepositoryProvider);
  return repo.watchChecklistItems(moduleId);
});

final ideaLinkItemsProvider =
    StreamProvider.family<List<IdeaLinkItemModel>, String>((ref, moduleId) {
  final repo = ref.watch(ideaRepositoryProvider);
  return repo.watchLinkItems(moduleId);
});

final speechRecognitionServiceProvider = Provider<SpeechRecognitionService>(
  (ref) => SpeechToTextService(),
);

final quickCaptureControllerProvider =
    NotifierProvider<QuickCaptureController, QuickCaptureState>(
  QuickCaptureController.new,
);

final speechSettingsServiceProvider = Provider<SpeechSettingsService>((ref) {
  return SpeechSettingsService();
});

final selectedSpeechLocaleIdProvider = FutureProvider<String?>((ref) async {
  final service = ref.watch(speechSettingsServiceProvider);
  return service.getSpeechLocaleId();
});

final availableSpeechLocalesProvider =
    FutureProvider<List<SpeechLocaleOption>>((ref) async {
  final speech = ref.watch(speechRecognitionServiceProvider);
  final initialized = await speech.initialize(
    onResult: (_, __) {},
    onStatus: (_) {},
    onError: (_) {},
  );
  if (!initialized) return [];
  return speech.getAvailableLocales();
});
