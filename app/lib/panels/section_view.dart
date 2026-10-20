/// Render de bloques de sección (M5).
///
/// Los recursos pequeños del catálogo (devocional fechado y Factbook) usan el
/// mismo formato de bloques que el lector (`heading`, `paragraph`,
/// `verseGroup`, `rule`). Este widget los pinta en una columna de lectura y
/// resuelve las referencias cruzadas contra el lector.
library;

import 'package:flutter/material.dart';

import '../catalog/document_models.dart';
import '../core/localization.dart';
import '../core/theme.dart';
import '../maps/bible_map.dart';
import '../reader/reader_style.dart';
import '../references/reference_parser.dart';

class SectionBlocksView extends StatelessWidget {
  const SectionBlocksView({
    super.key,
    required this.blocks,
    this.onNavigate,
    this.bodySize = 15.5,
  });

  final List<BookBlock> blocks;

  /// Referencia canónica de un enlace interno; si es `null` se abre en el
  /// lector por defecto.
  final ValueChanged<String>? onNavigate;

  final double bodySize;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    var firstHeading = true;
    for (final block in blocks) {
      switch (block) {
        case HeadingBlock heading:
          children.add(
            Padding(
              padding: EdgeInsets.only(top: firstHeading ? 0 : 22, bottom: 8),
              child: Text(
                heading.text,
                style: heading.style == 'psalmTitle'
                    ? readerBodyStyle(size: bodySize)
                          .copyWith(fontStyle: FontStyle.italic)
                    : readerBodyStyle(size: bodySize + 2.5)
                          .copyWith(fontWeight: FontWeight.w700, height: 1.35),
              ),
            ),
          );
          firstHeading = false;
        case ChapterNumberBlock number:
          children.add(
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 6),
              child: Text(
                '${number.value}',
                style: readerChapterNumberStyle().copyWith(fontSize: 26),
              ),
            ),
          );
        case VerseGroupBlock group:
          for (final verse in group.verses) {
            children.add(
              Padding(
                padding: EdgeInsets.only(
                  bottom: group.style == 'poetry' ? 2 : 10,
                  left: group.indent * 16.0,
                ),
                child: SelectionArea(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        if (verse.n > 0)
                          TextSpan(
                            text: '${verse.n} ',
                            style: readerMarkerStyle().copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ..._inlineSpans(context, verse.inlines),
                      ],
                    ),
                    style: readerBodyStyle(size: bodySize),
                  ),
                ),
              ),
            );
          }
        case RuleBlock _:
          children.add(
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: kBorder),
            ),
          );
        case MapBlock map:
          children.add(BibleMap(block: map, onNavigate: onNavigate));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  List<InlineSpan> _inlineSpans(BuildContext context, List<DocInline> inlines) {
    final spans = <InlineSpan>[];
    for (final inline in inlines) {
      switch (inline) {
        case TextInline text:
          spans.add(
            TextSpan(
              text: text.text,
              style: switch (text.style) {
                'italic' => const TextStyle(fontStyle: FontStyle.italic),
                'red' => TextStyle(color: kDangerText),
                _ => null,
              },
            ),
          );
        case LineInline _:
          spans.add(const TextSpan(text: ' '));
        case FootnoteRef _:
          break;
        case XrefLink xref:
          final canonical = parseReference(xref.ref ?? xref.label)?.canonical;
          final style = readerBodyStyle(size: bodySize)
              .copyWith(color: kAccent, fontWeight: FontWeight.w600);
          if (canonical == null) {
            spans.add(TextSpan(text: xref.label, style: style));
            break;
          }
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => onNavigate?.call(canonical),
                  child: Tooltip(
                    message: displayFromCanonical(
                      canonical,
                      lang: context.l10nLang,
                    ),
                    child: Text(xref.label, style: style),
                  ),
                ),
              ),
            ),
          );
      }
    }
    return spans;
  }
}

/// Estado vacío de un panel de sección.
class SectionEmptyState extends StatelessWidget {
  const SectionEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.detail,
  });

  final IconData icon;
  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 30, color: kTextSecondary),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            if (detail != null) ...[
              const SizedBox(height: 4),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: kTextSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
