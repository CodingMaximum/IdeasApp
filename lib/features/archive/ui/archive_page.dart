import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ideas_app/features/ideas/logic/providers.dart';
import 'package:ideas_app/features/ideas/presentation/widgets/idea_list_item.dart';

class ArchivePage extends ConsumerWidget {
  const ArchivePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivedIdeasAsync = ref.watch(archivedIdeasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archiv'),
      ),
      body: archivedIdeasAsync.when(
        data: (ideas) {
          if (ideas.isEmpty) {
            return const Center(
              child: Text('Noch keine archivierten Ideen'),
            );
          }

          return ListView.builder(
            itemCount: ideas.length,
            itemBuilder: (context, index) {
              final idea = ideas[index];
              return IdeaListItem(
                key: ValueKey(idea.id),
                idea: idea,
                isArchivedView: true,

              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (e, _) => Center(
          child: Text('Fehler: $e'),
        ),
      ),
    );
  }
}