/// Piezas compartidas de los resultados de búsqueda: el panel de Búsqueda
/// (M2) y la búsqueda dentro del panel del lector (`ReaderSearchView`).
library;

import 'package:flutter/material.dart';

import '../catalog/catalog_models.dart';
import '../core/theme.dart';

/// Fila de un resultado: cita en azul, sigla del recurso y fragmento con las
/// coincidencias resaltadas por el servicio (`<em>…</em>`).
class SearchHitTile extends StatelessWidget {
  const SearchHitTile({super.key, required this.hit, this.onTap});

  final SearchHit hit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    hit.citation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kAccent,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (hit.abbrev != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: kBorder),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      hit.abbrev!,
                      style: TextStyle(fontSize: 10.5, color: kTextSecondary),
                    ),
                  ),
                if (hit.locked)
                  Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(
                      Icons.lock_outline,
                      size: 13,
                      color: kTextSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            SnippetText(hit.snippet),
          ],
        ),
      ),
    );
  }
}

/// Fragmento con las coincidencias marcadas por el servicio (`<em>…</em>`).
class SnippetText extends StatelessWidget {
  const SnippetText(this.snippet, {super.key});

  final String snippet;

  static final _emphasis = RegExp(r'<em>(.*?)</em>', dotAll: true);

  List<TextSpan> _spans() {
    final spans = <TextSpan>[];
    var index = 0;
    for (final match in _emphasis.allMatches(snippet)) {
      if (match.start > index) {
        spans.add(TextSpan(text: snippet.substring(index, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: kAccentDark,
          ),
        ),
      );
      index = match.end;
    }
    if (index < snippet.length) {
      spans.add(TextSpan(text: snippet.substring(index)));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: _spans()),
      style: TextStyle(fontSize: 12.8, height: 1.45, color: kTextPrimary),
    );
  }
}
