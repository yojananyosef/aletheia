/// Modo «Notas» del lector (M4): las notas ancladas al recurso abierto,
/// agrupadas por referencia, con el editor integrado.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization.dart';
import 'notes_browser.dart';
import 'notes_models.dart';

class ReaderNotesView extends ConsumerWidget {
  const ReaderNotesView({
    super.key,
    required this.resourceId,
    required this.anchor,
    required this.focusNoteId,
    required this.onShowInReader,
  });

  final String resourceId;

  /// Referencia actual del panel: anclaje de las notas nuevas.
  final NoteAnchor? anchor;

  /// Nota a abrir en el editor (recién creada desde una selección).
  final String? focusNoteId;

  final void Function(Note note) onShowInReader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return NotesBrowser(
      resourceId: resourceId,
      defaultAnchor: anchor,
      focusNoteId: focusNoteId,
      groupByReference: true,
      onShowInReader: onShowInReader,
      emptyTitle: l10n.readerNotesEmpty,
      emptyHint: l10n.readerNotesEmptyHint,
    );
  }
}
