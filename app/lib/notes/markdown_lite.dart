/// Editor y presentación «markdown-lite» de las notas (M4).
///
/// Subconjunto suficiente para las notas del clon: `**negrita**`, `*cursiva*`
/// (o `_cursiva_`), `<u>subrayado</u>`, `==resaltado==`, listas (`- `, `1. `)
/// y citas (`> `). Puro y testeable; el editor solo aplica las operaciones al
/// texto y a la selección actual.
library;

import 'package:flutter/material.dart';

/// Aplica [marker] al principio y al final de la selección (o inserta el par
/// vacío para escribir dentro). Devuelve el texto y la selección resultantes.
({String text, TextSelection selection}) wrapSelection(
  String text,
  TextSelection selection,
  String marker,
) {
  final start = selection.start.clamp(0, text.length);
  final end = selection.end.clamp(0, text.length);
  final selected = text.substring(start, end);
  if (selected.isEmpty) {
    final next = text.replaceRange(start, end, '$marker$marker');
    return (
      text: next,
      selection: TextSelection.collapsed(offset: start + marker.length),
    );
  }
  // Si ya está envuelto, quitamos el formato.
  if (selected.startsWith(marker) &&
      selected.endsWith(marker) &&
      selected.length >= marker.length * 2) {
    final inner =
        selected.substring(marker.length, selected.length - marker.length);
    final next = text.replaceRange(start, end, inner);
    return (
      text: next,
      selection:
          TextSelection(baseOffset: start, extentOffset: start + inner.length),
    );
  }
  final inner = '$marker$selected$marker';
  final next = text.replaceRange(start, end, inner);
  return (
    text: next,
    selection: TextSelection(
      baseOffset: start + marker.length,
      extentOffset: start + marker.length + selected.length,
    ),
  );
}

/// Aplica un prefijo de línea (`- `, `1. `, `> `) a las líneas seleccionadas
/// (o a la línea del cursor). Si todas las líneas ya lo llevan, se quita.
({String text, TextSelection selection}) prefixLines(
  String text,
  TextSelection selection,
  String prefix,
) {
  final start = selection.start.clamp(0, text.length);
  final end = selection.end.clamp(0, text.length);
  final lineStart = text.lastIndexOf('\n', start > 0 ? start - 1 : 0) + 1;
  var lineEnd = text.indexOf('\n', end);
  if (lineEnd < 0) lineEnd = text.length;

  final block = text.substring(lineStart, lineEnd);
  final lines = block.split('\n');
  final nonEmpty = lines.where((l) => l.trim().isNotEmpty).toList();
  final hasPrefix =
      nonEmpty.isNotEmpty && nonEmpty.every((l) => l.startsWith(prefix));

  final next = hasPrefix
      ? [
          for (final line in lines)
            line.startsWith(prefix) ? line.substring(prefix.length) : line,
        ].join('\n')
      : [for (final line in lines) '$prefix$line'].join('\n');

  final updated = text.replaceRange(lineStart, lineEnd, next);
  return (
    text: updated,
    selection: TextSelection(
      baseOffset: lineStart,
      extentOffset: lineStart + next.length,
    ),
  );
}

/// Fragmento con estilo dentro del markdown-lite.
class MarkdownFragment {
  const MarkdownFragment(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.highlight = false,
    this.prefix = '',
  });

  final String text;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool highlight;

  /// Viñeta o marca de cita del inicio de la línea.
  final String prefix;
}

/// Fragmentos del markdown-lite, con los marcadores ya resueltos.
List<MarkdownFragment> markdownFragments(String source) {
  final fragments = <MarkdownFragment>[];
  final buffer = StringBuffer();
  var bold = false;
  var italic = false;
  var underline = false;
  var highlight = false;
  var prefix = '';

  void flush() {
    if (buffer.isEmpty) return;
    fragments.add(MarkdownFragment(
      buffer.toString(),
      bold: bold,
      italic: italic,
      underline: underline,
      highlight: highlight,
      prefix: prefix,
    ));
    buffer.clear();
    prefix = '';
  }

  for (final rawLine in source.split('\n')) {
    prefix = '';
    final match = RegExp(r'^(\s*)([-*]|\d+\.|>)\s+').firstMatch(rawLine);
    final line = match == null ? rawLine : rawLine.substring(match.end);
    if (match != null) prefix = match.group(2) == '>' ? '▏ ' : '• ';

    var i = 0;
    while (i < line.length) {
      final two = i + 2 <= line.length ? line.substring(i, i + 2) : '';
      final three = i + 3 <= line.length ? line.substring(i, i + 3) : '';
      final four = i + 4 <= line.length ? line.substring(i, i + 4) : '';
      if (three == '<u>') {
        flush();
        underline = true;
        i += 3;
        continue;
      }
      if (four == '</u>') {
        flush();
        underline = false;
        i += 4;
        continue;
      }
      if (two == '**') {
        flush();
        bold = !bold;
        i += 2;
        continue;
      }
      if (two == '==') {
        flush();
        highlight = !highlight;
        i += 2;
        continue;
      }
      final char = line[i];
      if (char == '*' || char == '_') {
        flush();
        italic = !italic;
        i += 1;
        continue;
      }
      buffer.write(char);
      i += 1;
    }
    flush();
    fragments.add(const MarkdownFragment('\n'));
  }
  if (fragments.isNotEmpty) fragments.removeLast();
  return fragments;
}

/// Convierte el markdown-lite a texto plano (para tarjetas y portapapeles).
String markdownToPlain(String source) {
  final buffer = StringBuffer();
  for (final fragment in markdownFragments(source)) {
    buffer.write(fragment.prefix);
    buffer.write(fragment.text);
  }
  return buffer.toString().trim();
}

/// Spans del markdown-lite con [style] como base (resaltado opcional).
List<InlineSpan> markdownSpans(
  String source,
  TextStyle style, {
  Color? highlightColor,
}) {
  final spans = <InlineSpan>[];
  for (final fragment in markdownFragments(source)) {
    final textStyle = style.copyWith(
      fontWeight: fragment.bold ? FontWeight.w600 : null,
      fontStyle: fragment.italic ? FontStyle.italic : null,
      decoration:
          fragment.underline ? TextDecoration.underline : TextDecoration.none,
      backgroundColor:
          fragment.highlight && highlightColor != null ? highlightColor : null,
    );
    spans.add(TextSpan(text: fragment.prefix + fragment.text, style: textStyle));
  }
  return spans;
}
