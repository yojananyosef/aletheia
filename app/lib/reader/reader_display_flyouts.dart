/// Flyouts de **Formato** y **Vista** del panel del lector (M3).
///
/// Réplica de los del original (según la evidencia de reconocimiento y
/// `paged.png`): tarjeta bajo la toolbar secundaria con interruptor maestro,
/// árbol de casillas y nota al pie.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization.dart';
import '../core/theme.dart';
import '../notes/notes_controller.dart';
import 'reader_style.dart';
import '../workspace/models.dart';

/// Tarjeta de flyout (título, atajo opcional y ✕).
class DisplayFlyoutCard extends StatelessWidget {
  const DisplayFlyoutCard({
    super.key,
    required this.title,
    required this.onClose,
    required this.child,
    this.shortcut,
  });

  final String title;
  final String? shortcut;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      color: kPanelBg,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 330),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 6, 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (shortcut != null && shortcut!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        shortcut!,
                        style: TextStyle(fontSize: 11.5, color: kTextSecondary),
                      ),
                    ),
                  IconButton(
                    iconSize: 15,
                    tooltip: context.l10n.close,
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class FlyoutSwitchRow extends StatelessWidget {
  const FlyoutSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13.5))),
        SizedBox(
          height: 26,
          child: FittedBox(
            child: Switch(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }
}

/// Casilla del árbol (con sangría y estado deshabilitado).
class FlyoutCheckRow extends StatelessWidget {
  const FlyoutCheckRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.indent = 0,
    this.expander = false,
    this.trailing,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final int indent;

  /// Nodo de árbol con ▾ (los del original agrupan subopciones).
  final bool expander;

  /// Marca del dataset a la derecha (✳ en el original).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final color = enabled
        ? kTextPrimary
        : kTextSecondary.withValues(alpha: 0.6);
    return InkWell(
      onTap: enabled ? () => onChanged!(!value) : null,
      child: Padding(
        padding: EdgeInsets.only(left: indent * 18.0, top: 3, bottom: 3),
        child: Row(
          children: [
            if (expander)
              Icon(Icons.arrow_drop_down, size: 17, color: color)
            else
              SizedBox(
                width: 17,
                height: 17,
                child: Checkbox(
                  value: value,
                  onChanged: enabled ? (v) => onChanged!(v ?? false) : null,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 13, color: color)),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// Etiqueta de grupo del flyout (Cuadernos / Etiquetas).
class _FlyoutGroupLabel extends StatelessWidget {
  const _FlyoutGroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 2),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: kTextSecondary,
        ),
      ),
    );
  }
}

/// Nota al pie con barra azul (como la del panel Marcadores del original).
class FlyoutNote extends StatelessWidget {
  const FlyoutNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 7, 9, 7),
      decoration: BoxDecoration(
        color: kSidebarBg,
        border: Border(left: BorderSide(color: kAccent, width: 3)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11.5, height: 1.35, color: kTextPrimary),
      ),
    );
  }
}

/// Formato → Reformato.
class ReformatFlyout extends StatelessWidget {
  const ReformatFlyout({
    super.key,
    required this.display,
    required this.onChanged,
    required this.onClose,
  });

  final TabDisplay display;
  final ValueChanged<TabDisplay> onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final on = display.reformat;
    ValueChanged<bool>? setter(
      bool Function(TabDisplay d) read,
      TabDisplay Function(TabDisplay d, bool v) write,
    ) => on ? (value) => onChanged(write(display, value)) : null;

    return DisplayFlyoutCard(
      title: l10n.fmtReformatTitle,
      onClose: onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.fmtTypography,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 4),
          SegmentedButton<String>(
            key: const ValueKey('reader-font-switch'),
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            segments: [
              ButtonSegment(
                value: 'serif',
                label: Text(
                  l10n.fontSerif,
                  style: readerBodyStyle(size: 12.5, font: 'serif'),
                ),
              ),
              ButtonSegment(
                value: 'sans',
                label: Text(
                  l10n.fontSans,
                  style: readerBodyStyle(size: 12.5, font: 'sans'),
                ),
              ),
              ButtonSegment(
                value: 'mono',
                label: Text(
                  l10n.fontMono,
                  style: readerBodyStyle(size: 12.5, font: 'mono'),
                ),
              ),
            ],
            selected: {display.font},
            onSelectionChanged: (selection) =>
                onChanged(display.copyWith(font: selection.first)),
          ),
          const SizedBox(height: 8),
          FlyoutSwitchRow(
            key: const ValueKey('reader-reformat-switch'),
            label: l10n.fmtReformatTitle,
            value: on,
            onChanged: (value) => onChanged(display.copyWith(reformat: value)),
          ),
          const SizedBox(height: 2),
          FlyoutCheckRow(
            label: l10n.fmtBibleText,
            value: true,
            expander: true,
            onChanged: on ? (_) {} : null,
          ),
          FlyoutCheckRow(
            label: l10n.fmtBibleTextFormatting,
            value: display.bibleTextFormatting,
            indent: 1,
            onChanged: setter(
              (d) => d.bibleTextFormatting,
              (d, v) => d.copyWith(bibleTextFormatting: v),
            ),
          ),
          FlyoutCheckRow(
            label: l10n.fmtNumbers,
            value: display.numbers,
            indent: 1,
            onChanged: setter(
              (d) => d.numbers,
              (d, v) => d.copyWith(numbers: v),
            ),
          ),
          FlyoutCheckRow(
            label: l10n.fmtFootnoteIndicators,
            value: display.footnoteIndicators,
            indent: 1,
            onChanged: setter(
              (d) => d.footnoteIndicators,
              (d, v) => d.copyWith(footnoteIndicators: v),
            ),
          ),
          FlyoutCheckRow(
            label: l10n.fmtNonBibleText,
            value: display.nonBibleText,
            onChanged: on
                ? (value) => onChanged(display.copyWith(nonBibleText: value))
                : null,
          ),
          FlyoutCheckRow(
            label: l10n.fmtOneVersePerLine,
            value: display.oneVersePerLine,
            onChanged: setter(
              (d) => d.oneVersePerLine,
              (d, v) => d.copyWith(oneVersePerLine: v),
            ),
          ),
          FlyoutCheckRow(
            label: l10n.fmtCorrespondingWords,
            value: true,
            expander: true,
            onChanged: on ? (_) {} : null,
          ),
          FlyoutCheckRow(
            label: l10n.fmtSameSurfaceText,
            value: display.sameSurfaceText,
            indent: 1,
            // Requiere datasets de morfología/correspondencia (M6).
            onChanged: null,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.fmtNote,
            style: TextStyle(fontSize: 11.5, color: kTextSecondary),
          ),
        ],
      ),
    );
  }
}

/// Formato → Marcadores (M6.2): filtra los indicadores y resaltados del panel
/// por cuaderno y etiqueta. Nuestros «datasets» son las anotaciones locales.
class MarkersFlyout extends ConsumerWidget {
  const MarkersFlyout({
    super.key,
    required this.display,
    required this.onChanged,
    required this.onClose,
  });

  final TabDisplay display;
  final ValueChanged<TabDisplay> onChanged;
  final VoidCallback onClose;

  void _toggleNotebook(String id) {
    final next = [...display.markerNotebooks];
    next.contains(id) ? next.remove(id) : next.add(id);
    onChanged(display.copyWith(markerNotebooks: next));
  }

  void _toggleTag(String tag) {
    final next = [...display.markerTags];
    next.contains(tag) ? next.remove(tag) : next.add(tag);
    onChanged(display.copyWith(markerTags: next));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final on = display.markers;
    final state = ref.watch(notesProvider);
    final notes = state.notes.where((note) => !note.isTrashed).toList();
    final tags = <String>{for (final note in notes) ...note.tags}.toList()
      ..sort();
    final trailing = Icon(
      Icons.auto_awesome,
      size: 12,
      color: kAccent.withValues(alpha: 0.75),
    );

    int notebookCount(String id) =>
        notes.where((note) => note.notebooks.contains(id)).length;
    int tagCount(String tag) =>
        notes.where((note) => note.tags.contains(tag)).length;

    return DisplayFlyoutCard(
      title: l10n.fmtMarkersTitle,
      onClose: onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          FlyoutSwitchRow(
            key: const ValueKey('markers-switch'),
            label: l10n.fmtMarkersTitle,
            value: on,
            onChanged: (value) => onChanged(display.copyWith(markers: value)),
          ),
          if (state.notebooks.isNotEmpty) ...[
            _FlyoutGroupLabel(l10n.fmtMarkersNotebooks),
            for (final notebook in state.notebooks)
              FlyoutCheckRow(
                key: ValueKey('marker-notebook-${notebook.id}'),
                label: '${notebook.name} (${notebookCount(notebook.id)})',
                value: display.markerNotebooks.contains(notebook.id),
                trailing: trailing,
                indent: 1,
                onChanged: on ? (_) => _toggleNotebook(notebook.id) : null,
              ),
          ],
          if (tags.isNotEmpty) ...[
            _FlyoutGroupLabel(l10n.fmtMarkersTags),
            for (final tag in tags)
              FlyoutCheckRow(
                key: ValueKey('marker-tag-$tag'),
                label: '#$tag (${tagCount(tag)})',
                value: display.markerTags.contains(tag),
                trailing: trailing,
                indent: 1,
                onChanged: on ? (_) => _toggleTag(tag) : null,
              ),
          ],
          if (state.notebooks.isEmpty && tags.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 2),
              child: Text(
                l10n.fmtMarkersEmpty,
                style: TextStyle(fontSize: 12, color: kTextSecondary),
              ),
            ),
          const SizedBox(height: 8),
          FlyoutNote(text: l10n.fmtMarkersNote),
        ],
      ),
    );
  }
}

/// Vista → Vista paginada (Ctrl+Shift+P).
class PagedViewFlyout extends StatelessWidget {
  const PagedViewFlyout({
    super.key,
    required this.display,
    required this.onChanged,
    required this.onClose,
  });

  final TabDisplay display;
  final ValueChanged<TabDisplay> onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final on = display.paged;
    return DisplayFlyoutCard(
      title: l10n.viewPagedTitle,
      shortcut: 'Ctrl+Shift+P',
      onClose: onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          FlyoutSwitchRow(
            key: const ValueKey('reader-paged-switch'),
            label: l10n.viewPagedTitle,
            value: on,
            onChanged: (value) => onChanged(display.copyWith(paged: value)),
          ),
          const SizedBox(height: 4),
          Text(l10n.viewColumns, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          SegmentedButton<String>(
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            segments: [
              for (final option in const ['1', '2', '3', 'auto'])
                ButtonSegment(
                  value: option,
                  label: Text(
                    option == 'auto' ? l10n.viewColumnsAuto : option,
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
            ],
            selected: {display.columns},
            onSelectionChanged: on
                ? (selection) =>
                      onChanged(display.copyWith(columns: selection.first))
                : null,
          ),
          const SizedBox(height: 4),
          FlyoutCheckRow(
            label: l10n.viewFootnotesOnPage,
            value: display.footnotesOnPage,
            onChanged: on
                ? (value) => onChanged(display.copyWith(footnotesOnPage: value))
                : null,
          ),
        ],
      ),
    );
  }
}
