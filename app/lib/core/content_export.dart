/// Exportación de contenido: pasajes del lector y notas a Markdown, HTML y
/// texto plano, más el lanzador de impresión (desktop: HTML temporal en el
/// navegador del sistema).
///
/// Puro Dart salvo `openInBrowserForPrinting` (desktop). Sin dependencias
/// nuevas: los archivos los guarda el llamador (diálogo `file_selector`).
library;

import 'dart:io' show File, Platform, Process;

import '../catalog/document_models.dart';

/// Formatos de exportación disponibles.
enum ExportFormat { markdown, html, plainText }

extension ExportFormatLabel on ExportFormat {
  String get fileExtension => switch (this) {
    ExportFormat.markdown => 'md',
    ExportFormat.html => 'html',
    ExportFormat.plainText => 'txt',
  };
}

/// Contenido exportable: título (referencia), líneas y pie de atribución.
class ExportDocument {
  const ExportDocument({required this.title, required this.blocks, this.footer});

  final String title;
  final List<BookBlock> blocks;

  /// Atribución final (p. ej. «Reina-Valera 1909 · dominio público»).
  final String? footer;

  String build(ExportFormat format) => switch (format) {
    ExportFormat.markdown => buildMarkdown(),
    ExportFormat.html => buildHtml(),
    ExportFormat.plainText => buildPlainText(),
  };

  // ------------------------------------------------------------- Markdown

  String buildMarkdown() {
    final out = StringBuffer('# $title\n\n');
    for (final block in blocks) {
      out.write(_markdownBlock(block));
      out.write('\n');
    }
    final footer = this.footer;
    if (footer != null && footer.isNotEmpty) {
      out.write('\n---\n\n*$footer*\n');
    }
    return out.toString();
  }

  String _markdownBlock(BookBlock block) {
    final buffer = StringBuffer();
    switch (block) {
      case HeadingBlock(:final text):
        buffer..write('## $text')..write('\n\n');
      case ChapterNumberBlock(:final value):
        buffer..write('## Capítulo $value')..write('\n\n');
      case VerseGroupBlock(:final verses, :final style):
        if (style == 'poetry' || style == 'list') {
          for (final verse in verses) {
            buffer.write('- ${_markdownVerses(verses, verse.n)}\n');
          }
        } else {
          buffer.write(_markdownVerses(verses, null));
          buffer.write('\n\n');
        }
      case RuleBlock():
        buffer.write('---\n\n');
      case MapBlock():
        // El mapa no se exporta: se anota como referencia del lugar.
        buffer.write('*(Mapa: ${block.title})*\n\n');
    }
    return buffer.toString();
  }

  String _markdownVerses(List<Verse> verses, int? indent) {
    final buffer = StringBuffer();
    var first = true;
    for (final verse in verses) {
      if (verse.n > 0) {
        buffer.write(first ? '**${verse.n}** ' : ' **${verse.n}** ');
      }
      final text = _inlinesMarkdown(verse.inlines);
      buffer.write(text);
      first = false;
    }
    final result = buffer.toString().trim();
    return indent != null ? '  $result' : result;
  }

  String _inlinesMarkdown(List<DocInline> inlines) {
    final buffer = StringBuffer();
    for (final inline in inlines) {
      switch (inline) {
        case TextInline(:final text, :final style):
          buffer.write(switch (style) {
            'italic' => '*${_escapeMarkdown(text)}*',
            'bold' => '**${_escapeMarkdown(text)}**',
            _ => _escapeMarkdown(text),
          });
        case FootnoteRef(:final label):
          buffer.write(' [${label ?? 'nota'}]');
        case XrefLink(:final label):
          buffer.write(label);
        case LineInline():
          buffer.write('\n');
      }
    }
    return buffer.toString();
  }

  String _escapeMarkdown(String text) => text.replaceAll('*', '\\*');

  // ----------------------------------------------------------------- HTML

  String buildHtml() {
    final buffer = StringBuffer()
      ..writeln('<!DOCTYPE html>')
      ..writeln('<html lang="es">')
      ..writeln('<head>')
      ..writeln('<meta charset="utf-8">')
      ..writeln('<title>${_htmlEscape(title)}</title>')
      ..writeln('<style>')
      ..writeln(
        'body{font-family:Georgia,serif;max-width:34em;margin:2em auto;'
        'line-height:1.65;color:#222}',
      )
      ..writeln('h1{font-size:1.6em} h2{font-size:1.2em;color:#555}')
      ..writeln('sup{color:#8a6d1a} footer{margin-top:2em;color:#666;'
        'font-size:.85em;border-top:1px solid #ddd;padding-top:.6em}')
      ..writeln('</style>')
      ..writeln('</head>')
      ..writeln('<body>')
      ..writeln('<h1>${_htmlEscape(title)}</h1>');
    for (final block in blocks) {
      _htmlBlock(buffer, block);
    }
    final footer = this.footer;
    if (footer != null && footer.isNotEmpty) {
      buffer.writeln('<footer>${_htmlEscape(footer)}</footer>');
    }
    buffer
      ..writeln('</body>')
      ..writeln('</html>');
    return buffer.toString();
  }

  void _htmlBlock(StringBuffer buffer, BookBlock block) {
    switch (block) {
      case HeadingBlock(:final text):
        buffer.writeln('<h2>${_htmlEscape(text)}</h2>');
      case ChapterNumberBlock(:final value):
        buffer.writeln('<h2>Capítulo ${_htmlEscape('$value')}</h2>');
      case VerseGroupBlock(:final verses, :final style, :final indent):
        if (style == 'poetry' || style == 'list') {
          buffer.writeln('<ul>');
          for (final verse in verses) {
            buffer.writeln('<li>${_htmlInlines(verse)}</li>');
          }
          buffer.writeln('</ul>');
        } else {
          final margin = indent > 0 ? ' style="margin-left:${indent * 2}em"' : '';
          buffer.writeln('<p$margin>${_htmlVerses(verses)}</p>');
        }
      case RuleBlock():
        buffer.writeln('<hr>');
      case MapBlock():
        buffer.writeln('<p><em>Mapa: ${_htmlEscape(block.title)}</em></p>');
    }
  }

  String _htmlVerses(List<Verse> verses) {
    final buffer = StringBuffer();
    for (final verse in verses) {
      if (verse.n > 0) buffer.write('<sup>${verse.n}</sup> ');
      buffer.write(_htmlInlines(verse));
    }
    return buffer.toString();
  }

  String _htmlInlines(Verse verse) {
    final buffer = StringBuffer();
    for (final inline in verse.inlines) {
      switch (inline) {
        case TextInline(:final text, :final style):
          final escaped = _htmlEscape(text);
          buffer.write(switch (style) {
            'italic' => '<em>$escaped</em>',
            'bold' => '<strong>$escaped</strong>',
            _ => escaped,
          });
        case FootnoteRef(:final label):
          buffer.write('<sup>[${
            _htmlEscape(label ?? 'nota')
          }]</sup>');
        case XrefLink(:final label):
          buffer.write(_htmlEscape(label));
        case LineInline():
          buffer.write('<br>');
      }
    }
    return buffer.toString();
  }

  String _htmlEscape(String text) => text
      .replaceAll('&', '\u0026amp;')
      .replaceAll('<', '\u0026lt;')
      .replaceAll('>', '\u0026gt;')
      .replaceAll('"', '\u0026quot;');

  // ---------------------------------------------------------- Texto plano

  String buildPlainText() {
    final buffer = StringBuffer('$title\n${'=' * title.length}\n\n');
    for (final block in blocks) {
      switch (block) {
        case HeadingBlock(:final text):
          buffer
            ..writeln(text)
            ..writeln();
        case ChapterNumberBlock(:final value):
          buffer
            ..writeln('Capítulo $value')
            ..writeln();
        case VerseGroupBlock(:final verses, :final style):
          if (style == 'poetry' || style == 'list') {
            for (final _ in verses) {
              buffer.writeln('  · ${_plainVerses(verses)}');
            }
          } else {
            buffer
              ..writeln(_plainVerses(verses))
              ..writeln();
          }
        case RuleBlock():
          buffer
            ..writeln('---')
            ..writeln();
        case MapBlock():
          buffer.writeln('(Mapa: ${block.title})\n');
      }
    }
    final footer = this.footer;
    if (footer != null && footer.isNotEmpty) {
      buffer
        ..writeln('---')
        ..writeln(footer);
    }
    return buffer.toString();
  }

  String _plainVerses(List<Verse> verses) {
    final buffer = StringBuffer();
    for (final verse in verses) {
      if (verse.n > 0) buffer.write('${verse.n} ');
      for (final inline in verse.inlines) {
        switch (inline) {
          case TextInline(:final text):
            buffer.write(text);
          case FootnoteRef(:final label):
            buffer.write(' [${label ?? 'nota'}]');
          case XrefLink(:final label):
            buffer.write(label);
          case LineInline():
            buffer.write('\n');
        }
      }
    }
    return buffer.toString().trim();
  }
}

/// Convierte el cuerpo markdown-lite de una nota a los formatos de export.
class NoteExportDocument {
  const NoteExportDocument({
    required this.title,
    required this.body,
    this.citation,
    this.tags = const [],
  });

  final String title;

  /// Cuerpo markdown-lite tal como lo guarda la nota.
  final String body;
  final String? citation;
  final List<String> tags;

  String build(ExportFormat format) => switch (format) {
    ExportFormat.markdown => buildMarkdown(),
    ExportFormat.html => buildHtml(),
    ExportFormat.plainText => buildPlainText(),
  };

  String buildMarkdown() {
    final buffer = StringBuffer('# $title\n\n');
    if (citation != null && citation!.isNotEmpty) {
      buffer.writeln('*$citation*\n');
    }
    buffer
      ..writeln(body)
      ..writeln();
    if (tags.isNotEmpty) {
      buffer.writeln('Etiquetas: ${tags.map((t) => '`$t`').join(' · ')}\n');
    }
    return buffer.toString();
  }

  String buildHtml() {
    final buffer = StringBuffer()
      ..writeln('<!DOCTYPE html>')
      ..writeln('<html lang="es"><head><meta charset="utf-8">')
      ..writeln('<title>${_esc(title)}</title>')
      ..writeln(
        '<style>body{font-family:Georgia,serif;max-width:34em;margin:2em auto;'
        'line-height:1.6;color:#222} blockquote{border-left:3px solid #ccc;'
        'margin-left:0;padding-left:1em;color:#555} mark{background:#fff3a3}'
        '</style></head><body>',
      )
      ..writeln('<h1>${_esc(title)}</h1>');
    if (citation != null && citation!.isNotEmpty) {
      buffer.writeln('<p><em>${_esc(citation!)}</em></p>');
    }
    for (final fragment in _markdownLines(body)) {
      buffer.writeln(fragment);
    }
    if (tags.isNotEmpty) {
      buffer.writeln(
        '<p><small>Etiquetas: ${tags.map(_esc).join(' · ')}</small></p>',
      );
    }
    buffer.writeln('</body></html>');
    return buffer.toString();
  }

  String buildPlainText() {
    final buffer = StringBuffer('$title\n\n');
    if (citation != null && citation!.isNotEmpty) {
      buffer
        ..writeln(citation!)
        ..writeln();
    }
    buffer
      ..writeln(_stripMarkdown(body))
      ..writeln();
    if (tags.isNotEmpty) {
      buffer.writeln('Etiquetas: ${tags.join(' · ')}');
    }
    return buffer.toString();
  }

  // Conversión markdown-lite → HTML (párrafo a párrafo).

  Iterable<String> _markdownLines(String source) sync* {
    var inList = false;
    for (final rawLine in source.split('\n')) {
      final line = rawLine.trimRight();
      final bullet = RegExp(r'^(\s*)[-*]\s+(.*)$').firstMatch(line);
      final ordered = RegExp(r'^(\s*)\d+\.\s+(.*)$').firstMatch(line);
      if (bullet != null || ordered != null) {
        if (!inList) {
          yield '<ul>';
          inList = true;
        }
        final content = (bullet?.group(2) ?? ordered?.group(2)) ?? '';
        yield '<li>${_inlineHtml(_esc(content))}</li>';
        continue;
      }
      if (inList) {
        yield '</ul>';
        inList = false;
      }
      if (line.startsWith('> ')) {
        yield '<blockquote>${_inlineHtml(_esc(line.substring(2)))}</blockquote>';
      } else if (line.startsWith('# ')) {
        yield '<h2>${_inlineHtml(_esc(line.substring(2)))}</h2>';
      } else if (line.trim().isEmpty) {
        continue;
      } else {
        yield '<p>${_inlineHtml(_esc(line))}</p>';
      }
    }
    if (inList) yield '</ul>';
  }

  /// Negrita, cursiva, subrayado, resaltado y enlaces `ref:` sobre texto ya
  /// escapado.
  String _inlineHtml(String escaped) => escaped
      .replaceAllMapped(
        RegExp(r'\*\*(.+?)\*\*'),
        (m) => '<strong>${m.group(1)}</strong>',
      )
      .replaceAllMapped(
        RegExp(r'__(.+?)__'),
        (m) => '<u>${m.group(1)}</u>',
      )
      .replaceAllMapped(
        RegExp(r'\*(.+?)\*'),
        (m) => '<em>${m.group(1)}</em>',
      )
      .replaceAllMapped(
        RegExp(r'==(.+?)=='),
        (m) => '<mark>${m.group(1)}</mark>',
      )
      .replaceAllMapped(
        RegExp(r'\[([^\]]+)\]\(ref:([^)]+)\)'),
        (m) => '<a href="#">${m.group(1)}</a>',
      );

  String _stripMarkdown(String source) => source
      .replaceAllMapped(RegExp(r'^\s*[-*]\s+', multiLine: true), (_) => '· ')
      .replaceAll('**', '')
      .replaceAll('==', '')
      .replaceAll('__', '')
      .replaceAll('_', '')
      .replaceAll('*', '')
      .replaceAllMapped(
        RegExp(r'\[([^\]]+)\]\(ref:([^)]+)\)'),
        (m) => m.group(1) ?? '',
      );

  String _esc(String text) => text
      .replaceAll('&', '\u0026amp;')
      .replaceAll('<', '\u0026lt;')
      .replaceAll('>', '\u0026gt;');
}

/// Abre un HTML temporal en el navegador del sistema para imprimir
/// (Ctrl+P). Sólo escritorio; en web el llamador ofrece copiar.
Future<void> openInBrowserForPrinting(File htmlFile) async {
  await openInBrowserForPrintingUrl(htmlFile.path);
}

/// Abre una URL o archivo con el manejador por defecto del sistema
/// (escritorio; en web no hace nada).
Future<void> openInBrowserForPrintingUrl(String target) async {
  if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return;
  if (Platform.isWindows) {
    await Process.run('cmd', ['/c', 'start', '', target], runInShell: false);
  } else if (Platform.isMacOS) {
    await Process.run('open', [target]);
  } else {
    await Process.run('xdg-open', [target]);
  }
}
