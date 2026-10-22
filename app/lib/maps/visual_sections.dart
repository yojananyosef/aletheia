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

import '../catalog/document_models.dart';

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
  const VisualSectionCatalog({
    required this.maps,
    required this.media,
    this.journeys = const [],
  });

  const VisualSectionCatalog.empty()
    : maps = const [],
      media = const [],
      journeys = const [];

  final List<VisualSectionEntry> maps;
  final List<VisualSectionEntry> media;

  /// Viajes (p. ej. los de Pablo) que viajan con el bundle, sin pertenecer a
  /// un recurso del catálogo: el Atlas los lista primero.
  final List<VisualJourney> journeys;
}

/// Una ruta del Atlas empaquetada con la app (`journeys` en
/// `map_sections.json`): paradas geolocalizadas con su referencia bíblica.
class VisualJourney {
  const VisualJourney({
    required this.id,
    required this.title,
    required this.order,
    this.caption,
    this.refs = const [],
    this.stops = const [],
  });

  factory VisualJourney.fromJson(Map<String, dynamic> json) => VisualJourney(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        order: (json['order'] as num?)?.toInt() ?? 0,
        caption: json['caption'] as String?,
        refs: [
          for (final ref in (json['refs'] as List?) ?? const [])
            if (ref is String) ref,
        ],
        stops: ((json['stops'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(MapMarker.fromJson)
            .toList(),
      );

  /// Id estable (`pablo-01`…); la entrada del Atlas usa `atlas.$id`.
  final String id;
  final String title;
  final int order;
  final String? caption;

  /// Lecturas sugeridas en orden cronológico (referencias canónicas).
  final List<String> refs;

  /// Paradas en orden de visita (puede repetirse un lugar).
  final List<MapMarker> stops;

  /// Entrada equivalente para las listas del Atlas y los favoritos.
  VisualSectionEntry get entry => VisualSectionEntry(
        resource: 'atlas',
        resourceTitle: 'Atlas',
        section: id,
        title: title,
        caption: caption,
        kind: 'journey',
      );

  /// Bloque de mapa con la ruta: encuadre calculado de la caja de paradas
  /// (padding del 12 % y mínimos por si la ruta es muy compacta) y marcadores
  /// interactivos por parada.
  MapBlock? toMapBlock() {
    if (stops.length < 2) return null;
    var minLat = stops.first.lat, maxLat = minLat;
    var minLon = stops.first.lon, maxLon = minLon;
    for (final stop in stops.skip(1)) {
      if (stop.lat < minLat) minLat = stop.lat;
      if (stop.lat > maxLat) maxLat = stop.lat;
      if (stop.lon < minLon) minLon = stop.lon;
      if (stop.lon > maxLon) maxLon = stop.lon;
    }
    final latSpan = (maxLat - minLat).clamp(1.5, 60.0) * 1.24;
    final lonSpan = (maxLon - minLon).clamp(1.5, 60.0) * 1.24;
    return MapBlock(
      title: title,
      caption: caption,
      centerLat: (minLat + maxLat) / 2,
      centerLon: (minLon + maxLon) / 2,
      latSpan: latSpan,
      lonSpan: lonSpan,
      markers: stops,
      routes: [MapRoute(label: title, stops: stops)],
    );
  }
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
      journeys: [
        for (final journey in (json['journeys'] as List?) ?? const [])
          if (journey is Map<String, dynamic>) VisualJourney.fromJson(journey),
      ],
    );
  } on Object {
    return const VisualSectionCatalog.empty();
  }
});
