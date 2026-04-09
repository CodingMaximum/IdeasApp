import 'package:flutter/material.dart';

class ModuleCardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ModuleCardHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          tooltip: 'Titel bearbeiten',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: 'Modul löschen',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }
}