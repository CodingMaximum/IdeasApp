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
        if (_controller.text != next.text) {
          _isApplyingExternalText = true;
          _controller.value = TextEditingValue(
            text: next.text,
            selection: TextSelection.collapsed(offset: next.text.length),
          );
          _isApplyingExternalText = false;
        }

        final wasSaving = previous?.isSaving ?? false;
        if (wasSaving && !next.isSaving && next.text.isEmpty && mounted) {
          _focusNode.requestFocus();
        }

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      ref.read(quickCaptureControllerProvider.notifier).initializeSpeech();
    });
  }

  void _onTextChanged() {
    if (_isApplyingExternalText) return;

    ref.read(quickCaptureControllerProvider.notifier).updateText(
          _controller.text,
        );
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
  Widget build(BuildContext context) {
    final state = ref.watch(quickCaptureControllerProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  minLines: 2,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'Sprich oder schreibe deine Idee…',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                    labelText: 'Beschreibung',
                  ),
                  onTap: () {
                    ref
                        .read(quickCaptureControllerProvider.notifier)
                        .clearError();
                  },
                  onTapOutside: (_) => _focusNode.unfocus(),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  Tooltip(
                    message: state.isListening
                        ? 'Aufnahme stoppen'
                        : 'Spracheingabe starten',
                    child: FilledButton.tonalIcon(
                      onPressed: state.isSaving
                          ? null
                          : () async {
                              await ref
                                  .read(
                                    quickCaptureControllerProvider.notifier,
                                  )
                                  .toggleListening();
                            },
                      icon: Icon(
                        state.isListening ? Icons.mic : Icons.mic_none,
                      ),
                      label: Text(state.isListening ? 'Stop' : 'Sprache'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Tooltip(
                    message: 'Idee speichern',
                    child: FilledButton.icon(
                      onPressed: state.canSubmit
                          ? () async {
                              await ref
                                  .read(
                                    quickCaptureControllerProvider.notifier,
                                  )
                                  .submit();
                            }
                          : null,
                      icon: state.isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_circle_right_outlined),
                      label: const Text('Speichern'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _buildStatusText(state),
              style: theme.textTheme.bodySmall?.copyWith(
                color: state.errorMessage != null
                    ? theme.colorScheme.error
                    : theme.textTheme.bodySmall?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildStatusText(QuickCaptureState state) {
    if (state.isSaving) {
      return 'Idee wird gespeichert…';
    }

    if (state.isListening) {
      return 'Höre zu… die Beschreibung wird live gefüllt.';
    }

    if (!state.isSpeechInitialized) {
      return 'Spracheingabe wird vorbereitet…';
    }

    if (!state.speechAvailable) {
      return 'Spracheingabe ist hier nicht verfügbar. Du kannst normal tippen.';
    }

    return 'Du kannst schreiben oder Spracheingabe nutzen.';
  }
}