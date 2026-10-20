/// Editor de notas (M4): detalle con título, cuerpo markdown-lite, formato,
/// anclaje, cuadernos, etiquetas y acciones de compartir/papelera.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization.dart';
import '../core/theme.dart';
import '../references/reference_parser.dart';
import '../workspace/models.dart';
import '../workspace/workspace_controller.dart';
import 'markdown_lite.dart';
import 'notes_controller.dart';
import 'notes_models.dart';
import 'notes_ui.dart';

class NoteEditorView extends ConsumerStatefulWidget {
  const NoteEditorView({
    super.key,
    required this.noteId,
    this.onClose,
    this.onShowInReader,
    this.defaultResourceId,
    this.autofocus = false,
  });

  final String noteId;

  /// Vuelve a la lista (botón atrás/a la izquierda).
  final VoidCallback? onClose;

  /// Navega al anclaje en el lector (si el panel puede hacerlo).
  final VoidCallback? onShowInReader;

  /// Recurso por defecto al crear un anclaje nuevo (el del lector).
  final String? defaultResourceId;
  final bool autofocus;

  @override
  ConsumerState<NoteEditorView> createState() => _NoteEditorViewState();
}

class _NoteEditorViewState extends ConsumerState<NoteEditorView> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _bodyFocus = FocusNode();
  final _titleFocus = FocusNode();
  Timer? _saveTimer;
  String? _syncedNoteId;
  bool _preview = false;

  @override
  void initState() {
    super.initState();
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _bodyFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _titleController.dispose();
    _bodyController.dispose();
    _bodyFocus.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  void _flushBody() {
    final note = ref.read(notesProvider.notifier).noteById(widget.noteId);
    if (note == null) return;
    final text = _bodyController.text;
    if (note.body != text) {
      ref.read(notesProvider.notifier).updateNote(widget.noteId, body: text);
    }
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 300), _flushBody);
  }

  /// Aplica una transformación de markdown-lite al cuerpo y deja la selección.
  void _applyFormat(
    ({String text, TextSelection selection}) Function(String, TextSelection) op,
  ) {
    final controller = _bodyController;
    final selection = controller.selection;
    final effective = selection.isValid
        ? selection
        : TextSelection.collapsed(offset: controller.text.length);
    final result = op(controller.text, effective);
    controller.value = TextEditingValue(
      text: result.text,
      selection: result.selection,
    );
    _scheduleSave();
    _bodyFocus.requestFocus();
  }

  Future<void> _insertReference() async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final parsed = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.noteFormatReference),
        content: SizedBox(
          width: 320,
          child: TextField(
            key: const Key('note-reference-field'),
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.omniboxHint,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
          FilledButton(
            key: const Key('note-reference-insert'),
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(l10n.noteFormatReference),
          ),
        ],
      ),
    );
    if (parsed == null || !mounted) return;
    final reference = parseReference(parsed);
    if (reference == null) return;
    final workspace = ref.read(workspaceProvider);
    final display = reference.displayIn(context.l10nLang);
    final text = workspace.hyperlinkCitations
        ? '[$display](ref:${reference.canonical})'
        : display;
    final controller2 = _bodyController;
    final selection = controller2.selection.isValid
        ? controller2.selection
        : TextSelection.collapsed(offset: controller2.text.length);
    final updated = controller2.text.replaceRange(
      selection.start,
      selection.end,
      text,
    );
    controller2.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: selection.start + text.length),
    );
    _scheduleSave();
  }

  Future<void> _changeAnchor(Note note) async {
    final l10n = context.l10n;
    final lang = context.l10nLang;
    final current = note.mainAnchor;
    final controller = TextEditingController(
      text: current == null ? '' : noteAnchorLabel(current, lang: lang),
    );
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.noteAnchorChange),
        content: SizedBox(
          width: 320,
          child: TextField(
            key: const Key('note-anchor-field'),
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.omniboxHint,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (text) => Navigator.of(context).pop(text),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
          FilledButton(
            key: const Key('note-anchor-save'),
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(l10n.noteAnchorLabel),
          ),
        ],
      ),
    );
    if (value == null || !mounted) return;
    final parsed = parseReference(value);
    if (parsed == null) return;
    final resourceId =
        current?.resourceId ??
        widget.defaultResourceId ??
        kDefaultBibleResourceId;
    ref
        .read(notesProvider.notifier)
        .setPrimaryAnchor(
          note.id,
          NoteAnchor(
            resourceId: resourceId,
            reference: parsed.canonical,
            bookCode: parsed.bookCode,
            chapter: parsed.chapter,
            verse: parsed.verseStart,
            verseEnd: parsed.verseEnd,
            quote: current?.quote,
          ),
        );
  }

  Future<void> _createNotebook(Note note) async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.notesNewNotebook),
        content: SizedBox(
          width: 320,
          child: TextField(
            key: const Key('notebook-name-field'),
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.notesNotebookName,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (text) => Navigator.of(context).pop(text),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
          FilledButton(
            key: const Key('notebook-create'),
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(l10n.notesNotebookCreate),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    final notifier = ref.read(notesProvider.notifier);
    final id = notifier.addNotebook(name);
    notifier.toggleNotebookOnNote(note.id, id);
  }

  String _noteAsMarkdown(Note note) {
    final buffer = StringBuffer();
    final title = note.title.trim();
    if (title.isNotEmpty) buffer.writeln('# $title\n');
    final quote = note.quote;
    if (quote != null) buffer.writeln('> $quote\n');
    if (note.body.trim().isNotEmpty) buffer.writeln(note.body.trim());
    final anchor = note.mainAnchor;
    if (anchor?.reference != null) {
      buffer.writeln(
        '\n— ${displayFromCanonical(anchor!.reference!, lang: context.l10nLang)}',
      );
    }
    return buffer.toString().trim();
  }

  void _share(Note note, {required bool markdown}) {
    final l10n = context.l10n;
    final text = markdown
        ? _noteAsMarkdown(note)
        : markdownToPlain(_noteAsMarkdown(note));
    Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(l10n.noteShareCopied),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final note = ref.watch(
      notesProvider.select((state) {
        for (final note in state.notes) {
          if (note.id == widget.noteId) return note;
        }
        return null;
      }),
    );
    final notebooks = ref.watch(notesProvider).notebooks;

    if (note == null) {
      return Center(child: Text(l10n.noteShareText));
    }

    // Sincroniza los campos al abrir otra nota (o al recibir cambios externos).
    if (_syncedNoteId != note.id) {
      _syncedNoteId = note.id;
      _titleController.text = note.title;
      _bodyController.text = note.body;
    } else {
      if (_titleController.text != note.title && !_titleHasFocus) {
        _titleController.text = note.title;
      }
      if (_bodyController.text != note.body && !_bodyFocus.hasFocus) {
        _bodyController.text = note.body;
      }
    }

    final anchorLabel = note.mainAnchor == null
        ? ''
        : noteAnchorLabel(note.mainAnchor, lang: context.l10nLang);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (note.isTrashed)
          Container(
            color: kAccent.withValues(alpha: 0.12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(Icons.delete_outline, size: 16, color: kWarning),
                Text(
                  note.deletedAt == null
                      ? l10n.notesTrash
                      : l10n.noteDeletedOn(
                          shortDateLabel(context, note.deletedAt!),
                        ),
                  style: TextStyle(fontSize: 12, color: kWarning),
                ),
                TextButton(
                  key: const Key('note-editor-restore'),
                  onPressed: () =>
                      ref.read(notesProvider.notifier).restoreNote(note.id),
                  child: Text(l10n.notesRestore),
                ),
                TextButton(
                  key: const Key('note-editor-purge'),
                  onPressed: () {
                    ref.read(notesProvider.notifier).purgeNote(note.id);
                    widget.onClose?.call();
                  },
                  child: Text(l10n.notesPurge),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: kBorder)),
          ),
          child: Row(
            children: [
              if (widget.onClose != null)
                IconButton(
                  key: const Key('note-editor-back'),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  tooltip: l10n.readerBack,
                  onPressed: widget.onClose,
                  visualDensity: VisualDensity.compact,
                ),
              Flexible(
                child: NoteAnchorChip(
                  label: note.isHighlight
                      ? l10n.noteKindHighlight
                      : l10n.noteKindNote,
                  icon: note.isHighlight
                      ? Icons.format_color_fill
                      : Icons.sticky_note_2_outlined,
                ),
              ),
              const Spacer(),
              IconButton(
                key: const Key('note-editor-duplicate'),
                icon: const Icon(Icons.copy_all_outlined, size: 17),
                tooltip: l10n.notesDuplicate,
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  final id = ref
                      .read(notesProvider.notifier)
                      .duplicateNote(note.id);
                  if (id != null) widget.onClose?.call();
                },
              ),
              PopupMenuButton<String>(
                key: const Key('note-editor-share'),
                tooltip: l10n.notesShare,
                icon: const Icon(Icons.ios_share, size: 17),
                onSelected: (value) =>
                    _share(note, markdown: value == 'markdown'),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'markdown',
                    child: Text(
                      l10n.noteShareMarkdown,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'text',
                    child: Text(
                      l10n.noteShareText,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              if (!note.isTrashed)
                IconButton(
                  key: const Key('note-editor-trash'),
                  icon: const Icon(Icons.delete_outline, size: 17),
                  tooltip: l10n.notesTrash,
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    ref.read(notesProvider.notifier).trashNote(note.id);
                    widget.onClose?.call();
                  },
                ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (anchorLabel.isNotEmpty || note.quote != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (anchorLabel.isNotEmpty)
                          InkWell(
                            key: const Key('note-anchor-chip'),
                            onTap: () => _changeAnchor(note),
                            child: NoteAnchorChip(
                              label: anchorLabel,
                              icon: Icons.bookmark_border,
                            ),
                          ),
                        if (note.quote != null)
                          NoteAnchorChip(
                            label: note.quote!.length > 48
                                ? '${note.quote!.substring(0, 48)}…'
                                : note.quote!,
                            icon: Icons.format_quote,
                          ),
                        if (widget.onShowInReader != null)
                          TextButton.icon(
                            key: const Key('note-editor-show-reader'),
                            onPressed: widget.onShowInReader,
                            icon: const Icon(
                              Icons.menu_book_outlined,
                              size: 15,
                            ),
                            label: Text(
                              l10n.notesShowInReader,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                TextField(
                  key: const Key('note-title-field'),
                  controller: _titleController,
                  focusNode: _titleFocus,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.noteTitleHint,
                    hintStyle: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: kTextSecondary,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (value) {
                    _scheduleSave();
                    ref
                        .read(notesProvider.notifier)
                        .updateNote(note.id, title: value);
                  },
                  onEditingComplete: _flushBody,
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: kBorder),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    children: [
                      _FormatBar(
                        onBold: () =>
                            _applyFormat((t, s) => wrapSelection(t, s, '**')),
                        onItalic: () =>
                            _applyFormat((t, s) => wrapSelection(t, s, '*')),
                        onUnderline: () =>
                            _applyFormat((t, s) => wrapSelection(t, s, '<u>')),
                        onHighlight: () =>
                            _applyFormat((t, s) => wrapSelection(t, s, '==')),
                        onBullets: () =>
                            _applyFormat((t, s) => prefixLines(t, s, '- ')),
                        onNumbered: () =>
                            _applyFormat((t, s) => prefixLines(t, s, '1. ')),
                        onQuote: () =>
                            _applyFormat((t, s) => prefixLines(t, s, '> ')),
                        onReference: _insertReference,
                        preview: _preview,
                        onTogglePreview: () =>
                            setState(() => _preview = !_preview),
                      ),
                      if (_preview)
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 120),
                          padding: const EdgeInsets.all(10),
                          child: Text.rich(
                            TextSpan(
                              children: markdownSpans(
                                _bodyController.text,
                                TextStyle(
                                  fontSize: 13.5,
                                  color: kTextPrimary,
                                  height: 1.45,
                                ),
                                highlightColor: highlightColor('yellow'),
                              ),
                            ),
                            key: const Key('note-body-preview'),
                          ),
                        )
                      else
                        TextField(
                          key: const Key('note-body-field'),
                          controller: _bodyController,
                          focusNode: _bodyFocus,
                          maxLines: null,
                          minLines: 6,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: kTextPrimary,
                            height: 1.45,
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.noteBodyHint,
                            hintStyle: TextStyle(
                              fontSize: 13.5,
                              color: kTextSecondary,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(10),
                          ),
                          onChanged: (_) => _scheduleSave(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      l10n.noteNotebooksLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: kTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    NotebookSelectorButton(
                      notebooks: notebooks,
                      selected: note.notebooks,
                      dense: true,
                      onToggle: (id) => ref
                          .read(notesProvider.notifier)
                          .toggleNotebookOnNote(note.id, id),
                      onCreate: (_) => _createNotebook(note),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.noteTagsLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: kTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TagEditorRow(
                  noteId: note.id,
                  tags: note.tags,
                  onAdd: (tag) =>
                      ref.read(notesProvider.notifier).addTag(note.id, tag),
                  onRemove: (tag) =>
                      ref.read(notesProvider.notifier).removeTag(note.id, tag),
                ),
                if (note.isHighlight) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        l10n.noteFormatHighlight,
                        style: TextStyle(
                          fontSize: 12,
                          color: kTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      HighlightPalette(
                        selected: note.color,
                        size: 18,
                        onPick: (id) => ref
                            .read(notesProvider.notifier)
                            .updateNote(note.id, color: id),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_done_outlined,
                      size: 14,
                      color: kTextSecondary,
                    ),
                    Text(
                      l10n.noteSaved,
                      style: TextStyle(fontSize: 11.5, color: kTextSecondary),
                    ),
                    Text(
                      l10n.noteModifiedOn(
                        shortDateLabel(context, note.updatedAt),
                      ),
                      style: TextStyle(fontSize: 11.5, color: kTextSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool get _titleHasFocus => _titleFocus.hasFocus;
}

/// Barra de formato del cuerpo (markdown-lite).
class _FormatBar extends StatelessWidget {
  const _FormatBar({
    required this.onBold,
    required this.onItalic,
    required this.onUnderline,
    required this.onHighlight,
    required this.onBullets,
    required this.onNumbered,
    required this.onQuote,
    required this.onReference,
    required this.preview,
    required this.onTogglePreview,
  });

  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onUnderline;
  final VoidCallback onHighlight;
  final VoidCallback onBullets;
  final VoidCallback onNumbered;
  final VoidCallback onQuote;
  final VoidCallback onReference;
  final bool preview;
  final VoidCallback onTogglePreview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: kFieldFill,
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      // Desplazable en horizontal: en paneles estrechos siguen estando todos
      // los botones de formato al alcance.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FormatButton(
              key: const Key('format-bold'),
              icon: Icons.format_bold,
              tooltip: l10n.noteFormatBold,
              onTap: onBold,
            ),
            _FormatButton(
              key: const Key('format-italic'),
              icon: Icons.format_italic,
              tooltip: l10n.noteFormatItalic,
              onTap: onItalic,
            ),
            _FormatButton(
              key: const Key('format-underline'),
              icon: Icons.format_underlined,
              tooltip: l10n.noteFormatUnderline,
              onTap: onUnderline,
            ),
            _FormatButton(
              key: const Key('format-highlight'),
              icon: Icons.format_color_fill,
              tooltip: l10n.noteFormatHighlight,
              onTap: onHighlight,
            ),
            const SizedBox(width: 4),
            _FormatButton(
              key: const Key('format-bullets'),
              icon: Icons.format_list_bulleted,
              tooltip: l10n.noteFormatBullets,
              onTap: onBullets,
            ),
            _FormatButton(
              key: const Key('format-numbered'),
              icon: Icons.format_list_numbered,
              tooltip: l10n.noteFormatNumbered,
              onTap: onNumbered,
            ),
            _FormatButton(
              key: const Key('format-quote'),
              icon: Icons.format_quote,
              tooltip: l10n.noteFormatQuote,
              onTap: onQuote,
            ),
            const SizedBox(width: 8),
            _FormatButton(
              key: const Key('format-reference'),
              icon: Icons.link,
              tooltip: l10n.noteFormatReference,
              onTap: onReference,
            ),
            _FormatButton(
              key: const Key('format-preview'),
              icon: preview ? Icons.edit_outlined : Icons.visibility_outlined,
              tooltip: preview ? l10n.notesEdit : l10n.noteBodyHint,
              onTap: onTogglePreview,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatButton extends StatelessWidget {
  const _FormatButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 16, color: kTextSecondary),
        ),
      ),
    );
  }
}
