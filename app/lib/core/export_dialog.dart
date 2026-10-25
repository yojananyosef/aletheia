/// Diálogo de exportación compartido (pasajes del lector y notas).
///
/// Ofrece formato (Markdown/HTML/Texto), copiar al portapapeles (todas las
/// plataformas) y, en escritorio, guardar archivo e imprimir (HTML temporal
/// en el navegador con el diálogo de impresión del sistema).
library;

import 'dart:io' show Directory, File, Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'content_export.dart';
import 'localization.dart';
import 'theme.dart';

class ExportDialog extends StatefulWidget {
  const ExportDialog({
    super.key,
    required this.title,
    required this.buildContent,
    required this.suggestedBaseName,
  });

  /// Título del diálogo (p. ej. «Exportar pasaje»).
  final String title;

  /// Construye el contenido según el formato elegido.
  final String Function(ExportFormat format) buildContent;

  /// Nombre base sin extensión para el archivo (p. ej. `juan-3`).
  final String suggestedBaseName;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String Function(ExportFormat format) buildContent,
    required String suggestedBaseName,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => ExportDialog(
        title: title,
        buildContent: buildContent,
        suggestedBaseName: suggestedBaseName,
      ),
    );
  }

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  ExportFormat _format = ExportFormat.markdown;
  String? _result;

  void _regenerate(ExportFormat format) {
    setState(() {
      _format = format;
      _result = null;
    });
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.buildContent(_format)));
    final l10n = context.l10n;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(l10n.exportCopied),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final location = await getSaveLocation(
      suggestedName: '${widget.suggestedBaseName}.${_format.fileExtension}',
      acceptedTypeGroups: [
        XTypeGroup(
          label: _formatLabel(l10n, _format),
          extensions: [_format.fileExtension],
        ),
      ],
    );
    if (location == null) return;
    final path = location.path.endsWith('.${_format.fileExtension}')
        ? location.path
        : '${location.path}.${_format.fileExtension}';
    await File(path).writeAsString(widget.buildContent(_format), flush: true);
    if (!mounted) return;
    setState(() => _result = l10n.exportSaved(path));
  }

  Future<void> _print() async {
    final dir = Directory.systemTemp;
    final file = File(
      '${dir.path}${Platform.pathSeparator}'
      '${widget.suggestedBaseName}-imprimir.html',
    );
    await file.writeAsString(widget.buildContent(ExportFormat.html), flush: true);
    await openInBrowserForPrinting(file);
  }

  String _formatLabel(AppLocalizations l10n, ExportFormat format) =>
      switch (format) {
        ExportFormat.markdown => l10n.exportFormatMarkdown,
        ExportFormat.html => l10n.exportFormatHtml,
        ExportFormat.plainText => l10n.exportFormatPlain,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDesktop =
        !kIsWeb &&
        (Platform.isLinux || Platform.isWindows || Platform.isMacOS);
    return AlertDialog(
      title: Text(widget.title, style: const TextStyle(fontSize: 17)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.exportFormat,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: kTextSecondary,
              ),
            ),
            const SizedBox(height: 6),
            SegmentedButton<ExportFormat>(
              segments: [
                for (final format in ExportFormat.values)
                  ButtonSegment(
                    value: format,
                    label: Text(
                      _formatLabel(l10n, format),
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
              ],
              selected: {_format},
              onSelectionChanged: (selection) => _regenerate(selection.first),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('export-copy'),
                  onPressed: _copy,
                  icon: const Icon(Icons.copy, size: 16),
                  label: Text(l10n.exportCopy, style: const TextStyle(fontSize: 13)),
                ),
                if (isDesktop)
                  OutlinedButton.icon(
                    key: const ValueKey('export-save'),
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined, size: 16),
                    label: Text(
                      l10n.exportSave,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                if (isDesktop)
                  OutlinedButton.icon(
                    key: const ValueKey('export-print'),
                    onPressed: _print,
                    icon: const Icon(Icons.print_outlined, size: 16),
                    label: Text(
                      l10n.exportPrint,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
              ],
            ),
            if (_result != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _result!,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: kTextSecondary,
                  ),
                ),
              ),
            if (isDesktop)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l10n.exportPrintHelp,
                  style: TextStyle(fontSize: 11.5, color: kTextSecondary),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
