import 'package:speech_to_text/speech_to_text.dart';

import 'speech_locale_option.dart';
import 'speech_recognition_service.dart';

class SpeechToTextService implements SpeechRecognitionService {
  final SpeechToText _speech = SpeechToText();

  bool _isAvailable = false;

  void Function(String text, bool isFinal)? _onResult;

  @override
  bool get isListening => _speech.isListening;

  @override
  bool get isAvailable => _isAvailable;

  @override
  Future<bool> initialize({
    required void Function(String text, bool isFinal) onResult,
    required void Function(String status) onStatus,
    required void Function(String errorMessage) onError,
  }) async {
    _onResult = onResult;

    _isAvailable = await _speech.initialize(
      onStatus: onStatus,
      onError: (error) {
        onError('${error.errorMsg} (permanent: ${error.permanent})');
      },
      debugLogging: false,
    );

    return _isAvailable;
  }

  @override
  Future<List<SpeechLocaleOption>> getAvailableLocales() async {
    final locales = await _speech.locales();

    return locales
        .map(
          (locale) =>
              SpeechLocaleOption(localeId: locale.localeId, name: locale.name),
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<String?> getSystemLocaleId() async {
    final locale = await _speech.systemLocale();
    return locale?.localeId;
  }

  @override
  Future<void> startListening({String? localeId}) async {
    if (!_isAvailable) return;

    await _speech.listen(
      onResult: (result) {
        _onResult?.call(result.recognizedWords, result.finalResult);
      },
      localeId: localeId,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation, // war confirmation → falsch
        cancelOnError: false, // fehlte → wichtig
        sampleRate: 44100, // fehlte → war sogar explizit als Fix kommentiert
      ),
    );
  }

  @override
  Future<void> stopListening() async {
    await _speech.stop();
  }

  @override
  Future<void> cancelListening() async {
    await _speech.cancel();
  }
}
