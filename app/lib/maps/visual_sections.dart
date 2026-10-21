/// Manifiesto empaquetado de mapas y contenido visual.
///
/// `sync_app_catalog.py` lo genera a partir de los bloques `map` del Factbook
/// y del comentario. Atlas y Medios lo leen directamente del bundle para
/// listar las entradas sin descargar el índice FTS ni depender de una ruta
/// remota que puede no existir en una versión antigua del catálogo.
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VisualSectionEntry {
  const VisualSectionEntry({
    required this.resource,
    required this.resourceTitle,
    required this.section,
    required this.title,
    this.caption,
    this.kind = 'map',
  });

  factory VisualSectionEntry.fromJson(Map<String, dynamic> json) =>
      VisualSectionEntry(
        resource: json['resource'] as String? ?? '',
        resourceTitle: json['resourceTitle'] as String? ?? '',
        section: json['section'] as String? ?? '',
        title: json['title'] as String? ?? '',
        caption: json['caption'] as String?,
        kind: json['kind'] as String? ?? 'map',
      );

  /// Id del recurso (`factbook.core` o el comentario).
  final String resource;
  final String resourceTitle;

  /// Id de la sección que contiene el bloque (`JHN.3`, `fe`, …).
  final String section;
  final String title;
  final String? caption;

  /// `map` por ahora; queda abierto a otros bloques visuales.
  final String kind;

  bool get isCommentary => resource.startsWith('commentary.');

  String get sourceLabel => isCommentary ? 'Comentario' : 'Factbook';
}

class VisualSectionCatalog {
  const VisualSectionCatalog({required this.maps, required this.media});

  const VisualSectionCatalog.empty() : maps = const [], media = const [];

  final List<VisualSectionEntry> maps;
  final List<VisualSectionEntry> media;
}

/// Lista de mapas y medios empaquetada con la app.
final visualSectionsProvider = FutureProvider<VisualSectionCatalog>((
  ref,
) async {
  try {
    final text = await rootBundle.loadString(
      'assets/catalog/map_sections.json',
    );
    final json = jsonDecode(text);
    if (json is! Map<String, dynamic>) {
      return const VisualSectionCatalog.empty();
    }
    List<VisualSectionEntry> parse(Object? value) => [
      for (final entry in (value as List? ?? const []))
        if (entry is Map<String, dynamic>) VisualSectionEntry.fromJson(entry),
    ];
    return VisualSectionCatalog(
      maps: parse(json['maps']),
      media: parse(json['media']),
    );
  } on Object {
    return const VisualSectionCatalog.empty();
  }
});
