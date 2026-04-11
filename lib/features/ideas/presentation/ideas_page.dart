import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ideas_app/features/ideas/presentation/widgets/idea_list_item.dart';
import 'package:ideas_app/features/settings/settings_page.dart';
import 'package:ideas_app/features/archive/ui/archive_page.dart';
import '../logic/providers.dart';

class IdeasPage extends ConsumerStatefulWidget {
  const IdeasPage({super.key});

  @override
  ConsumerState<IdeasPage> createState() => _IdeasPageState();
}

class _IdeasPageState extends ConsumerState<IdeasPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSaving = false;

  bool get _canSubmit => _controller.text.trim().isNotEmpty && !_isSaving;

  @override
  void initState() {
    super.initState();

    _controller.addListener(() {
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _createIdea() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(ideaRepositoryProvider);
      await repo.createIdea(text);
      _controller.clear();

      if (mounted) {
        _focusNode.requestFocus();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ideasAsync = ref.watch(ideasProvider);
    final archivedIdeasCount = ref.watch(archivedIdeasCountProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ideen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Einstellungen',
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _canSubmit ? _createIdea() : null,
              decoration: InputDecoration(
                hintText: 'Was ist deine Idee?',
                border: const OutlineInputBorder(),
                suffixIcon: IgnorePointer(
                  ignoring: !_canSubmit,
                  child: IconButton(
                    onPressed: _createIdea,
                    icon: AnimatedOpacity(
                      opacity: _controller.text.trim().isEmpty && !_isSaving
                          ? 0.25
                          : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : const Icon(Icons.arrow_circle_right_outlined),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ideasAsync.when(
              data: (ideas) {
                return ListView(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.archive_outlined),
                      title: const Text('Archiv'),
                      trailing: archivedIdeasCount > 0
                          ? Text(
                              '$archivedIdeasCount',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            )
                          : null,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ArchivePage(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    if (ideas.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('Schreib oben deine erste Idee auf'),
                        ),
                      )
                    else
                      ...ideas.map(
                        (idea) => IdeaListItem(
                          key: ValueKey(idea.id),
                          idea: idea,
                          isArchivedView: false,
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Fehler: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
