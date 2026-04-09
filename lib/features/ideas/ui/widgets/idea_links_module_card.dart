import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ideas_app/data/db/app_database.dart';
import 'package:ideas_app/features/ideas/logic/providers.dart';
import 'package:ideas_app/features/ideas/ui/widgets/module_card_header.dart';
import 'package:ideas_app/features/ideas/ui/widgets/module_card_shell.dart';
import 'package:ideas_app/features/ideas/ui/widgets/module_dialogs.dart';
import 'package:url_launcher/url_launcher.dart';

class IdeaLinksModuleCard extends ConsumerWidget {
  final IdeaModule module;

  const IdeaLinksModuleCard({
    super.key,
    required this.module,
  });

  bool _isValidWebUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null) return false;
    return (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  Future<void> _openLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url.trim());

    if (uri == null) {
      _showSnackBar(context, 'Ungültige URL.');
      return;
    }

    final success = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!success && context.mounted) {
      _showSnackBar(context, 'Link konnte nicht geöffnet werden.');
    }
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
      contentTypeLabel: 'Links',
    );

    if (!confirmed) return;

    await ref.read(ideaRepositoryProvider).deleteModule(module.id);

    if (context.mounted) {
      _showSnackBar(context, 'Modul gelöscht.');
    }
  }

  Future<void> _showAddLinkDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final labelController = TextEditingController();
    final urlController = TextEditingController(text: 'https://');
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Link hinzufügen'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: labelController,
                    decoration: const InputDecoration(
                      labelText: 'Bezeichnung (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: urlController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'URL',
                      errorText: errorText,
                    ),
                    keyboardType: TextInputType.url,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Abbrechen'),
                ),
                FilledButton(
                  onPressed: () async {
                    final url = urlController.text.trim();
                    final label = labelController.text.trim();

                    if (!_isValidWebUrl(url)) {
                      setState(() {
                        errorText = 'Bitte eine gültige http(s)-URL eingeben.';
                      });
                      return;
                    }

                    await ref.read(ideaRepositoryProvider).addLinkItem(
                          moduleId: module.id,
                          url: url,
                          label: label.isEmpty ? null : label,
                        );

                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }

                    if (context.mounted) {
                      _showSnackBar(context, 'Link hinzugefügt.');
                    }
                  },
                  child: const Text('Hinzufügen'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditLinkDialog(
    BuildContext context,
    WidgetRef ref,
    IdeaLinkItem item,
  ) async {
    final labelController = TextEditingController(text: item.label ?? '');
    final urlController = TextEditingController(text: item.url);
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Link bearbeiten'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: labelController,
                    decoration: const InputDecoration(
                      labelText: 'Bezeichnung (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: urlController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'URL',
                      errorText: errorText,
                    ),
                    keyboardType: TextInputType.url,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Abbrechen'),
                ),
                FilledButton(
                  onPressed: () async {
                    final url = urlController.text.trim();
                    final label = labelController.text.trim();

                    if (!_isValidWebUrl(url)) {
                      setState(() {
                        errorText = 'Bitte eine gültige http(s)-URL eingeben.';
                      });
                      return;
                    }

                    await ref.read(ideaRepositoryProvider).updateLinkItem(
                          itemId: item.id,
                          url: url,
                          label: label.isEmpty ? null : label,
                        );

                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }

                    if (context.mounted) {
                      _showSnackBar(context, 'Link gespeichert.');
                    }
                  },
                  child: const Text('Speichern'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(ideaLinkItemsProvider(module.id));

    return ModuleCardShell(
      header: ModuleCardHeader(
        icon: Icons.link,
        title: module.title,
        onEdit: () => _showRenameModuleDialog(context, ref),
        onDelete: () => _confirmDeleteModule(context, ref),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: () => _showAddLinkDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Link hinzufügen'),
          ),
          const SizedBox(height: 8),
          itemsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: CircularProgressIndicator(),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('Links konnten nicht geladen werden: $e'),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Noch keine Links vorhanden.'),
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
                            .deleteLinkItem(item.id);

                        if (context.mounted) {
                          _showSnackBar(context, 'Link gelöscht.');
                        }
                      },
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.link),
                        title: Text(
                          (item.label ?? '').trim().isNotEmpty
                              ? item.label!
                              : item.url,
                        ),
                        subtitle: (item.label ?? '').trim().isNotEmpty
                            ? Text(item.url)
                            : null,
                        onTap: () => _openLink(context, item.url),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Link öffnen',
                              onPressed: () => _openLink(context, item.url),
                              icon: const Icon(Icons.open_in_new),
                            ),
                            IconButton(
                              tooltip: 'Link bearbeiten',
                              onPressed: () =>
                                  _showEditLinkDialog(context, ref, item),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                          ],
                        ),
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