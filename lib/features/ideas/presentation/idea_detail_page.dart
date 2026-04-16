import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ideas_app/domain/enums/idea_module_type.dart';
import 'package:ideas_app/domain/models/idea_model.dart';
import 'package:ideas_app/domain/models/idea_module_model.dart';
import 'package:ideas_app/features/ideas/logic/providers.dart';
import 'package:ideas_app/features/ideas/presentation/widgets/category_selection.dart';
import 'package:ideas_app/features/ideas/presentation/widgets/idea_checklist_module_card.dart';
import 'package:ideas_app/features/ideas/presentation/widgets/idea_links_module_card.dart';
import 'package:ideas_app/features/ideas/presentation/widgets/status_selection.dart';

class IdeaDetailPage extends ConsumerWidget {
  final String ideaId;

  const IdeaDetailPage({super.key, required this.ideaId});

  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    IdeaModel idea,
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

  Future<void> _showAddModuleBottomSheet(
    BuildContext context,
    WidgetRef ref,
    String ideaId,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return _AddModuleBottomSheet(ideaId: ideaId);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ideaAsync = ref.watch(ideaByIdProvider(ideaId));
    final categoriesAsync = ref.watch(categoriesProvider);
    final statusesAsync = ref.watch(ideaStatusesProvider);
    final modulesAsync = ref.watch(ideaModulesProvider(ideaId));

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
              SizedBox(
                width: double.infinity,
                child: statusesAsync.when(
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
              ),
              const SizedBox(height: 24),
              _DescriptionSection(idea: idea),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: categoriesAsync.when(
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
              ),

              const SizedBox(height: 24),

              _ModulesSection(
                ideaId: idea.id,
                modulesAsync: modulesAsync,
                onAddModule: () =>
                    _showAddModuleBottomSheet(context, ref, idea.id),
              ),
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

class _ModulesSection extends ConsumerWidget {
  final String ideaId;
  final AsyncValue<List<IdeaModuleModel>> modulesAsync;
  final VoidCallback onAddModule;

  const _ModulesSection({
    required this.ideaId,
    required this.modulesAsync,
    required this.onAddModule,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Module', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            FilledButton.icon(
              onPressed: onAddModule,
              icon: const Icon(Icons.add),
              label: const Text('Modul hinzufügen'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        modulesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: CircularProgressIndicator(),
          ),
          error: (e, _) => Text('Module konnten nicht geladen werden: $e'),
          data: (modules) {
            if (modules.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Noch keine Module vorhanden.'),
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
                      elevation: 8,
                      borderRadius: BorderRadius.circular(12),
                      child: child,
                    );
                  },
                );
              },
              itemCount: modules.length,
              onReorder: (oldIndex, newIndex) async {
                await ref
                    .read(ideaRepositoryProvider)
                    .reorderModules(
                      modules: modules,
                      oldIndex: oldIndex,
                      newIndex: newIndex,
                    );
              },
              itemBuilder: (context, index) {
                final module = modules[index];

                return ReorderableDelayedDragStartListener(
                  key: ValueKey(module.id),
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ModuleRenderer(module: module),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _ModuleRenderer extends ConsumerWidget {
  final IdeaModuleModel module;

  const _ModuleRenderer({required this.module});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (module.type) {
      case IdeaModuleType.checklist:
        return IdeaChecklistModuleCard(module: module);
      case IdeaModuleType.links:
        return IdeaLinksModuleCard(module: module);
    }
  }
}

class _TitleSection {
  static Future<void> showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    IdeaModel    idea,
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
  final IdeaModel idea;

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

class _AddModuleBottomSheet extends ConsumerStatefulWidget {
  final String ideaId;

  const _AddModuleBottomSheet({required this.ideaId});

  @override
  ConsumerState<_AddModuleBottomSheet> createState() =>
      _AddModuleBottomSheetState();
}

class _AddModuleBottomSheetState extends ConsumerState<_AddModuleBottomSheet> {
  final _titleController = TextEditingController();
  IdeaModuleType _selectedType = IdeaModuleType.checklist;
  bool _isSaving = false;

  Future<void> _submit() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final repo = ref.read(ideaRepositoryProvider);
      final title = _titleController.text.trim();

      switch (_selectedType) {
        case IdeaModuleType.checklist:
          await repo.addChecklistModuleWithTitle(
            ideaId: widget.ideaId,
            title: title,
          );
          break;
        case IdeaModuleType.links:
          await repo.addLinksModuleWithTitle(
            ideaId: widget.ideaId,
            title: title,
          );
          break;
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          left: 16,
          top: 8,
          right: 16,
          bottom: bottomInset + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Modul hinzufügen',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Wähle den Modultyp und gib einen Titel an.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              RadioGroup<IdeaModuleType>(
                groupValue: _selectedType,
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _selectedType = value;
                  });
                },
                child: Column(
                  children: [
                    RadioListTile<IdeaModuleType>(
                      contentPadding: EdgeInsets.zero,
                      value: IdeaModuleType.checklist,
                      title: const Text('Checkliste'),
                      subtitle: const Text(
                        'Mehrere Punkte sammeln und abhaken',
                      ),
                    ),
                    RadioListTile<IdeaModuleType>(
                      contentPadding: EdgeInsets.zero,
                      value: IdeaModuleType.links,
                      title: const Text('Links'),
                      subtitle: const Text('URLs und Quellen sammeln'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Titel',
                  hintText: _selectedType == IdeaModuleType.checklist
                      ? 'z. B. Packliste'
                      : 'z. B. Inspirationsquellen',
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Abbrechen'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSaving ? null : _submit,
                      child: _isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Anlegen'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
