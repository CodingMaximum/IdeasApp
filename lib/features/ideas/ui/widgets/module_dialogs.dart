import 'package:flutter/material.dart';

Future<String?> showModuleRenameDialog({
  required BuildContext context,
  required String initialTitle,
}) async {
  final controller = TextEditingController(text: initialTitle);

  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Modultitel bearbeiten'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Titel',
          ),
          onSubmitted: (value) {
            final trimmed = value.trim();
            Navigator.of(dialogContext).pop(
              trimmed.isEmpty ? null : trimmed,
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              final trimmed = controller.text.trim();
              Navigator.of(dialogContext).pop(
                trimmed.isEmpty ? null : trimmed,
              );
            },
            child: const Text('Speichern'),
          ),
        ],
      );
    },
  );
}

Future<bool> showDeleteModuleDialog({
  required BuildContext context,
  required String moduleTitle,
  required String contentTypeLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Modul löschen?'),
        content: Text(
          'Das Modul "$moduleTitle" und alle enthaltenen $contentTypeLabel werden gelöscht.',
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