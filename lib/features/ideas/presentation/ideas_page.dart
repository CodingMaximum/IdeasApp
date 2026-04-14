import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ideas_app/features/ideas/presentation/widgets/idea_list_item.dart';
import 'package:ideas_app/features/ideas/presentation/widgets/quick_capture_bar.dart';
import 'package:ideas_app/features/settings/settings_page.dart';
import 'package:ideas_app/features/archive/ui/archive_page.dart';
import '../logic/providers.dart';

class IdeasPage extends ConsumerWidget {
  const IdeasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const QuickCaptureBar(),
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
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
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
                          child: Text('Sprich oben deine erste Idee ein'),
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