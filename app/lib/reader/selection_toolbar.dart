import 'package:flutter/material.dart';

import '../core/localization.dart';
import '../core/theme.dart';
import '../notes/notes_models.dart';

/// Menú de una selección en el lector, con la estructura del original
/// (según la evidencia de reconocimiento §2): una fila de acciones
/// —Copiar · Consultar (solo con una palabra) · Buscar · Mostrar más
/// opciones— y otra de anotaciones: Agregar nota, los cinco colores de
/// resaltado y el Subrayado rojo.
///
/// Desviaciones documentadas: el original ofrece además `Explicar`,
/// `Preguntar` (Asistente de estudio con IA) y `Estudio de palabra bíblica`;
/// el clon no tiene servicio de IA (M6/M7) y los omite. El menú completo del
/// original muestra los *sujetos del contexto* (referencia y entidades
/// detectadas) en una columna a la izquierda, que aquí no se replican.
class SelectionToolbar extends StatelessWidget {
  const SelectionToolbar({
    super.key,
    required this.singleWord,
    required this.onCopy,
    required this.onLookUp,
    required this.onSearch,
    required this.onNote,
    required this.onHighlight,
    required this.onVisualCopy,
    this.activeColor,
    this.canRemoveHighlight = false,
    this.onRemoveHighlight,
  });

  /// `true` cuando la selección es una sola palabra (habilita `Consultar`,
  /// como en el original).
  final bool singleWord;
  final VoidCallback onCopy;
  final VoidCallback onLookUp;
  final VoidCallback onSearch;
  final VoidCallback onNote;

  /// Color y estilo (`kHighlightStyleIds`) del resaltado elegido.
  final void Function(String color, String style) onHighlight;
  final VoidCallback onVisualCopy;

  /// Color del resaltado que ya cubre la selección (se marca en la paleta).
  final String? activeColor;

  /// Hay un resaltado bajo la selección que se puede quitar.
  final bool canRemoveHighlight;
  final VoidCallback? onRemoveHighlight;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: kPanelBg,
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TextAction(label: l10n.selectionCopy, onPressed: onCopy),
                if (singleWord)
                  _TextAction(label: l10n.selectionLookUp, onPressed: onLookUp),
                _TextAction(label: l10n.selectionSearch, onPressed: onSearch),
                PopupMenuButton<String>(
                  key: const Key('selection-more-options'),
                  tooltip: l10n.selectionMore,
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.expand_more, size: 18),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'visual-copy',
                      child: Text(l10n.selectionVisualCopy),
                    ),
                    PopupMenuItem(
                      value: 'underline-red',
                      child: Text(l10n.selectionUnderlineRed),
                    ),
                  ],
                  onSelected: (value) => switch (value) {
                    'visual-copy' => onVisualCopy(),
                    _ => onHighlight(
                      kDefaultUnderlineColor,
                      kHighlightStyleUnderline,
                    ),
                  },
                ),
              ],
            ),
            const SizedBox(height: 1),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconAction(
                  key: const Key('selection-add-note'),
                  tooltip: l10n.selectionAddNote,
                  icon: Icons.sticky_note_2_outlined,
                  onPressed: onNote,
                ),
                for (final colorId in kHighlightPickColorIds)
                  _Swatch(
                    key: Key('selection-highlight-$colorId'),
                    tooltip: l10n.highlightSwatch(_colorName(context, colorId)),
                    color: highlightColor(colorId),
                    selected: activeColor == colorId,
                    onPressed: () =>
                        onHighlight(colorId, kHighlightStyleHighlight),
                  ),
                if (canRemoveHighlight)
                  _IconAction(
                    key: const Key('selection-highlight-remove'),
                    tooltip: l10n.selectionRemoveHighlight,
                    icon: Icons.format_color_reset,
                    onPressed: onRemoveHighlight ?? () {},
                  ),
                _IconAction(
                  key: const Key('selection-underline-red'),
                  tooltip: l10n.selectionUnderlineRed,
                  icon: Icons.format_underline,
                  color: highlightColor(kDefaultUnderlineColor),
                  onPressed: () => onHighlight(
                    kDefaultUnderlineColor,
                    kHighlightStyleUnderline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _colorName(BuildContext context, String colorId) {
    final l10n = context.l10n;
    return switch (colorId) {
      'green' => l10n.noteColorGreen,
      'blue' => l10n.noteColorBlue,
      'red' => l10n.noteColorRed,
      'orange' => l10n.noteColorOrange,
      'pink' => l10n.noteColorPink,
      _ => l10n.noteColorYellow,
    };
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: kTextPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: Theme.of(context).textTheme.labelMedium
            ?.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      child: Text(label),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: 17,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 30, height: 28),
      color: color ?? kTextSecondary,
      icon: Icon(icon),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    super.key,
    required this.tooltip,
    required this.color,
    required this.onPressed,
    this.selected = false,
  });

  final String tooltip;
  final Color color;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 30,
          height: 28,
          child: Center(
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: selected ? kAccentDark : kBorder,
                  width: selected ? 2.5 : 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
