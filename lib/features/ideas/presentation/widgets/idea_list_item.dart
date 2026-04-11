import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../../core/utils/platform.dart';
import '../../../../data/db/app_database.dart';
import '../../logic/providers.dart';
import 'package:go_router/go_router.dart';

class IdeaListItem extends ConsumerWidget {
  final Idea idea;
  final bool isArchivedView;

  const IdeaListItem({
    super.key,
    required this.idea,
    this.isArchivedView = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isMobilePlatform) {
      return _MobileItem(
        key: ValueKey(idea.id),
        idea: idea,
        isArchivedView: isArchivedView,
      );
    } else {
      return _DesktopItem(
        key: ValueKey(idea.id),
        idea: idea,
        isArchivedView: isArchivedView,
      );
    }
  }
}

Future<bool> _showDeleteDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Idee löschen?'),
        content: const Text(
          'Die Idee wird aus der Übersicht entfernt. Du kannst sie direkt danach wiederherstellen.',
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

  return result ?? false;
}

Future<void> _deleteIdeaWithUndo(
  BuildContext context,
  WidgetRef ref,
  Idea idea,
) async {
  final confirmed = await _showDeleteDialog(context);
  if (!confirmed) return;

  final repo = ref.read(ideaRepositoryProvider);
  final messenger = ScaffoldMessenger.of(context);

  await repo.deleteIdea(idea.id);

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('„${idea.title}“ gelöscht'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Wiederherstellen',
          onPressed: () async {
            try {
              await repo.restoreIdea(idea.id);
            } catch (e) {
              messenger.showSnackBar(
                SnackBar(content: Text('Wiederherstellen fehlgeschlagen: $e')),
              );
            }
          },
        ),
      ),
    );
}

Future<void> _archiveIdeaWithUndo(
  BuildContext context,
  WidgetRef ref,
  Idea idea,
) async {
  final repo = ref.read(ideaRepositoryProvider);
  final messenger = ScaffoldMessenger.of(context);

  await repo.archiveIdea(idea.id);

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('„${idea.title}“ archiviert'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Rückgängig',
          onPressed: () async {
            try {
              await repo.unarchiveIdea(idea.id);
            } catch (e) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'Archivierung konnte nicht rückgängig gemacht werden: $e',
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
}

Future<void> _unarchiveIdea(
  BuildContext context,
  WidgetRef ref,
  Idea idea,
) async {
  final repo = ref.read(ideaRepositoryProvider);
  final messenger = ScaffoldMessenger.of(context);

  await repo.unarchiveIdea(idea.id);

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('„${idea.title}“ aus dem Archiv entfernt'),
        behavior: SnackBarBehavior.floating,
      ),
    );
}

class _MobileItem extends ConsumerWidget {
  final Idea idea;
  final bool isArchivedView;

  const _MobileItem({
    super.key,
    required this.idea,
    required this.isArchivedView,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Slidable(
      key: ValueKey(idea.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          if (isArchivedView)
            SlidableAction(
              onPressed: (_) => _unarchiveIdea(context, ref, idea),
              icon: Icons.unarchive_outlined,
              label: 'Aus dem Archiv',
              backgroundColor: Colors.blueGrey,
              foregroundColor: Colors.white,
            )
          else
            SlidableAction(
              onPressed: (_) => _archiveIdeaWithUndo(context, ref, idea),
              icon: Icons.archive_outlined,
              label: 'Archiv',
              backgroundColor: Colors.blueGrey,
              foregroundColor: Colors.white,
            ),
          SlidableAction(
            onPressed: (_) => _deleteIdeaWithUndo(context, ref, idea),
            icon: Icons.delete,
            label: 'Löschen',
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ],
      ),
      child: ListTile(
        title: Text(idea.title),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: () async {
          final result = await context.pushNamed<Map<String, dynamic>>(
            'idea-detail',
            pathParameters: {'id': idea.id},
          );

          if (result == null ||
              result['action'] != 'deleted' ||
              !context.mounted) {
            return;
          }

          final repo = ref.read(ideaRepositoryProvider);
          final messenger = ScaffoldMessenger.of(context);
          final deletedIdeaId = result['ideaId'] as String;
          final deletedTitle = result['title'] as String;

          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('„$deletedTitle“ gelöscht'),
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'Wiederherstellen',
                  onPressed: () async {
                    try {
                      await repo.restoreIdea(deletedIdeaId);
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Wiederherstellen fehlgeschlagen: $e'),
                        ),
                      );
                    }
                  },
                ),
              ),
            );
        },
      ),
    );
  }
}


class _DesktopItem extends ConsumerStatefulWidget {
  final Idea idea;
  final bool isArchivedView;

  const _DesktopItem({
    super.key,
    required this.idea,
    required this.isArchivedView,
  });

  @override
  ConsumerState<_DesktopItem> createState() => _DesktopItemState();
}

class _DesktopItemState extends ConsumerState<_DesktopItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _isHovered
            ? Theme.of(context).hoverColor.withValues(alpha: 0.1)
            : Colors.transparent,
        child: ListTile(
          title: Text(widget.idea.title),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          onTap: () async {
            final result = await context.pushNamed<Map<String, dynamic>>(
              'idea-detail',
              pathParameters: {'id': widget.idea.id},
            );

            if (result == null ||
                result['action'] != 'deleted' ||
                !context.mounted) {
              return;
            }

            final repo = ref.read(ideaRepositoryProvider);
            final messenger = ScaffoldMessenger.of(context);
            final deletedIdeaId = result['ideaId'] as String;
            final deletedTitle = result['title'] as String;

            messenger
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text('„$deletedTitle“ gelöscht'),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'Wiederherstellen',
                    onPressed: () async {
                      try {
                        await repo.restoreIdea(deletedIdeaId);
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Wiederherstellen fehlgeschlagen: $e',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              );
          },
          trailing: SizedBox(
            width: 144,
            child: IgnorePointer(
              ignoring: !_isHovered,
              child: AnimatedOpacity(
                opacity: _isHovered ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Tooltip(
                      message: widget.isArchivedView
                          ? 'Aus dem Archiv'
                          : 'Archivieren',
                      child: IconButton(
                        icon: Icon(
                          widget.isArchivedView
                              ? Icons.unarchive_outlined
                              : Icons.archive_outlined,
                        ),
                        onPressed: () => widget.isArchivedView
                            ? _unarchiveIdea(context, ref, widget.idea)
                            : _archiveIdeaWithUndo(context, ref, widget.idea),
                        iconSize: 22,
                        splashRadius: 20,
                      ),
                    ),
                    Tooltip(
                      message: 'Löschen',
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            _deleteIdeaWithUndo(context, ref, widget.idea),
                        iconSize: 22,
                        splashRadius: 20,
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
