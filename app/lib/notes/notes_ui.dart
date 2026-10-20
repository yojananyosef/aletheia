/// Piezas compartidas de la UI de Notas (M4): chips, tarjeta de nota, paleta
/// de resaltado y etiquetas de fecha/anclaje.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization.dart';
import '../core/theme.dart';
import '../references/reference_parser.dart';
import 'markdown_lite.dart';
import 'notes_models.dart';

/// Fecha corta y localizada («19/10/2026»).
String shortDateLabel(BuildContext context, DateTime date) =>
    MaterialLocalizations.of(context).formatShortDate(date.toLocal());

/// Etiqueta legible de un anclaje (referencia en el idioma activo).
String noteAnchorLabel(NoteAnchor? anchor, {String lang = 'es'}) {
  if (anchor == null) return '';
  final reference = anchor.reference;
  if (reference != null && reference.isNotEmpty) {
    return displayFromCanonical(reference, lang: lang);
  }
  if (anchor.bookCode != null && anchor.chapter != null) {
    final display = bookDisplayName(anchor.bookCode!, lang: lang);
    return '${display.isEmpty ? anchor.bookCode! : display} ${anchor.chapter}';
  }
  return anchor.resourceId;
}

/// Chip breve de anclaje/referencia.
class NoteAnchorChip extends StatelessWidget {
  const NoteAnchorChip({
    super.key,
    required this.label,
    this.icon,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : 8,
        vertical: dense ? 1.5 : 3,
      ),
      decoration: BoxDecoration(
        color: kFieldFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 11 : 13, color: kTextSecondary),
            const SizedBox(width: 4),
          ],
          // La etiqueta recorta con puntos suspensivos antes que desbordar la
          // fila (paneles estrechos).
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(
              fontSize: dense ? 11 : 12,
              color: kTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Paleta de colores de resaltado (la comparten el editor y la selección).
class HighlightPalette extends StatelessWidget {
  const HighlightPalette({
    super.key,
    required this.selected,
    required this.onPick,
    this.size = 20,
    this.dense = false,
  });

  final String selected;
  final ValueChanged<String> onPick;
  final double size;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final id in kHighlightColorIds)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: dense ? 2 : 4),
            child: Tooltip(
              message: switch (id) {
                'yellow' => l10n.noteColorYellow,
                'green' => l10n.noteColorGreen,
                'blue' => l10n.noteColorBlue,
                _ => l10n.noteColorPink,
              },
              child: InkWell(
                key: Key('highlight-color-$id'),
                onTap: () => onPick(id),
                customBorder: const CircleBorder(),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: highlightColor(id),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: id == selected ? kAccentDark : kBorder,
                      width: id == selected ? 2 : 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Tarjeta de una nota en las listas (panel global y lector).
class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onEdit,
    this.onShowInReader,
    this.onTrash,
    this.onRestore,
    this.onPurge,
    this.selected = false,
    this.showActions = true,
    this.showAnchor = true,
    this.notebookNames = const [],
    this.dense = false,
  });

  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onShowInReader;
  final VoidCallback? onTrash;
  final VoidCallback? onRestore;
  final VoidCallback? onPurge;
  final bool selected;
  final bool showActions;
  final bool showAnchor;
  final List<String> notebookNames;

  /// Densidad compacta de la lista (controles «Predeterminado / Compacto»).
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = context.l10nLang;
    final anchor = note.mainAnchor;
    final anchorLabel = noteAnchorLabel(anchor, lang: lang);
    final headline = note.headline;
    final preview = note.preview;
    final quote = note.quote;

    return InkWell(
      key: Key('note-card-${note.id}'),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? kAccent.withValues(alpha: 0.12) : kPanelBg,
          border: Border(
            bottom: BorderSide(color: kBorder),
            left: BorderSide(
              color: selected ? kAccent : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        padding: EdgeInsets.fromLTRB(12, dense ? 6 : 10, 8, dense ? 6 : 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note.isHighlight)
                  Padding(
                    padding: const EdgeInsets.only(top: 3, right: 8),
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: highlightColor(note.color),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: kBorder),
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (headline.isNotEmpty)
                        Text(
                          headline,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: dense ? 12.5 : 13,
                            fontWeight: FontWeight.w600,
                            color: kTextPrimary,
                          ),
                        ),
                      if (preview.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                            top: headline.isEmpty ? 0 : 2,
                          ),
                          child: Text.rich(
                            TextSpan(
                              children: markdownSpans(
                                preview,
                                TextStyle(
                                  fontSize: dense ? 12 : 12.5,
                                  color: kTextSecondary,
                                ),
                              ),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (quote != null && note.title.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            '«$quote»',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: kTextSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      if (anchorLabel.isNotEmpty ||
                          notebookNames.isNotEmpty ||
                          note.tags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (showAnchor && anchorLabel.isNotEmpty)
                                NoteAnchorChip(
                                  label: anchorLabel,
                                  icon: Icons.menu_book_outlined,
                                  dense: true,
                                ),
                              for (final name in notebookNames)
                                NoteAnchorChip(
                                  label: name,
                                  icon: Icons.library_books_outlined,
                                  dense: true,
                                ),
                              for (final tag in note.tags)
                                NoteAnchorChip(label: '#$tag', dense: true),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (note.isTrashed)
                  Text(
                    note.deletedAt == null
                        ? ''
                        : shortDateLabel(context, note.deletedAt!),
                    style: TextStyle(fontSize: 11, color: kTextSecondary),
                  )
                else
                  Text(
                    shortDateLabel(context, note.updatedAt),
                    style: TextStyle(fontSize: 11, color: kTextSecondary),
                  ),
              ],
            ),
            if (showActions)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    if (note.isTrashed) ...[
                      _NoteAction(
                        key: Key('note-restore-${note.id}'),
                        icon: Icons.restore,
                        tooltip: l10n.notesRestore,
                        onTap: onRestore,
                      ),
                      _NoteAction(
                        key: Key('note-purge-${note.id}'),
                        icon: Icons.delete_forever_outlined,
                        tooltip: l10n.notesPurge,
                        onTap: onPurge,
                      ),
                    ] else ...[
                      _NoteAction(
                        key: Key('note-edit-${note.id}'),
                        icon: Icons.edit_outlined,
                        tooltip: l10n.notesEdit,
                        onTap: onEdit,
                      ),
                      if (onShowInReader != null)
                        _NoteAction(
                          key: Key('note-reader-${note.id}'),
                          icon: Icons.menu_book_outlined,
                          tooltip: l10n.notesShowInReader,
                          onTap: onShowInReader,
                        ),
                      _NoteAction(
                        key: Key('note-trash-${note.id}'),
                        icon: Icons.delete_outline,
                        tooltip: l10n.notesTrash,
                        onTap: onTrash,
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NoteAction extends StatelessWidget {
  const _NoteAction({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 15, color: kTextSecondary),
        ),
      ),
    );
  }
}

/// Botón con la lista de cuadernos (con marcas) para el editor.
class NotebookSelectorButton extends StatelessWidget {
  const NotebookSelectorButton({
    super.key,
    required this.notebooks,
    required this.selected,
    required this.onToggle,
    required this.onCreate,
    this.dense = false,
  });

  final List<Notebook> notebooks;
  final List<String> selected;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onCreate;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final names = <String>[];
    for (final id in selected) {
      for (final notebook in notebooks) {
        if (notebook.id == id) names.add(notebook.name);
      }
    }
    return PopupMenuButton<String>(
      key: const Key('note-notebook-selector'),
      tooltip: l10n.noteNotebookAdd,
      onSelected: (value) =>
          value == '__new__' ? onCreate('') : onToggle(value),
      itemBuilder: (context) => [
        for (final notebook in notebooks)
          CheckedPopupMenuItem<String>(
            key: Key('note-notebook-option-${notebook.id}'),
            value: notebook.id,
            checked: selected.contains(notebook.id),
            child: Text(notebook.name, style: const TextStyle(fontSize: 13)),
          ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: '__new__',
          child: Row(
            children: [
              const Icon(Icons.add, size: 16),
              const SizedBox(width: 8),
              Text(l10n.notesNewNotebook, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
      child: NoteAnchorChip(
        label: names.isEmpty ? l10n.noteNotebookAdd : names.join(', '),
        icon: Icons.library_books_outlined,
        dense: dense,
      ),
    );
  }
}

/// Fila de etiquetas de una nota con campo para añadir.
class TagEditorRow extends ConsumerStatefulWidget {
  const TagEditorRow({
    super.key,
    required this.noteId,
    required this.tags,
    required this.onAdd,
    required this.onRemove,
  });

  final String noteId;
  final List<String> tags;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  ConsumerState<TagEditorRow> createState() => _TagEditorRowState();
}

class _TagEditorRowState extends ConsumerState<TagEditorRow> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onAdd(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final tag in widget.tags)
          InputChip(
            key: Key('note-tag-${widget.noteId}-$tag'),
            label: Text('#$tag', style: const TextStyle(fontSize: 11.5)),
            onDeleted: () => widget.onRemove(tag),
            deleteIcon: const Icon(Icons.close, size: 13),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        SizedBox(
          width: 132,
          child: TextField(
            key: Key('note-tag-field-${widget.noteId}'),
            controller: _controller,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              isDense: true,
              hintText: l10n.noteTagHint,
              hintStyle: TextStyle(fontSize: 12, color: kTextSecondary),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
            onEditingComplete: _submit,
          ),
        ),
      ],
    );
  }
}
