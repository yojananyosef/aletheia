/// Panel global de **Notas** (M4): todas las notas del usuario, con búsqueda,
/// filtros, cuadernos, papelera y editor. Sustituye el placeholder de M1.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../workspace/models.dart';
import '../workspace/workspace_controller.dart';
import 'notes_browser.dart';
import 'notes_models.dart';

class NotesPanel extends ConsumerWidget {
  const NotesPanel({super.key});

  void _showInReader(BuildContext context, WidgetRef ref, Note note) {
    final anchor = note.mainAnchor;
    final reference = anchor?.reference;
    if (anchor == null || reference == null) return;
    final controller = ref.read(workspaceProvider.notifier);
    // Si el recurso ya está abierto en otro panel, navega allí; si no, abre
    // una pestaña de lectura en la referencia de la nota.
    if (controller.openInResource(
      resourceId: anchor.resourceId,
      reference: reference,
    )) {
      return;
    }
    controller.openTab(TabSpec(
      kind: PanelKind.bible,
      reference: reference,
      resourceId: anchor.resourceId,
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: kPanelBg,
      child: NotesBrowser(
        onShowInReader: (note) => _showInReader(context, ref, note),
      ),
    );
  }
}
