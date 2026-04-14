import 'speech_locale_option.dart';

abstract class SpeechRecognitionService {
  Future<bool> initialize({
    required void Function(String text, bool isFinal) onResult,
    required void Function(String status) onStatus,
    required void Function(String errorMessage) onError,
  });

  Future<List<SpeechLocaleOption>> getAvailableLocales();
  Future<String?> getSystemLocaleId();

  Future<void> startListening({String? localeId});
  Future<void> stopListening();
  Future<void> cancelListening();

  bool get isListening;
  bool get isAvailable;
}