import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ideas_app/data/db/app_database.dart';
import 'package:ideas_app/features/ideas/logic/providers.dart';
import 'package:ideas_app/features/ideas/ui/widgets/module_card_header.dart';
import 'package:ideas_app/features/ideas/ui/widgets/module_card_shell.dart';
import 'package:ideas_app/features/ideas/ui/widgets/module_dialogs.dart';


class IdeaChecklistModuleCard extends ConsumerWidget {
  final IdeaModule module;

  const IdeaChecklistModuleCard({
    super.key,
    required this.module,
  });

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

   Future<void> _showRenameModuleDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final newTitle = await showModuleRenameDialog(
      context: context,
      initialTitle: module.title,
    );

    if (newTitle == null || newTitle == module.title) return;

    await ref.read(ideaRepositoryProvider).renameModule(module.id, newTitle);

    if (context.mounted) {
      _showSnackBar(context, 'Modultitel gespeichert.');
    }
  }

  Future<void> _confirmDeleteModule(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDeleteModuleDialog(
      context: context,
      moduleTitle: module.title,
      contentTypeLabel: 'Punkte',
    );

    if (!confirmed) return;

    await ref.read(ideaRepositoryProvider).deleteModule(module.id);

    if (context.mounted) {
      _showSnackBar(context, 'Modul gelöscht.');
    }
  }

  Future<void> _showAddChecklistItemDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Punkt hinzufügen'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Inhalt',
              hintText: 'z. B. Domain sichern',
            ),
            onSubmitted: (_) async {
              final value = controller.text.trim();
              if (value.isEmpty) return;

              await ref.read(ideaRepositoryProvider).addChecklistItemWithContent(
                    moduleId: module.id,
                    content: value,
                  );

              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }

              if (context.mounted) {
                _showSnackBar(context, 'Punkt hinzugefügt.');
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () async {
                final value = controller.text.trim();
                if (value.isEmpty) return;

                await ref.read(ideaRepositoryProvider).addChecklistItemWithContent(
                      moduleId: module.id,
                      content: value,
                    );

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }

                if (context.mounted) {
                  _showSnackBar(context, 'Punkt hinzugefügt.');
                }
              },
              child: const Text('Hinzufügen'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditChecklistItemDialog(
    BuildContext context,
    WidgetRef ref,
    IdeaChecklistItem item,
  ) async {
    final controller = TextEditingController(text: item.content);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Punkt bearbeiten'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Inhalt',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () async {
                final value = controller.text.trim();
                if (value.isEmpty) return;

                await ref.read(ideaRepositoryProvider).updateChecklistItem(
                      itemId: item.id,
                      content: value,
                      isDone: item.isDone,
                    );

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }

                if (context.mounted) {
                  _showSnackBar(context, 'Punkt gespeichert.');
                }
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(ideaChecklistItemsProvider(module.id));

    return ModuleCardShell(
      header: ModuleCardHeader(
        icon: Icons.checklist,
        title: module.title,
        onEdit: () => _showRenameModuleDialog(context, ref),
        onDelete: () => _confirmDeleteModule(context, ref),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: () => _showAddChecklistItemDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Punkt hinzufügen'),
          ),
          const SizedBox(height: 8),
          itemsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: CircularProgressIndicator(),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('Punkte konnten nicht geladen werden: $e'),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Noch keine Punkte vorhanden.'),
                );
              }

              return Column(
                children: [
                  for (final item in items)
                    Dismissible(
                      key: ValueKey(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      onDismissed: (_) async {
                        await ref
                            .read(ideaRepositoryProvider)
                            .deleteChecklistItem(item.id);

                        if (context.mounted) {
                          _showSnackBar(context, 'Punkt gelöscht.');
                        }
                      },
                      child: CheckboxListTile(
                        value: item.isDone,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          item.content,
                          style: item.isDone
                              ? const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                )
                              : null,
                        ),
                        secondary: IconButton(
                          tooltip: 'Punkt bearbeiten',
                          onPressed: () =>
                              _showEditChecklistItemDialog(context, ref, item),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        onChanged: (value) async {
                          if (value == null) return;

                          await ref.read(ideaRepositoryProvider).toggleChecklistItem(
                                itemId: item.id,
                                isDone: value,
                              );

                          if (context.mounted) {
                            _showSnackBar(
                              context,
                              value
                                  ? 'Punkt abgehakt.'
                                  : 'Punkt wieder geöffnet.',
                            );
                          }
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}