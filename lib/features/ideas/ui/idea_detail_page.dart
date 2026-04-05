import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ideas_app/data/db/app_database.dart';
import 'package:ideas_app/features/ideas/logic/providers.dart';
import 'package:ideas_app/features/ideas/ui/widgets/category_selection.dart';
import 'package:ideas_app/features/ideas/ui/widgets/status_selection.dart';

class IdeaDetailPage extends ConsumerWidget {
  final String ideaId;

  const IdeaDetailPage({super.key, required this.ideaId});

  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    Idea idea,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Idee löschen?'),
          content: const Text(
            'Die Idee wird aus der Übersicht entfernt. Du kannst sie danach direkt wiederherstellen.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Löschen'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await ref.read(ideaRepositoryProvider).deleteIdea(idea.id);

    if (!context.mounted) return;

    Navigator.of(
      context,
    ).pop({'action': 'deleted', 'ideaId': idea.id, 'title': idea.title});
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ideaAsync = ref.watch(ideaByIdProvider(ideaId));
    final categoriesAsync = ref.watch(categoriesProvider);
    final statusesAsync = ref.watch(ideaStatusesProvider);

    return ideaAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Fehler: $e')),
      ),
      data: (idea) {
        if (idea == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Idee nicht gefunden')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    idea.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Titel bearbeiten',
                  onPressed: () =>
                      _TitleSection.showRenameDialog(context, ref, idea),
                ),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'delete':
                      await _confirmAndDelete(context, ref, idea);
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'delete', child: Text('Löschen')),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              categoriesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CircularProgressIndicator(),
                ),
                error: (e, _) =>
                    Text('Kategorien konnten nicht geladen werden: $e'),
                data: (categories) => CategorySelection(
                  value: idea.categoryId,
                  categories: categories,
                  onChanged: (categoryId) async {
                    if (categoryId == null) return;
                    await ref
                        .read(ideaRepositoryProvider)
                        .updateIdeaCategory(idea.id, categoryId);
                  },
                ),
              ),
              const SizedBox(height: 16),
              statusesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CircularProgressIndicator(),
                ),
                error: (e, _) =>
                    Text('Status konnten nicht geladen werden: $e'),
                data: (statuses) => StatusSelection(
                  value: idea.statusId,
                  statuses: statuses,
                  onChanged: (statusId) async {
                    await ref
                        .read(ideaRepositoryProvider)
                        .updateIdeaStatus(idea.id, statusId);
                  },
                ),
              ),
              const SizedBox(height: 24),
              _DescriptionSection(idea: idea),
              const SizedBox(height: 24),
              Text(
                'Erstellt: ${idea.createdAt}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Aktualisiert: ${idea.updatedAt}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TitleSection {
  static Future<void> showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    Idea idea,
  ) async {
    final controller = TextEditingController(text: idea.title);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Titel bearbeiten'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Titel'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () async {
                final newTitle = controller.text.trim();
                if (newTitle.isEmpty) return;

                await ref
                    .read(ideaRepositoryProvider)
                    .updateIdea(
                      id: idea.id,
                      title: newTitle,
                      description: idea.description ?? '',
                    );

                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );
  }
}

class _DescriptionSection extends ConsumerStatefulWidget {
  final Idea idea;

  const _DescriptionSection({required this.idea});

  @override
  ConsumerState<_DescriptionSection> createState() =>
      _DescriptionSectionState();
}

class _DescriptionSectionState extends ConsumerState<_DescriptionSection> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String _lastSavedValue = '';

  @override
  void initState() {
    super.initState();
    _lastSavedValue = widget.idea.description ?? '';
    _controller = TextEditingController(text: _lastSavedValue);
    _focusNode = FocusNode();

    _focusNode.addListener(() async {
      if (!_focusNode.hasFocus) {
        await _saveIfChanged();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _DescriptionSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newValue = widget.idea.description ?? '';
    if (!_focusNode.hasFocus && newValue != _lastSavedValue) {
      _lastSavedValue = newValue;
      _controller.text = newValue;
    }
  }

  Future<void> _saveIfChanged() async {
    final newDescription = _controller.text.trim();
    if (newDescription == _lastSavedValue) return;

    await ref
        .read(ideaRepositoryProvider)
        .updateIdea(
          id: widget.idea.id,
          title: widget.idea.title,
          description: newDescription,
        );

    _lastSavedValue = newDescription;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          minLines: 6,
          maxLines: null,
          textInputAction: TextInputAction.newline,
          decoration: const InputDecoration(
            hintText: 'Noch keine Beschreibung',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
            label: Text('Beschreibung'),
          ),
          onSubmitted: (_) async => _saveIfChanged(),
          onTapOutside: (_) => _focusNode.unfocus(),
        ),
      ],
    );
  }
}
