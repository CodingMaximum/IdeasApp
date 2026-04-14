import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:ideas_app/features/ideas/logic/providers.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isBusy = false;

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _resetDatabaseContent(BuildContext context) async {
    final confirmed = await _confirm(
      context,
      title: 'Lokale Daten zurücksetzen?',
      message:
          'Alle lokalen Inhalte werden gelöscht und die Standarddaten neu angelegt.',
      confirmLabel: 'Zurücksetzen',
    );

    if (!confirmed) return;

    setState(() => _isBusy = true);

    try {
      final db = ref.read(databaseProvider);
      await db.resetDatabaseContent();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokale Daten wurden zurückgesetzt.')),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fehler beim Zurücksetzen: $e')));
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _deleteDatabaseFile(BuildContext context) async {
    final confirmed = await _confirm(
      context,
      title: 'Datenbankdatei löschen?',
      message:
          'Die lokale Datenbankdatei wird gelöscht. Danach werden Datenbank und Streams neu aufgebaut.',
      confirmLabel: 'Datei löschen',
    );

    if (!confirmed) return;

    setState(() => _isBusy = true);

    try {
      final db = ref.read(databaseProvider);
      await db.close();

      final dbFolder = await getApplicationDocumentsDirectory();
      final dbPath = p.join(dbFolder.path, 'app.db');

      final dbFile = File(dbPath);
      final walFile = File('$dbPath-wal');
      final shmFile = File('$dbPath-shm');

      if (await dbFile.exists()) {
        await dbFile.delete();
      }
      if (await walFile.exists()) {
        await walFile.delete();
      }
      if (await shmFile.exists()) {
        await shmFile.delete();
      }

      ref.invalidate(databaseProvider);
      ref.invalidate(ideaRepositoryProvider);
      ref.invalidate(ideasProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(ideaStatusesProvider);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Datenbankdatei gelöscht. Die App-Daten werden neu aufgebaut.',
          ),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Löschen der Datenbankdatei: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _selectSpeechLanguage(BuildContext context) async {
    final speech = ref.read(speechRecognitionServiceProvider);
    final settings = ref.read(speechSettingsServiceProvider);

    setState(() => _isBusy = true);

    try {
      final initialized = await speech.initialize(
        onResult: (_, __) {},
        onStatus: (_) {},
        onError: (_) {},
      );

      if (!initialized) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Spracheingabe ist auf diesem Gerät nicht verfügbar.',
            ),
          ),
        );
        return;
      }

      final locales = await speech.getAvailableLocales();
      final selectedLocaleId = await settings.getSpeechLocaleId();
      final systemLocaleId = await speech.getSystemLocaleId();

      if (!context.mounted) return;

      final result = await showModalBottomSheet<String?>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) {
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                const ListTile(
                  title: Text('Sprache für Spracheingabe'),
                  subtitle: Text('Wähle die Erkennungssprache aus'),
                ),
                RadioGroup<String?>(
                  groupValue: selectedLocaleId,
                  onChanged: (value) async {
                    await settings.setSpeechLocaleId(value);
                    if (context.mounted) {
                      Navigator.of(context).pop(value);
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<String?>(
                        value: null,
                        title: const Text('Systemstandard'),
                        subtitle: Text(
                          systemLocaleId == null
                              ? 'Gerätesprache verwenden'
                              : 'Gerätesprache verwenden ($systemLocaleId)',
                        ),
                      ),
                      const Divider(height: 1),
                      ...locales.map(
                        (locale) => RadioListTile<String?>(
                          value: locale.localeId,
                          title: Text(locale.name),
                          subtitle: Text(locale.localeId),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (result != null || selectedLocaleId != null) {
        ref.invalidate(selectedSpeechLocaleIdProvider);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Laden der Sprachen: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Spracheingabe', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Consumer(
              builder: (context, ref, _) {
                final selectedLocaleAsync = ref.watch(
                  selectedSpeechLocaleIdProvider,
                );

                final subtitle = selectedLocaleAsync.maybeWhen(
                  data: (localeId) =>
                      localeId == null ? 'Systemstandard' : localeId,
                  orElse: () => 'Laden…',
                );

                return ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Erkennungssprache'),
                  subtitle: Text(subtitle),
                  trailing: _isBusy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _isBusy ? null : () => _selectSpeechLanguage(context),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text('Entwicklung', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.restart_alt),
                  title: const Text('Lokale Daten zurücksetzen'),
                  subtitle: const Text(
                    'Löscht alle Inhalte und legt die Seed-Daten neu an.',
                  ),
                  trailing: _isBusy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: _isBusy ? null : () => _resetDatabaseContent(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined),
                  title: const Text('Datenbankdatei löschen'),
                  subtitle: const Text(
                    'Harter Reset von app.db. Danach App neu starten.',
                  ),
                  trailing: _isBusy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: _isBusy ? null : () => _deleteDatabaseFile(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
