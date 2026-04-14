class QuickCaptureState {
  final String text;
  final bool isListening;
  final bool isSaving;
  final bool speechAvailable;
  final bool isSpeechInitialized;
  final String? errorMessage;

  const QuickCaptureState({
    this.text = '',
    this.isListening = false,
    this.isSaving = false,
    this.speechAvailable = false,
    this.isSpeechInitialized = false,
    this.errorMessage,
  });

  bool get canSubmit => text.trim().isNotEmpty && !isSaving;
  bool get hasText => text.trim().isNotEmpty;

  QuickCaptureState copyWith({
    String? text,
    bool? isListening,
    bool? isSaving,
    bool? speechAvailable,
    bool? isSpeechInitialized,
    String? errorMessage,
    bool clearError = false,
  }) {
    return QuickCaptureState(
      text: text ?? this.text,
      isListening: isListening ?? this.isListening,
      isSaving: isSaving ?? this.isSaving,
      speechAvailable: speechAvailable ?? this.speechAvailable,
      isSpeechInitialized: isSpeechInitialized ?? this.isSpeechInitialized,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}