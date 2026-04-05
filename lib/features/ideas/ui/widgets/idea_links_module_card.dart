import 'package:flutter/material.dart';
import 'package:ideas_app/data/db/app_database.dart';

class IdeaLinksModuleCard extends StatelessWidget {
  final IdeaModule module;

  const IdeaLinksModuleCard({
    super.key,
    required this.module,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.link),
        title: Text(module.title),
        subtitle: const Text('Links-Modul'),
      ),
    );
  }
}