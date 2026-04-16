import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ideas_app/core/utils/platform.dart';
import 'package:ideas_app/data/db/app_database.dart';
import 'package:ideas_app/domain/models/idea_link_item_model.dart';
import 'package:ideas_app/domain/models/idea_module_model.dart';
import 'package:ideas_app/features/ideas/logic/providers.dart';
import 'package:ideas_app/features/ideas/presentation/widgets/module_card_header.dart';
import 'package:ideas_app/features/ideas/presentation/widgets/module_card_shell.dart';
import 'package:ideas_app/features/ideas/presentation/widgets/module_dialogs.dart';
import 'package:url_launcher/url_launcher.dart';

class IdeaLinksModuleCard extends ConsumerWidget {
  final IdeaModuleModel module;

  const IdeaLinksModuleCard({super.key, required this.module});

  bool _isValidWebUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null) return false;
    return (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url.trim());

    if (uri == null) {
      _showSnackBar(context, 'Ungültige URL.');
      return;
    }

    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);

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

  Future<void> _confirmDeleteModule(BuildContext context, WidgetRef ref) async {
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

  Future<void> _showAddLinkDialog(BuildContext context, WidgetRef ref) async {
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

                    await ref
                        .read(ideaRepositoryProvider)
                        .addLinkItem(
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
    IdeaLinkItemModel item,
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

                    await ref
                        .read(ideaRepositoryProvider)
                        .updateLinkItem(
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

  Future<void> _deleteLinkItem(
    BuildContext context,
    WidgetRef ref,
    IdeaLinkItemModel item,
  ) async {
    await ref.read(ideaRepositoryProvider).deleteLinkItem(item.id);

    if (context.mounted) {
      _showSnackBar(context, 'Link gelöscht.');
    }
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

              return ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                proxyDecorator: (child, index, animation) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, _) {
                      return Material(
                        color: Colors.transparent,
                        shadowColor: Colors.black26,
                        elevation: 6,
                        borderRadius: BorderRadius.circular(12),
                        child: child,
                      );
                    },
                  );
                },
                itemCount: items.length,
                onReorder: (oldIndex, newIndex) async {
                  await ref
                      .read(ideaRepositoryProvider)
                      .reorderLinkItems(
                        items: items,
                        oldIndex: oldIndex,
                        newIndex: newIndex,
                      );
                },
                itemBuilder: (context, index) {
                  final item = items[index];

                  return ReorderableDelayedDragStartListener(
                    key: ValueKey(item.id),
                    index: index,
                    enabled: items.length > 1,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: isMobilePlatform
                          ? _MobileLinkItem(
                              item: item,
                              onOpen: () => _openLink(context, item.url),
                              onEdit: () =>
                                  _showEditLinkDialog(context, ref, item),
                              onDelete: () =>
                                  _deleteLinkItem(context, ref, item),
                            )
                          : _DesktopLinkItem(
                              item: item,
                              onOpen: () => _openLink(context, item.url),
                              onEdit: () =>
                                  _showEditLinkDialog(context, ref, item),
                              onDelete: () =>
                                  _deleteLinkItem(context, ref, item),
                            ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MobileLinkItem extends StatelessWidget {
  final IdeaLinkItemModel item;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MobileLinkItem({
    required this.item,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasLabel = (item.label ?? '').trim().isNotEmpty;

    return Dismissible(
      key: ValueKey('dismiss_${item.id}'),
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
      onDismissed: (_) => onDelete(),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: const Icon(Icons.link),
          title: Text(hasLabel ? item.label! : item.url),
          subtitle: hasLabel ? Text(item.url) : null,
          onTap: onOpen,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Link öffnen',
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new),
              ),
              IconButton(
                tooltip: 'Link bearbeiten',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopLinkItem extends StatefulWidget {
  final IdeaLinkItemModel item;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DesktopLinkItem({
    required this.item,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_DesktopLinkItem> createState() => _DesktopLinkItemState();
}

class _DesktopLinkItemState extends State<_DesktopLinkItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final hasLabel = (widget.item.label ?? '').trim().isNotEmpty;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _isHovered
              ? Theme.of(context).hoverColor.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: const Icon(Icons.link),
          title: Text(hasLabel ? widget.item.label! : widget.item.url),
          subtitle: hasLabel ? Text(widget.item.url) : null,
          onTap: widget.onOpen,
          trailing: SizedBox(
            width: 132,
            child: IgnorePointer(
              ignoring: !_isHovered,
              child: AnimatedOpacity(
                opacity: _isHovered ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Tooltip(
                      message: 'Link öffnen',
                      child: IconButton(
                        onPressed: widget.onOpen,
                        icon: const Icon(Icons.open_in_new),
                        iconSize: 20,
                        splashRadius: 18,
                      ),
                    ),
                    Tooltip(
                      message: 'Link bearbeiten',
                      child: IconButton(
                        onPressed: widget.onEdit,
                        icon: const Icon(Icons.edit_outlined),
                        iconSize: 20,
                        splashRadius: 18,
                      ),
                    ),
                    Tooltip(
                      message: 'Link löschen',
                      child: IconButton(
                        onPressed: widget.onDelete,
                        icon: const Icon(Icons.delete_outline),
                        iconSize: 20,
                        splashRadius: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
