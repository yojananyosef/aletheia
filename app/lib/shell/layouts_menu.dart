/// Menú de diseños (M5): presets + diseños guardados por el usuario.
///
/// El original asocia los diseños a la cuenta; el clon los guarda en local
/// (SQLite, dentro del workspace). Se usa tanto en la barra superior como en
/// la barra lateral.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization.dart';
import '../core/theme.dart';
import '../workspace/models.dart';
import '../workspace/workspace_controller.dart';

class LayoutsMenuButton extends ConsumerWidget {
  const LayoutsMenuButton({
    super.key,
    required this.menuKey,
    required this.trigger,
  });

  final String menuKey;
  final Widget trigger;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(workspaceProvider);
    final ctrl = ref.read(workspaceProvider.notifier);

    return PopupMenuButton<String>(
      key: ValueKey(menuKey),
      tooltip: l10n.navLayouts,
      position: PopupMenuPosition.under,
      onSelected: (value) {
        if (value.startsWith('preset:')) {
          ctrl.setLayout(value.substring('preset:'.length));
          return;
        }
        if (value.startsWith('saved:')) {
          final id = value.substring('saved:'.length);
          SavedLayout? saved;
          for (final layout in state.savedLayouts) {
            if (layout.id == id) {
              saved = layout;
              break;
            }
          }
          if (saved != null && ctrl.applySavedLayout(id)) {
            _toast(context, l10n.layoutAppliedToast(saved.name));
          }
          return;
        }
        if (value == 'save') {
          _saveLayout(context, ref);
          return;
        }
        if (value == 'manage') {
          _manageLayouts(context);
        }
      },
      itemBuilder: (context) => [
        for (final id in kLayoutPatterns.keys)
          PopupMenuItem(
            value: 'preset:$id',
            height: 34,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                _layoutLabel(l10n, id),
                style: const TextStyle(fontSize: 13.5),
              ),
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          enabled: false,
          height: 28,
          child: Text(
            l10n.layoutsSaved.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w700,
              color: kTextSecondary,
            ),
          ),
        ),
        if (state.savedLayouts.isEmpty)
          PopupMenuItem<String>(
            enabled: false,
            height: 34,
            child: Text(
              l10n.layoutNoSaved,
              style: TextStyle(fontSize: 12, color: kTextSecondary),
            ),
          )
        else
          for (final saved in state.savedLayouts)
            PopupMenuItem(
              value: 'saved:${saved.id}',
              key: ValueKey('layout-saved-${saved.id}'),
              height: 34,
              child: Row(
                children: [
                  Icon(
                    Icons.dashboard_customize_outlined,
                    size: 16,
                    color: kTextSecondary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      saved.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13.5),
                    ),
                  ),
                ],
              ),
            ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'save',
          key: const ValueKey('layout-save-current'),
          height: 34,
          child: Row(
            children: [
              Icon(Icons.save_outlined, size: 16, color: kTextSecondary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.layoutSaveCurrent,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5),
                ),
              ),
            ],
          ),
        ),
        if (state.savedLayouts.isNotEmpty)
          PopupMenuItem(
            value: 'manage',
            key: const ValueKey('layout-manage'),
            height: 34,
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 16, color: kTextSecondary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.layoutDelete,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13.5),
                  ),
                ),
              ],
            ),
          ),
      ],
      child: trigger,
    );
  }

  static String _layoutLabel(AppLocalizations l10n, String id) => switch (id) {
    'one' => l10n.layoutOne,
    'twoRows' => l10n.layoutTwoRows,
    'three' => l10n.layoutThree,
    'four' => l10n.layoutFour,
    _ => l10n.layoutTwo,
  };

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  Future<void> _saveLayout(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _SaveLayoutDialog(),
    );
    if (name == null || name.trim().isEmpty) return;
    ref.read(workspaceProvider.notifier).saveCurrentLayout(name);
    if (context.mounted) _toast(context, l10n.layoutSavedToast);
  }

  Future<void> _manageLayouts(BuildContext context) async {
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.layoutDelete, style: const TextStyle(fontSize: 15.5)),
        content: SizedBox(
          width: 400,
          child: Consumer(
            builder: (context, ref, _) {
              final saved = ref.watch(workspaceProvider).savedLayouts;
              if (saved.isEmpty) {
                return Text(
                  l10n.layoutNoSaved,
                  style: const TextStyle(fontSize: 13),
                );
              }
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: math.min(320, saved.length * 54.0),
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final layout in saved)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          layout.name,
                          style: const TextStyle(fontSize: 13),
                        ),
                        trailing: IconButton(
                          key: ValueKey('layout-delete-${layout.id}'),
                          iconSize: 17,
                          tooltip: l10n.layoutDelete,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => ref
                              .read(workspaceProvider.notifier)
                              .deleteSavedLayout(layout.id),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }
}

/// Diálogo para nombrar un diseño; posee su propio controlador para
/// liberarlo al desmontarse (no al cerrar la ruta).
class _SaveLayoutDialog extends StatefulWidget {
  const _SaveLayoutDialog();

  @override
  State<_SaveLayoutDialog> createState() => _SaveLayoutDialogState();
}

class _SaveLayoutDialogState extends State<_SaveLayoutDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.layoutSaveTitle, style: const TextStyle(fontSize: 15.5)),
      content: SizedBox(
        width: 360,
        child: TextField(
          key: const ValueKey('layout-name-field'),
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.layoutNameLabel,
            hintText: l10n.layoutNameHint,
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('layout-save-confirm'),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.layoutSave),
        ),
      ],
    );
  }
}
