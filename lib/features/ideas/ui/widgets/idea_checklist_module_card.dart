import 'package:flutter/material.dart';
import 'package:ideas_app/data/db/app_database.dart';

class IdeaChecklistModuleCard extends StatelessWidget {
  final IdeaModule module;

  const IdeaChecklistModuleCard({
    super.key,
    required this.module,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.checklist),
        title: Text(module.title),
        subtitle: const Text('Checklisten-Modul'),
      ),
    );
  }
}