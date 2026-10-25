/// Sección «Datos y respaldo» de Ajustes: exportar/restaurar el respaldo sin
/// cuenta, y exportar/borrar el registro local de fallos. Sólo escritorio
/// (en web la persistencia es IndexedDB y estos botones no se muestran).
library;

import 'dart:io' show File;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_backup.dart';
import '../core/app_update.dart';
import '../core/content_export.dart';
import '../core/data_care.dart';
import '../core/localization.dart';
import '../core/theme.dart';
import '../core/app_version.dart';

/// Filas de Ajustes para el respaldo, el diagnóstico y la versión.
class DataCareSection extends ConsumerStatefulWidget {
  const DataCareSection({super.key});

  @override
  ConsumerState<DataCareSection> createState() => _DataCareSectionState();
}

class _DataCareSectionState extends ConsumerState<DataCareSection> {
  bool _busy = false;
  String? _message;

  void _done(String message) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = message;
    });
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = message;
    });
  }

  Future<void> _exportBackup() async {
    final backup = ref.read(appBackupProvider);
    if (backup == null || _busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final l10n = context.l10n;
      final location = await getSaveLocation(
        suggestedName: backup.suggestedFileName(),
        acceptedTypeGroups: [
          const XTypeGroup(label: 'Respaldo de Aletheia', extensions: ['aletheiabackup', 'zip']),
        ],
      );
      if (location == null) {
        _done('');
        return;
      }
      final path = location.path.endsWith('.aletheiabackup') ||
              location.path.endsWith('.zip')
          ? location.path
          : '${location.path}.aletheiabackup';
      await backup.exportTo(path);
      _done(l10n.backupExported(path));
    } on BackupException catch (error) {
      _fail(error.message);
    } on Object catch (error) {
      _fail(error.toString());
    }
  }

  Future<void> _restoreBackup() async {
    final backup = ref.read(appBackupProvider);
    if (backup == null || _busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      const typeGroup = XTypeGroup(
        label: 'Respaldo de Aletheia',
        extensions: ['aletheiabackup', 'zip'],
      );
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) {
        _done('');
        return;
      }
      final summary = await backup.stageRestore(file.path);
      if (!mounted) return;
      final l10n = context.l10n;
      final dateLabel = summary.exportedAt.toIso8601String().split('T').first;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.backupRestoreConfirmTitle),
          content: Text(
            l10n.backupRestoreConfirmBody(dateLabel, summary.appVersion),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.backupRestoreApply),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        _done('');
        return;
      }
      _done(l10n.backupStagedRestart);
    } on BackupException catch (error) {
      _fail(error.message);
    } on Object catch (error) {
      _fail(error.toString());
    }
  }

  Future<void> _exportCrashLog() async {
    final crashLog = ref.read(crashLogProvider);
    if (crashLog == null || _busy) return;
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final content = await crashLog.read();
      if (content == null || content.isEmpty) {
        _done(l10n.crashLogEmpty);
        return;
      }
      final location = await getSaveLocation(
        suggestedName: 'aletheia-crash.log',
        acceptedTypeGroups: const [
          XTypeGroup(label: 'Registro de texto', extensions: ['log', 'txt']),
        ],
      );
      if (location == null) {
        _done('');
        return;
      }
      await File(location.path).writeAsString(content, flush: true);
      _done(l10n.crashLogExported(location.path));
    } on Object catch (error) {
      _fail(error.toString());
    }
  }

  Future<void> _clearCrashLog() async {
    final crashLog = ref.read(crashLogProvider);
    if (crashLog == null || _busy) return;
    final l10n = context.l10n;
    await crashLog.clear();
    _done(l10n.crashLogCleared);
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final checker = AppUpdateChecker();
    final info = await checker.checkLatestRelease();
    if (!mounted) return;
    setState(() => _busy = false);
    if (info == null) {
      _done(context.l10n.updateNone);
      return;
    }
    final l10n = context.l10n;
    final open = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.updateAvailableTitle(info.versionLabel)),
        content: Text(l10n.updateAvailableBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.updateOpenReleases),
          ),
        ],
      ),
    );
    if (open == true) {
      await openInBrowserForPrintingUrl(info.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 2),
          child: Text(
            l10n.dataCareTitle,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: kTextSecondary,
            ),
          ),
        ),
        _ActionRow(
          key: const ValueKey('settings-backup-export'),
          label: l10n.backupExport,
          help: l10n.backupExportHelp,
          onPressed: _exportBackup,
        ),
        _ActionRow(
          key: const ValueKey('settings-backup-restore'),
          label: l10n.backupRestore,
          help: l10n.backupRestoreHelp,
          onPressed: _restoreBackup,
        ),
        _ActionRow(
          key: const ValueKey('settings-crash-export'),
          label: l10n.crashLogExport,
          help: l10n.crashLogHelp,
          onPressed: _exportCrashLog,
        ),
        _ActionRow(
          key: const ValueKey('settings-crash-clear'),
          label: l10n.crashLogClear,
          onPressed: _clearCrashLog,
        ),
        _ActionRow(
          key: const ValueKey('settings-update-check'),
          label: l10n.updateCheck,
          help: l10n.updateCheckHelp,
          onPressed: _checkForUpdates,
        ),
        if (_busy) const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: LinearProgressIndicator(minHeight: 2),
        ),
        if (_message != null && _message!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Text(
              _message!,
              style: TextStyle(fontSize: 12.5, color: kTextSecondary),
            ),
          ),
        const SizedBox(height: 4),
        Text(
          l10n.aboutVersion(kAppVersion),
          style: TextStyle(fontSize: 12, color: kTextSecondary),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    super.key,
    required this.label,
    required this.onPressed,
    this.help,
  });

  final String label;
  final VoidCallback onPressed;
  final String? help;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          TextButton(
            key: key,
            onPressed: onPressed,
            child: Text(label, style: const TextStyle(fontSize: 13.5)),
          ),
          const Spacer(),
          if (help != null)
            Tooltip(
              message: help,
              child: Icon(Icons.help_outline, size: 15, color: kTextSecondary),
            ),
        ],
      ),
    );
  }
}
