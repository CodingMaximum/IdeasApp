import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ideas_app/data/repositories/idea_repository.dart';
import 'package:ideas_app/features/ideas/application/quick_capture_state.dart';
import 'package:ideas_app/features/ideas/data/speech/speech_recognition_service.dart';
import 'package:ideas_app/features/ideas/logic/providers.dart';
import 'package:ideas_app/core/services/speech_settings_service.dart';

class QuickCaptureController extends Notifier<QuickCaptureState> {
  late final IdeaRepository _repo;
  late final SpeechRecognitionService _speech;
  late final SpeechSettingsService _speechSettings;
  @override
  QuickCaptureState build() {
    _repo = ref.read(ideaRepositoryProvider);
    _speech = ref.read(speechRecognitionServiceProvider);
    _speechSettings = ref.read(speechSettingsServiceProvider);

    ref.onDispose(() async {
      await _speech.cancelListening();
    });

    return const QuickCaptureState();
  }

  Future<void> initializeSpeech() async {
    if (state.isSpeechInitialized) return;

    try {
      final available = await _speech.initialize(
        onResult: (text, isFinal) {
          state = state.copyWith(text: text, clearError: true);
        },
        onStatus: (status) {
          final listening = status.toLowerCase().contains('listening');
          state = state.copyWith(isListening: listening);
        },
        onError: (message) {
          state = state.copyWith(isListening: false, errorMessage: message);
        },
      );

      state = state.copyWith(
        speechAvailable: available,
        isSpeechInitialized: true,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        speechAvailable: false,
        isSpeechInitialized: true,
        errorMessage: 'Speech-to-Text konnte nicht initialisiert werden: $e',
      );
    }
  }

  void updateText(String value) {
    state = state.copyWith(text: value, clearError: true);
  }

  Future<void> toggleListening() async {
    if (!state.isSpeechInitialized) {
      await initializeSpeech();
    }

    if (!state.speechAvailable) {
      state = state.copyWith(
        errorMessage:
            'Spracheingabe ist auf diesem Gerät oder Browser nicht verfügbar.',
      );
      return;
    }

    try {
      if (_speech.isListening) {
        await _speech.stopListening();
        state = state.copyWith(isListening: false);
      } else {
        final savedLocaleId = await _speechSettings.getSpeechLocaleId();

        // Falls nichts gespeichert: Systemsprache explizit abfragen
        final localeId = savedLocaleId ?? await _speech.getSystemLocaleId();
        await _speech.startListening(localeId: localeId);
        state = state.copyWith(clearError: true);
      }
    } catch (e) {
      state = state.copyWith(
        isListening: false,
        errorMessage: 'Spracherkennung konnte nicht gestartet werden: $e',
      );
    }
  }

  Future<void> submit() async {
    final description = state.text.trim();
    if (description.isEmpty || state.isSaving) return;

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      if (_speech.isListening) {
        await _speech.stopListening();
      }

      await _repo.createIdeaFromCapture(description: description);

      state = state.copyWith(
        text: '',
        isSaving: false,
        isListening: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Idee konnte nicht gespeichert werden: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
