import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ideas_app/features/ideas/application/quick_capture_state.dart';
import 'package:ideas_app/features/ideas/logic/providers.dart';

class QuickCaptureBar extends ConsumerStatefulWidget {
  const QuickCaptureBar({super.key});

  @override
  ConsumerState<QuickCaptureBar> createState() => _QuickCaptureBarState();
}

class _QuickCaptureBarState extends ConsumerState<QuickCaptureBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isApplyingExternalText = false;
  ProviderSubscription<QuickCaptureState>? _subscription;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController();
    _focusNode = FocusNode();
    _controller.addListener(_onTextChanged);

    _subscription = ref.listenManual<QuickCaptureState>(
      quickCaptureControllerProvider,
      (previous, next) {
        // Speech-Text ins Feld übernehmen
        if (_controller.text != next.text) {
          _isApplyingExternalText = true;
          _controller.value = TextEditingValue(
            text: next.text,
            selection: TextSelection.collapsed(offset: next.text.length),
          );
          _isApplyingExternalText = false;
        }

        // Nach erfolgreichem Speichern Fokus zurück
        final wasSaving = previous?.isSaving ?? false;
        if (wasSaving && !next.isSaving && next.text.isEmpty && mounted) {
          _focusNode.requestFocus();
        }

        // Fehler als SnackBar
        final errorChanged = previous?.errorMessage != next.errorMessage;
        if (errorChanged &&
            next.errorMessage != null &&
            next.errorMessage!.trim().isNotEmpty &&
            mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(next.errorMessage!),
                behavior: SnackBarBehavior.floating,
              ),
            );
        }
      },
    );

    // Speech sofort im Hintergrund initialisieren — kein await, damit UI
    // nicht blockiert wird und der erste Mic-Tap ohne Verzögerung reagiert.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(quickCaptureControllerProvider.notifier).initializeSpeech();
    });
  }

  void _onTextChanged() {
    if (_isApplyingExternalText) return;
    ref
        .read(quickCaptureControllerProvider.notifier)
        .updateText(_controller.text);
  }

  @override
  void dispose() {
    _subscription?.close();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context, ) {
    final state = ref.watch(quickCaptureControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isListening = state.isListening;
    final isSpeechReady = state.isSpeechInitialized && state.speechAvailable;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Neue Idee',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // Textfeld + Mic-Button nebeneinander
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mic-IconButton — schmal, volle Höhe des Textfelds
                    _MicButton(
                      isListening: isListening,
                      isReady: isSpeechReady,
                      isInitializing: !state.isSpeechInitialized,
                      isSaving: state.isSaving,
                      onTap: () async {
                        await ref
                            .read(quickCaptureControllerProvider.notifier)
                            .toggleListening();
                      },
                    ),
                    const SizedBox(width: 10),

                    // Textfeld — Rest der Breite
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        minLines: 4,
                        maxLines: 8,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: isSpeechReady
                              ? 'Tippe oder nutze das Mikrofon …'
                              : 'Beschreibe deine Idee …',
                          border: const OutlineInputBorder(),
                          alignLabelWithHint: true,
                          isDense: false,
                        ),
                        onTap: () {
                          ref
                              .read(quickCaptureControllerProvider.notifier)
                              .clearError();
                        },
                        onTapOutside: (_) => _focusNode.unfocus(),
                      ),
                    ),
                  ],
                ),
              ),

              // Statuszeile
              if (_statusText(state).isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  _statusText(state),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isListening
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Hinzufügen-Button
              FilledButton.icon(
                onPressed: state.canSubmit
                    ? () async {
                        await ref
                            .read(quickCaptureControllerProvider.notifier)
                            .submit();
                      }
                    : null,
                icon: state.isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add),
                label:
                    Text(state.isSaving ? 'Wird gespeichert …' : 'Hinzufügen'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusText(QuickCaptureState state) {
    if (state.isSaving) return '';
    if (!state.isSpeechInitialized) return 'Spracheingabe wird vorbereitet …';
    if (!state.speechAvailable) return 'Spracheingabe nicht verfügbar';
    if (state.isListening) return '🎙 Höre zu …';
    return '';
  }
}

/// Schmaler Mic-Button mit voller Höhe des Textfelds.
class _MicButton extends StatelessWidget {
  final bool isListening;
  final bool isReady;
  final bool isInitializing;
  final bool isSaving;
  final VoidCallback onTap;

  const _MicButton({
    required this.isListening,
    required this.isReady,
    required this.isInitializing,
    required this.isSaving,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final backgroundColor = isListening
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;

    final iconColor = isListening
        ? colorScheme.onPrimaryContainer
        : isReady
            ? colorScheme.onSurfaceVariant
            : colorScheme.outline;

    return Tooltip(
      message: isInitializing
          ? 'Spracheingabe wird initialisiert …'
          : !isReady
              ? 'Spracheingabe nicht verfügbar'
              : isListening
                  ? 'Aufnahme stoppen'
                  : 'Spracheingabe starten',
      child: InkWell(
        onTap: (isSaving || isInitializing || !isReady) ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 52,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: isListening
                ? Border.all(
                    color: colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: Center(
            child: isInitializing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.outline,
                    ),
                  )
                : Icon(
                    isListening ? Icons.mic : Icons.mic_none,
                    color: iconColor,
                    size: 26,
                  ),
          ),
        ),
      ),
    );
  }
}