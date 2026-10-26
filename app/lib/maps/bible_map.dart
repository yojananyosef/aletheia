/// Mapas bíblicos offline.
///
/// La geometría de costas y lagos viene de Natural Earth (dominio público);
/// las coordenadas de los lugares, de OpenBible.info (CC BY 4.0). El widget
/// dibuja un encuadre esquemático con `CustomPainter`, sin teselas ni red.
library;

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/document_models.dart';
import '../core/localization.dart';
import '../core/theme.dart';
import '../references/reference_parser.dart';

class MapGeometry {
  const MapGeometry({
    required this.land,
    required this.lakes,
    this.rivers = const [],
    this.boundaries = const [],
    this.riverLabelAnchors = const {},
  });

  final List<List<Offset>> land;
  final List<List<Offset>> lakes;

  /// Cuerpos fluviales (ríos) y regalías de límites de país: cadenas abiertas
  /// de (lon, lat) que [geoJsonToChains] levanta de un GeoJSON de líneas.
  final List<List<Offset>> rivers;
  final List<List<Offset>> boundaries;

  /// Ancla (lon, lat) por río — nombre ya traducido — para el texto repetido
  /// a lo largo del cauce en lugar del rótulo flotante (estilo atlas).
  final Map<String, Offset> riverLabelAnchors;
}

final mapGeometryProvider = FutureProvider<MapGeometry>((ref) async {
  final required = await Future.wait([
    rootBundle.loadString('assets/maps/ne_110m_land.geojson'),
    rootBundle.loadString('assets/maps/ne_110m_lakes.geojson'),
  ]);
  // Ríos y límites son enriquecimiento: si faltan los assets el mapa sigue
  // funcionando con costas y lagos.
  Future<String> optional(String asset) async {
    try {
      return await rootBundle.loadString(asset);
    } catch (_) {
      return '';
    }
  }

  return mapGeometryFromGeoJson(
    land: required[0],
    lakes: required[1],
    rivers: await optional('assets/maps/ne_rivers.geojson'),
    boundaries: await optional('assets/maps/ne_boundaries.geojson'),
  );
});

/// Levanta la geometría completa desde los GeoJSON empaquetados. Público para
/// poder testear el parseo de líneas sin assets.
MapGeometry mapGeometryFromGeoJson({
  required String land,
  required String lakes,
  required String rivers,
  required String boundaries,
}) {
  final named = <_GeoFeature>[];
  for (final feature in _GeoFeature.fromGeoJson(rivers)) {
    named.add(feature);
  }
  return MapGeometry(
    land: _polygons(land),
    lakes: _polygons(lakes),
    rivers: [for (final f in named) ...f.runs],
    boundaries: [
      for (final f in _GeoFeature.fromGeoJson(boundaries)) ...f.runs,
    ],
    riverLabelAnchors: _riverLabelAnchors(named),
  );
}

/// Nombre en castellano de los ríos del caché (null = no rotular); agrupa
/// variantes del mismo cauce para que Éufrates salga una sola vez.
const _riverNameEs = <String, String>{
  'Nile': 'Nilo',
  'Danube': 'Danubio',
  'Donau': 'Danubio',
  'Euphrates': 'Éufrates',
  'Al Furat': 'Éufrates',
  'Firat': 'Éufrates',
  'Tigris': 'Tigris',
  'Dicle': 'Tigris',
  'Jordan': 'Jordán',
};

/// Por río (nombre ya traducido) conserva el punto medio del tramo más largo:
/// tal vez quede fuera de algún encuadre, pero nunca dentro de la cola corta.
Map<String, Offset> _riverLabelAnchors(List<_GeoFeature> features) {
  final anchors = <String, Offset>{};
  final lengths = <String, double>{};
  for (final feature in features) {
    final es = _riverNameEs[feature.name];
    if (es == null) continue;
    final longest = feature.runs.reduce(
      (a, b) => _chainLength(b) > _chainLength(a) ? b : a,
    );
    final length = _chainLength(longest);
    if (length > (lengths[es] ?? -1)) {
      lengths[es] = length;
      anchors[es] = longest[longest.length ~/ 2];
    }
  }
  return anchors;
}

double _chainLength(List<Offset> chain) {
  var total = 0.0;
  for (var i = 1; i < chain.length; i++) {
    total += (chain[i] - chain[i - 1]).distance;
  }
  return total;
}

class _GeoFeature {
  const _GeoFeature({required this.name, required this.runs});

  final String? name;
  final List<List<Offset>> runs;

  static List<_GeoFeature> fromGeoJson(String source) {
    final json = jsonDecode(source.isEmpty ? '{"features":[]}' : source);
    if (json is! Map<String, dynamic>) return const [];
    final out = <_GeoFeature>[];
    for (final feature
        in ((json['features'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()) {
      final geometry = feature['geometry'];
      if (geometry is! Map<String, dynamic>) continue;
      final coordinates = geometry['coordinates'];
      final runs = <List<Offset>>[];
      void addLine(Object? line) {
        if (line is! List) return;
        final points = <Offset>[];
        for (final pair in line) {
          if (pair is List && pair.length >= 2) {
            final lon = pair[0];
            final lat = pair[1];
            if (lon is num && lat is num) {
              points.add(Offset(lon.toDouble(), lat.toDouble()));
            }
          }
        }
        if (points.length >= 2) runs.add(points);
      }

      switch (geometry['type']) {
        case 'LineString':
          addLine(coordinates);
        case 'MultiLineString':
          if (coordinates is List) {
            for (final line in coordinates) {
              addLine(line);
            }
          }
      }
      if (runs.isNotEmpty) {
        out.add(
          _GeoFeature(
            name: feature['properties']?['name'] as String?,
            runs: runs,
          ),
        );
      }
    }
    return out;
  }
}

/// Convierte un GeoJSON de líneas (LineString/MultiLineString) en cadenas de
/// (lon, lat). Público para tests.
List<List<Offset>> geoJsonToChains(String source) => [
  for (final f in _GeoFeature.fromGeoJson(source)) ...f.runs,
];

List<List<Offset>> _polygons(String source) {
  final json = jsonDecode(source);
  if (json is! Map<String, dynamic>) return const [];
  final features = (json['features'] as List?) ?? const [];
  final rings = <List<Offset>>[];
  for (final feature in features.whereType<Map<String, dynamic>>()) {
    final geometry = feature['geometry'];
    if (geometry is! Map<String, dynamic>) continue;
    final coordinates = geometry['coordinates'];
    switch (geometry['type']) {
      case 'Polygon':
        _appendPolygon(rings, coordinates);
      case 'MultiPolygon':
        if (coordinates is List) {
          for (final polygon in coordinates) {
            _appendPolygon(rings, polygon);
          }
        }
    }
  }
  return rings;
}

void _appendPolygon(List<List<Offset>> rings, Object? polygon) {
  if (polygon is! List) return;
  for (final ring in polygon) {
    if (ring is! List) continue;
    final points = <Offset>[];
    for (final pair in ring) {
      if (pair is List && pair.length >= 2) {
        final lon = pair[0];
        final lat = pair[1];
        if (lon is num && lat is num) {
          points.add(Offset(lon.toDouble(), lat.toDouble()));
        }
      }
    }
    if (points.length >= 3) rings.add(points);
  }
}

/// Diálogo de mapa completo: reutiliza [BibleMap] a casi toda la pantalla,
/// sin su fila de título (para no duplicar el encabezado) y con un botón de
/// cierre flotante; cierra también con clic fuera o Escape.
void _openFullMapDialog(BuildContext context, MapBlock block) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final size = MediaQuery.of(dialogContext).size;
      final width = (size.width * 0.92).clamp(480.0, 1700.0);
      final height = (size.height * 0.86).clamp(360.0, 1000.0);
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            SizedBox(
              width: width,
              height: height,
              child: BibleMap(block: block, showHeader: false),
            ),
            Positioned(
              top: 10,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  key: const ValueKey('map-full-close'),
                  tooltip: dialogContext.l10n.close,
                  icon: Icon(Icons.close, size: 20, color: kTextSecondary),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Mapa de una sección con marcadores interactivos.
///
/// Si un marcador trae `ref`, al pulsarlo se llama a [onNavigate] con la
/// referencia canónica; así el mapa funciona como un índice del pasaje.
class BibleMap extends ConsumerWidget {
  const BibleMap({
    super.key,
    required this.block,
    this.onNavigate,
    this.showHeader = true,
    this.expandable = false,
  });

  final MapBlock block;
  final ValueChanged<String>? onNavigate;

  /// Oculta la fila de título; el modal de mapa completo la usa para no
  /// duplicar el encabezado.
  final bool showHeader;

  /// Muestra el botón que abre el mapa completo en un diálogo grande.
  final bool expandable;

  VoidCallback? _openMarker(MapMarker marker) =>
      marker.ref == null || onNavigate == null
      ? null
      : () => onNavigate!(marker.ref!);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final aspect =
        (block.lonSpan *
                math.cos(block.centerLat * math.pi / 180) /
                block.latSpan)
            .clamp(0.65, 2.8)
            .toDouble();

    return LayoutBuilder(
      builder: (context, outer) {
        // Si el contenedor impone altura (p. ej. el detalle del atlas usa un
        // Expanded), el mapa encaja exactamente en ese espacio y no genera
        // scroll; en contextos de scroll libre la altura se calcula desde el
        // ancho.
        final bool fitHeight =
            outer.maxHeight.isFinite && outer.maxHeight > 220.0;
        return Container(
          key: const ValueKey('bible-map'),
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF1E2420) : const Color(0xFFFBF9F3),
            border: Border.all(color: kBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          height: fitHeight ? outer.maxHeight : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showHeader)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 6, 8),
                  child: Row(
                    children: [
                      Icon(Icons.public, size: 15, color: kTextSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          block.title.isEmpty ? l10n.mapTitle : block.title,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (expandable)
                        IconButton(
                          key: const ValueKey('map-expand'),
                          tooltip: l10n.mapFullView,
                          icon: Icon(
                            Icons.fullscreen,
                            size: 22,
                            color: kTextSecondary,
                          ),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _openFullMapDialog(context, block),
                        ),
                    ],
                  ),
                ),
              if (block.routes.length > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                  child: Row(
                    key: const ValueKey('map-route-legend'),
                    children: [
                      for (final withIndex in block.routes.indexed)
                        if (withIndex.$2.label.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: mapRouteColor(withIndex.$1),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  withIndex.$2.label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: kTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
              if (fitHeight)
                Expanded(
                  child: _mapContent(
                    context: context,
                    ref: ref,
                    l10n: l10n,
                    dark: dark,
                    aspect: aspect,
                  ),
                )
              else
                _mapContent(
                  context: context,
                  ref: ref,
                  l10n: l10n,
                  dark: dark,
                  aspect: aspect,
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (block.caption != null && block.caption!.isNotEmpty) ...[
                      Text(
                        block.caption!,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          color: kTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      l10n.mapAttribution,
                      style: TextStyle(
                        fontSize: 9.5,
                        height: 1.3,
                        color: kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Contenido del mapa (carga, error y lienzo), compartido por los dos
  /// modos de altura del build: encajado en la altura del panel o de
  /// altura libre calculada desde el ancho.
  Widget _mapContent({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
    required bool dark,
    required double aspect,
  }) {
    final asyncGeometry = ref.watch(mapGeometryProvider);
    return asyncGeometry.when(
      loading: () => SizedBox(
        height: 240,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
      error: (error, _) => SizedBox(
        height: 160,
        child: Center(
          child: Text(
            l10n.mapLoadError,
            style: TextStyle(fontSize: 12, color: kTextSecondary),
          ),
        ),
      ),
      data: (geometry) => LayoutBuilder(
        builder: (context, constraints) {
          // Tamaño único del lienzo: la proyección, la pintura y el viewport
          // del zoom usan exactamente el mismo rect, sin recortes a mitad de
          // mapa ni desbordes. Si el contenedor impone altura (el detalle
          // del atlas usa un Expanded), el mapa encaja ahí sin generar
          // scroll; si el eje vertical es libre, la altura se calcula desde
          // el ancho entre límites cómodos. El zoom y el pan los maneja
          // [_MapPane].
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 600.0;
          final height = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : (width / aspect).clamp(340.0, 560.0).toDouble();
          final size = Size(width, height);
          final projection = _MapProjection(block, size);
          final markers = <_MarkerPlacement>[];
          final occupied = <Rect>[];
          // Reservar TODAS las pastillas de paradas (incluidas las apiladas
          // cuando una ruta repite punto, p. ej. al volver a Jerusalén):
          // los chips colocados después no pueden tapar ningún número.
          for (final route in block.routes) {
            final seenPoints = <String, int>{};
            for (final stop in route.stops) {
              final point = projection.project(stop.lat, stop.lon);
              final key =
                  '${point.dx.toStringAsFixed(1)},'
                  '${point.dy.toStringAsFixed(1)}';
              final ordinal = seenPoints[key] ?? 0;
              seenPoints[key] = ordinal + 1;
              occupied.add(
                Rect.fromCircle(
                  center:
                      point +
                      const Offset(-9.5, -9.5) +
                      Offset(13.0 * ordinal, -13.0 * ordinal),
                  radius: 8,
                ),
              );
            }
          }
          final seenNames = <String>{};
          for (final marker in block.markers) {
            // Evitar duplicados: un mismo nombre no se dibuja dos veces.
            if (seenNames.contains(marker.name)) continue;
            seenNames.add(marker.name);
            final point = projection.project(marker.lat, marker.lon);
            if (point.dx < -20 ||
                point.dx > size.width + 20 ||
                point.dy < -20 ||
                point.dy > size.height + 20) {
              continue;
            }
            final labelRect = _placeMarkerLabel(
              point: point,
              labelSize: _measureMarkerLabel(context, marker.name),
              bounds: size,
              occupied: occupied,
            );
            occupied.add(labelRect);
            // Reservar también el punto y el badge del marcador: las
            // etiquetas colocadas después no deben tapar los números ni
            // la pastilla del nombre.
            occupied.add(Rect.fromCircle(center: point, radius: 9));
            occupied.add(
              Rect.fromCircle(
                center: point + const Offset(-9.5, -9.5),
                radius: 8,
              ),
            );
            markers.add(
              _MarkerPlacement(
                marker: marker,
                point: point,
                labelRect: labelRect,
              ),
            );
          }
          // Rótulos de ríos con nombre (Jordán, Éufrates…): rellenan huecos
          // del atlas cuando lo hacen los nombres de lugares. Un rótulo por
          // cauce, y solo si queda sitio libre tras los chips y sus pastillas.
          final riverLabels = <_RiverLabelPlacement>[];
          final drawnRivers = <String>{};
          for (final entry in geometry.riverLabelAnchors.entries) {
            if (!drawnRivers.add(entry.key)) continue;
            final point = projection.project(entry.value.dy, entry.value.dx);
            if (point.dx < 20 ||
                point.dx > size.width - 20 ||
                point.dy < 12 ||
                point.dy > size.height - 12) {
              continue;
            }
            final painter = TextPainter(
              text: TextSpan(text: entry.key, style: _riverLabelStyle),
              textDirection: TextDirection.ltr,
            )..layout(maxWidth: 180);
            final rect = Rect.fromCenter(
              center: point,
              width: painter.width + 8,
              height: painter.height + 6,
            );
            painter.dispose();
            if (occupied.any((other) => other.overlaps(rect))) continue;
            occupied.add(rect);
            riverLabels.add(
              _RiverLabelPlacement(name: entry.key, point: point),
            );
          }
          final map = SizedBox(
            width: size.width,
            height: size.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MapPainter(
                      geometry: geometry,
                      block: block,
                      dark: dark,
                    ),
                  ),
                ),
                if (riverLabels.isNotEmpty)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _RiverLabelPainter(
                          labels: riverLabels,
                          textScaler: MediaQuery.textScalerOf(context),
                          dark: dark,
                        ),
                      ),
                    ),
                  ),
                if (block.routes.isNotEmpty)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        key: const ValueKey('map-route-layer'),
                        painter: _RoutePainter(
                          routes: block.routes,
                          projection: projection,
                          dark: dark,
                        ),
                      ),
                    ),
                  ),
                if (markers.isNotEmpty)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _MarkerLinePainter(
                          lines: [
                            for (final entry in markers)
                              _MarkerLine(
                                start: entry.point,
                                end: _nearestPoint(
                                  entry.labelRect,
                                  entry.point,
                                ),
                              ),
                          ],
                          color: Theme.of(context).colorScheme.primary
                              .withValues(alpha: 0.32),
                        ),
                      ),
                    ),
                  ),
                for (final entry in markers)
                  Positioned(
                    left: entry.point.dx - 4.5,
                    top: entry.point.dy - 4.5,
                    child: _MarkerDot(
                      key: ValueKey('map-marker-dot-${entry.marker.name}'),
                      marker: entry.marker,
                      dark: dark,
                      onTap: _openMarker(entry.marker),
                    ),
                  ),
                for (final entry in markers)
                  Positioned(
                    left: entry.labelRect.left,
                    top: entry.labelRect.top,
                    width: entry.labelRect.width,
                    height: entry.labelRect.height,
                    child: _MarkerChip(
                      key: ValueKey('map-marker-${entry.marker.name}'),
                      marker: entry.marker,
                      dark: dark,
                      onTap: _openMarker(entry.marker),
                    ),
                  ),
              ],
            ),
          );
          return Semantics(
            image: true,
            label: [
              block.title.isEmpty ? l10n.mapTitle : block.title,
              ...block.markers.map((marker) => marker.name),
            ].join('. '),
            child: _MapPane(size: size, child: map),
          );
        },
      ),
    );
  }
}

const _markerLabelStyle = TextStyle(
  fontSize: 9.5,
  height: 1.1,
  fontWeight: FontWeight.w600,
);

/// Rótulo de río: itálica pequeña tipo carta antigua, sin chip de fondo.
const _riverLabelStyle = TextStyle(
  fontSize: 8.5,
  height: 1.25,
  fontStyle: FontStyle.italic,
  fontWeight: FontWeight.w500,
  letterSpacing: 0.2,
);

/// Nombre de río dibujado en el lienzo con su punto ya proyectado.
class _RiverLabelPlacement {
  const _RiverLabelPlacement({required this.name, required this.point});

  final String name;
  final Offset point;
}

/// Pinta los rótulos de ríos debajo de las rutas, así las líneas de viaje
/// pasan por encima pero el texto queda legible al saltarse los huecos.
class _RiverLabelPainter extends CustomPainter {
  const _RiverLabelPainter({
    required this.labels,
    required this.textScaler,
    required this.dark,
  });

  final List<_RiverLabelPlacement> labels;
  final TextScaler textScaler;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    if (labels.isEmpty) return;
    final ink = dark
        ? const Color(0xFF9EC1D0).withValues(alpha: 0.92)
        : const Color(0xFF47708C).withValues(alpha: 0.95);
    final style = _riverLabelStyle.copyWith(color: ink);
    for (final label in labels) {
      final painter = TextPainter(
        text: TextSpan(text: label.name, style: style),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
      )..layout(maxWidth: 180);
      painter.paint(
        canvas,
        label.point - Offset(painter.width / 2, painter.height / 2),
      );
      painter.dispose();
    }
  }

  @override
  bool shouldRepaint(covariant _RiverLabelPainter oldDelegate) =>
      oldDelegate.labels != labels ||
      oldDelegate.dark != dark ||
      oldDelegate.textScaler != textScaler;
}

/// Paleta para las rutas del mapa (viajes, itinerarios): tonos sobrios que
/// se distinguen tanto en claro como en oscuro, con halo para poder seguir
/// la línea sobre tierra y mar.
const List<Color> mapRouteColors = [
  Color(0xFF2E6E8E), // azul acero
  Color(0xFF8E4468), // vino
  Color(0xFF3E7D53), // verde bosque
  Color(0xFF7A5B22), // ocre
  Color(0xFF5B51A5), // índigo
];

Color mapRouteColor(int index) => mapRouteColors[index % mapRouteColors.length];

/// Chevron sencillo de la flecha de dirección de un tramo `from → to`.
///
/// Se ancla a lo largo del tramo según [anchor] (0.5 = punto medio):
/// la punta señala la dirección del avance y las dos alas quedan detrás,
/// apartadas perpendicularmente. Devuelve [tip, ala1, ala2] (path de dos
/// segmentos, sin relleno) o null si el tramo es demasiado corto.
@visibleForTesting
List<Offset>? routeArrowChevron(
  Offset from,
  Offset to, {
  double anchor = 0.5,
  double leg = 5,
  double halfHeight = 4,
  double minLeg = 18,
}) {
  final delta = to - from;
  final distance = delta.distance;
  if (distance < minLeg) return null;
  final unit = delta / distance;
  // Anclada al medio del tramo para que no la tapen el punto de destino ni
  // la parada numerada; en tramos largos [_RoutePainter] pinta varias.
  final tip = from + delta * anchor;
  final perpendicular = Offset(-unit.dy, unit.dx);
  final behind = tip - unit * leg;
  return [
    tip,
    behind + perpendicular * halfHeight,
    behind - perpendicular * halfHeight,
  ];
}

/// Clave estable de un tramo proyectado (tolerancia de medio píxel) para
/// detectar ida y vuelta por el mismo camino.
String _segmentKey(Offset a, Offset b) =>
    '${((a.dx * 2).round())},${(a.dy * 2).round()}-'
    '${((b.dx * 2).round())},${(b.dy * 2).round()}';

Size _measureMarkerLabel(BuildContext context, String name) {
  final painter = TextPainter(
    text: TextSpan(text: name, style: _markerLabelStyle),
    maxLines: 1,
    ellipsis: '…',
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout(maxWidth: 122);
  return Size(
    math.max(30.0, painter.width.ceilToDouble() + 12),
    math.max(13.0, painter.height.ceilToDouble() + 2),
  );
}

Rect _placeMarkerLabel({
  required Offset point,
  required Size labelSize,
  required Size bounds,
  required List<Rect> occupied,
}) {
  final width = labelSize.width;
  final height = labelSize.height;
  // Elección de la posición del chip, en orden de preferencia:
  // 1. posición que no choca con nada; 2. posición que solo roza el punto
  // del propio marcador (la línea de guía igual lo une); 3. la menos mala.
  // El número (badge) propio nunca debe quedar tapado ni por el propio
  // chip ni por otro, y los chips no deben taparse entre sí (Seleucia,
  // Perge y Atalía en el primer viaje de Pablo).
  final ownBadgeRect = Rect.fromCircle(
    center: point + const Offset(-9.5, -9.5),
    radius: 8,
  );
  final ownDotRect = Rect.fromCircle(center: point, radius: 7);
  final candidates = [
    Offset(-width / 2, 7), // debajo
    Offset(-width / 2, -height - 7), // encima
    Offset(7, -height / 2), // derecha
    Offset(-width - 7, -height / 2), // izquierda
    Offset(5, 7), // debajo, pegado a la derecha
    Offset(-width - 5, 7), // debajo, pegado a la izquierda
    Offset(5, -height - 6), // arriba, pegado a la derecha
    Offset(-width - 5, -height - 6), // arriba, pegado a la izquierda
    Offset(-width / 2, 22), // más abajo
    Offset(-width / 2, -height - 22), // más arriba
    Offset(20, -height / 2), // más a la derecha
    Offset(-width - 20, -height / 2), // más a la izquierda
  ];
  Rect? acceptable;
  Rect? anyRect;
  for (final offset in candidates) {
    final rect = Rect.fromLTWH(
      point.dx + offset.dx,
      point.dy + offset.dy,
      width,
      height,
    );
    if (rect.left < 2 ||
        rect.top < 2 ||
        rect.right > bounds.width - 2 ||
        rect.bottom > bounds.height - 2) {
      continue;
    }
    anyRect ??= rect;
    // Nada de tapar otros chips/dots/badges ni el número propio.
    if (occupied.any((other) => other.inflate(1.5).overlaps(rect))) {
      continue;
    }
    if (ownBadgeRect.inflate(1.5).overlaps(rect)) {
      continue;
    }
    if (ownDotRect.inflate(1.5).overlaps(rect)) {
      // Solo roza su propio punto: respaldo negociable.
      acceptable ??= rect;
      continue;
    }
    return rect;
  }
  final Rect chosen =
      acceptable ??
      anyRect ??
      (() {
        final left = (point.dx - width / 2)
            .clamp(2.0, math.max(2.0, bounds.width - width - 2))
            .toDouble();
        final top = (point.dy - height / 2)
            .clamp(2.0, math.max(2.0, bounds.height - height - 2))
            .toDouble();
        return Rect.fromLTWH(left, top, width, height);
      })();
  return chosen;
}

Offset _nearestPoint(Rect rect, Offset point) => Offset(
  point.dx < rect.left
      ? rect.left
      : point.dx > rect.right
      ? rect.right
      : point.dx,
  point.dy < rect.top
      ? rect.top
      : point.dy > rect.bottom
      ? rect.bottom
      : point.dy,
);

/// Pintor de rutas: polilínea con halo, flechas de dirección y numeración
/// de paradas. Va por debajo de los marcadores y sus etiquetas; los puntos
/// interactivos los siguen dibujando las capas de arriba.
class _RoutePainter extends CustomPainter {
  const _RoutePainter({
    required this.routes,
    required this.projection,
    required this.dark,
  });

  final List<MapRoute> routes;
  final _MapProjection projection;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    for (final withIndex in routes.indexed) {
      final route = withIndex.$2;
      final stops = route.stops;
      if (stops.length < 2) continue;
      final color = mapRouteColor(withIndex.$1);
      final points = [
        for (final stop in stops) projection.project(stop.lat, stop.lon),
      ];

      // Tramos de regreso que reutilizan el camino de ida: se apartan unos
      // píxeles perpendicularmente para que ida y vuelta no se superpongan.
      final shifted = List.of(points);
      // Qué tramos reutilizan camino ya pintado (sentido contrario): sus
      // chevrons se omiten para no apiñar dos flechas sobre la misma senda
      // (el sentido de la vuelta lo cuentan los números de parada).
      final isReturnLeg = List<bool>.filled(points.length - 1, false);
      final used = <String>{};
      var i = 0;
      while (i + 1 < points.length) {
        if (!used.contains(_segmentKey(points[i + 1], points[i]))) {
          used.add(_segmentKey(points[i], points[i + 1]));
          i++;
          continue;
        }
        // Cadena de regreso: tramos consecutivos que reutilizan tramos ya
        // dibujados; se aparta completa (rígida) para conservar continuidad.
        var end = i;
        while (end + 1 < points.length &&
            used.contains(_segmentKey(points[end + 1], points[end]))) {
          used.add(_segmentKey(points[end], points[end + 1]));
          end++;
        }
        for (var k = i; k < end; k++) {
          isReturnLeg[k] = true;
        }
        final leg = points[i + 1] - points[i];
        if (leg.distance > 0.5) {
          final perp = Offset(-leg.dy, leg.dx) * (5.0 / leg.distance);
          for (var k = i; k <= end + 1 && k < shifted.length; k++) {
            shifted[k] = shifted[k] + perp;
          }
        }
        i = end + 1;
      }

      // Línea de puntitos con chevrons discretos: menos peso visual que la
      // cinta continua con flechas grandes (antes se amontonaba); la
      // dirección la refuerzan los números de parada.
      _paintDottedLine(canvas, shifted, color.withValues(alpha: 0.85));
      _paintArrows(canvas, shifted, color, skip: isReturnLeg);
      _paintStopBadges(canvas, points, color, size);
    }
    canvas.restore();
  }

  /// Sendita de puntitos: dibuja círculos pequeños a intervalos fijos a lo
  /// largo de la polilínea (Flutter no expone `PathEffect`, se reparte a
  /// mano por longitud de arco, respetando las esquinas del trazado).
  void _paintDottedLine(Canvas canvas, List<Offset> points, Color color) {
    const dotRadius = 1.3;
    const spacing = 6.4;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    var emitted = 0.0; // longitud de arco consumida hasta aquí
    var dotAt = 0.0; // longitud de arco donde cae el próximo puntito
    for (var i = 0; i < points.length - 1; i++) {
      final from = points[i];
      final to = points[i + 1];
      final leg = (to - from).distance;
      if (leg < 0.001) continue;
      while (dotAt <= emitted + leg) {
        if (dotAt >= emitted) {
          final t = dotAt - emitted;
          final point = Offset.lerp(from, to, t / leg)!;
          canvas.drawCircle(point, dotRadius, paint);
        }
        dotAt += spacing;
      }
      emitted += leg;
    }
  }

  void _paintArrows(
    Canvas canvas,
    List<Offset> points,
    Color color, {
    List<bool> skip = const <bool>[],
  }) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      // Punta redondeada: el miter en el vértice del chevron clava una
      // púa del doble del grosor y arruina la forma sencilla.
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.6;
    for (var i = 0; i < points.length - 1; i++) {
      if (i < skip.length && skip[i]) continue;
      final from = points[i];
      final to = points[i + 1];
      final distance = (to - from).distance;
      // Tramos largos llevan dos flechas para que la dirección siga
      // leyéndose más allá del punto medio; tramos normales, una al medio.
      final anchors = distance > 240 ? const [0.33, 0.72] : const [0.5];
      for (final t in anchors) {
        final chevron = routeArrowChevron(from, to, anchor: t);
        if (chevron == null) continue;
        final path = Path()
          ..moveTo(chevron[1].dx, chevron[1].dy)
          ..lineTo(chevron[0].dx, chevron[0].dy)
          ..lineTo(chevron[2].dx, chevron[2].dy);
        canvas.drawPath(path, paint);
      }
    }
  }

  void _paintStopBadges(
    Canvas canvas,
    List<Offset> points,
    Color color,
    Size bounds,
  ) {
    final badgePaint = Paint();
    final borderPaint = Paint()
      ..color = dark ? const Color(0xFF101410) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final textPaint = TextPainter(textDirection: TextDirection.ltr);
    // ¿Qué número corresponde a cada parada cuando comparten punto? Una
    // revisita (p. ej. volver a Jerusalén) ancla su badge al mismo punto,
    // así que se apilan en diagonal para que todos los números queden
    // legibles: antes el dedup los ocultaba y en pantalla faltaba un número.
    final ordinals = <int>[];
    final seenPoints = <String, int>{};
    for (var i = 0; i < points.length; i++) {
      final key =
          '${points[i].dx.toStringAsFixed(1)},'
          '${points[i].dy.toStringAsFixed(1)}';
      final ordinal = seenPoints[key] ?? 0;
      seenPoints[key] = ordinal + 1;
      ordinals.add(ordinal);
    }
    final drawn = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      var extra = 0; // empujones diagonales cuando el punto queda tomado
      final delta = Offset(13.0 * ordinals[i], -13.0 * ordinals[i]);
      var badgeCenter = points[i] + const Offset(-9.5, -9.5) + delta;
      // Además del apilado por revisita, dos puntos distintos muy cercanos
      // en pantalla (p. ej. Neapolis y Filipos) pueden pisar sus badges:
      // se empuja el nuevo en la misma diagonal hasta quedar legible.
      while (extra < 8 &&
          drawn.any((other) => (other - badgeCenter).distance < 13.5)) {
        extra++;
        badgeCenter =
            points[i] +
            const Offset(-9.5, -9.5) +
            delta +
            Offset(13.0 * extra, -13.0 * extra);
      }
      if (extra >= 8) continue;
      if (badgeCenter.dx < 6 ||
          badgeCenter.dy < 6 ||
          badgeCenter.dx > bounds.width - 6 ||
          badgeCenter.dy > bounds.height - 6) {
        continue;
      }
      drawn.add(badgeCenter);
      badgePaint.color = color;
      canvas.drawCircle(badgeCenter, 6, badgePaint);
      canvas.drawCircle(badgeCenter, 6, borderPaint);
      textPaint.text = TextSpan(
        text: '${i + 1}',
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          height: 1,
          letterSpacing: 0,
        ),
      );
      textPaint.layout();
      textPaint.paint(
        canvas,
        badgeCenter - Offset(textPaint.width / 2, textPaint.height / 2),
      );
    }
    textPaint.dispose();
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.routes != routes || oldDelegate.dark != dark;
}

class _MarkerPlacement {
  const _MarkerPlacement({
    required this.marker,
    required this.point,
    required this.labelRect,
  });

  final MapMarker marker;
  final Offset point;
  final Rect labelRect;
}

class _MarkerLine {
  const _MarkerLine({required this.start, required this.end});

  final Offset start;
  final Offset end;
}

class _MarkerLinePainter extends CustomPainter {
  const _MarkerLinePainter({required this.lines, required this.color});

  final List<_MarkerLine> lines;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;
    for (final line in lines) {
      canvas.drawLine(line.start, line.end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MarkerLinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.lines != lines;
}

class _MarkerDot extends StatelessWidget {
  const _MarkerDot({
    super.key,
    required this.marker,
    required this.dark,
    this.onTap,
  });

  final MapMarker marker;
  final bool dark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: marker.name,
      child: MouseRegion(
        cursor: onTap == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: Semantics(
          button: onTap != null,
          label: marker.name,
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: dark ? const Color(0xFF101410) : Colors.white,
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x33000000), blurRadius: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MarkerChip extends StatelessWidget {
  const _MarkerChip({
    super.key,
    required this.marker,
    required this.dark,
    this.onTap,
  });

  final MapMarker marker;
  final bool dark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final reference = marker.ref == null
        ? null
        : displayFromCanonical(marker.ref!, lang: context.l10nLang);
    final label = reference == null
        ? marker.name
        : '${marker.name} · $reference';
    return Tooltip(
      message: label,
      child: MouseRegion(
        cursor: onTap == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: dark ? const Color(0xDD202620) : const Color(0xEEFFFFFF),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: kBorder.withValues(alpha: 0.7)),
            ),
            child: Text(
              marker.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: _markerLabelStyle.copyWith(
                color: dark ? Colors.white : const Color(0xFF2A2A2A),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapProjection {
  const _MapProjection(this.block, this.size);

  final MapBlock block;
  final Size size;

  Offset project(double lat, double lon) {
    final left = block.centerLon - block.lonSpan / 2;
    final top = block.centerLat + block.latSpan / 2;
    return Offset(
      ((lon - left) / block.lonSpan) * size.width,
      ((top - lat) / block.latSpan) * size.height,
    );
  }
}

class _MapPainter extends CustomPainter {
  const _MapPainter({
    required this.geometry,
    required this.block,
    required this.dark,
  });

  final MapGeometry geometry;
  final MapBlock block;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final projection = _MapProjection(block, size);
    final water = dark ? const Color(0xFF16262D) : const Color(0xFFE7F0F3);
    final land = dark ? const Color(0xFF2B302B) : const Color(0xFFF4EEDF);
    final coast = dark ? const Color(0xFF5B665A) : const Color(0xFFCBBFA5);
    final lake = dark ? const Color(0xFF1A3038) : const Color(0xFFD4E7EB);

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..color = water);
    _paintGrid(canvas, size, projection);
    _paintRings(canvas, geometry.land, projection, land, coast);
    // División política discreta (punteados cortos) y cuerpos de agua lineales
    // de Natural Earth: dan cuerpo al atlas y dejarn repartir rótulos.
    final border = dark ? const Color(0xFF9AA3AD) : const Color(0xFF8A93A0);
    _paintChainsDashed(
      canvas,
      geometry.boundaries,
      projection,
      Paint()
        ..color = border.withValues(alpha: dark ? 0.28 : 0.38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
    final river = dark ? const Color(0xFF3E6E82) : const Color(0xFF7DA7BD);
    _paintChains(
      canvas,
      geometry.rivers,
      projection,
      Paint()
        ..color = river.withValues(alpha: dark ? 0.95 : 1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    _paintRings(canvas, geometry.lakes, projection, lake, coast);
    canvas.restore();
  }

  void _paintChains(
    Canvas canvas,
    List<List<Offset>> chains,
    _MapProjection projection,
    Paint paint,
  ) {
    for (final chain in chains) {
      final path = Path();
      var first = true;
      for (final point in chain) {
        final projected = projection.project(point.dy, point.dx);
        if (first) {
          path.moveTo(projected.dx, projected.dy);
          first = false;
        } else {
          path.lineTo(projected.dx, projected.dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  /// Trazo discontinuo a mano: flutter no expone un PathEffect y así el
  /// guión queda estable en todas las plataformas. Secuencia 2.8/2.4.
  void _paintChainsDashed(
    Canvas canvas,
    List<List<Offset>> chains,
    _MapProjection projection,
    Paint paint,
  ) {
    const dashOn = 2.8;
    const dashOff = 2.4;
    for (final chain in chains) {
      if (chain.length < 2) continue;
      var prev = projection.project(chain.first.dy, chain.first.dx);
      var on = true;
      var left = dashOn;
      for (var i = 1; i < chain.length; i++) {
        var cur = projection.project(chain[i].dy, chain[i].dx);
        while (true) {
          final span = (cur - prev).distance;
          if (span < left) {
            if (on) canvas.drawLine(prev, cur, paint);
            left -= span;
            prev = cur;
            break;
          }
          final gap = Offset.lerp(prev, cur, left / span)!;
          if (on) canvas.drawLine(prev, gap, paint);
          prev = gap;
          on = !on;
          left = on ? dashOn : dashOff;
        }
      }
    }
  }

  void _paintRings(
    Canvas canvas,
    List<List<Offset>> rings,
    _MapProjection projection,
    Color fillColor,
    Color stroke,
  ) {
    final fillPaint = Paint()..color = fillColor;
    final strokePaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    for (final ring in rings) {
      final path = Path();
      var first = true;
      for (final point in ring) {
        final projected = projection.project(point.dy, point.dx);
        if (first) {
          path.moveTo(projected.dx, projected.dy);
          first = false;
        } else {
          path.lineTo(projected.dx, projected.dy);
        }
      }
      path.close();
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, strokePaint);
    }
  }

  void _paintGrid(Canvas canvas, Size size, _MapProjection projection) {
    final step = block.latSpan <= 2
        ? 0.5
        : block.latSpan <= 6
        ? 1.0
        : 2.0;
    final paint = Paint()
      ..color = dark ? const Color(0x16FFFFFF) : const Color(0x14000000)
      ..strokeWidth = 0.5;
    final minLat = block.centerLat - block.latSpan / 2;
    final maxLat = block.centerLat + block.latSpan / 2;
    final minLon = block.centerLon - block.lonSpan / 2;
    final maxLon = block.centerLon + block.lonSpan / 2;

    for (var lat = (minLat / step).ceil() * step; lat <= maxLat; lat += step) {
      final y = projection.project(lat, minLon).dy;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (var lon = (minLon / step).ceil() * step; lon <= maxLon; lon += step) {
      final x = projection.project(minLat, lon).dx;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) =>
      oldDelegate.geometry != geometry ||
      oldDelegate.block != block ||
      oldDelegate.dark != dark;
}

/// Visor interactivo del mapa: la rueda encara y aleja anclando donde está el
/// cursor (y la señal queda para el mapa, no para el desplazamiento de la
/// página), y expone botones de zoom y de encuadre completo.
class _MapPane extends StatefulWidget {
  const _MapPane({required this.size, required this.child});

  /// Tamaño del viewport del mapa; coincide con el lienzo pintado, así el
  /// zoom 1.0 muestra siempre el mapa completo sin recortes.
  final Size size;

  final Widget child;

  @override
  State<_MapPane> createState() => _MapPaneState();
}

class _MapPaneState extends State<_MapPane> {
  static const double _minScale = 1.0;
  static const double _maxScale = 4.0;
  static const double _zoomInFactor = 1.35;
  static const double _zoomOutFactor = 0.74;

  final TransformationController _transform = TransformationController();

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    // El mapa decide qué hacer con la rueda (como un visor de mapas): la
    // señal se registra en el resolver y no sigue hacia los scrollables de
    // la página.
    GestureBinding.instance.pointerSignalResolver.register(event, (resolved) {
      if (resolved is! PointerScrollEvent) return;
      _zoomAt(
        resolved.scrollDelta.dy > 0 ? _zoomOutFactor : _zoomInFactor,
        resolved.localPosition,
      );
    });
  }

  void _zoomAt(double factor, Offset anchor) {
    final oldValue = _transform.value;
    final oldScale = oldValue.getMaxScaleOnAxis();
    final nextScale = (oldScale * factor)
        .clamp(_minScale, _maxScale)
        .toDouble();
    if ((nextScale - oldScale).abs() < 0.0005) return;
    // El punto del contenido que está bajo el ancla permanece en pantalla:
    // el zoom se hace alrededor del cursor (o del centro con los botones).
    final contentPoint =
        (anchor - Offset(oldValue.storage[12], oldValue.storage[13])) /
        oldScale;
    final translation = anchor - contentPoint * nextScale;
    _transform.value = Matrix4(
      nextScale,
      0,
      0,
      0,
      0,
      nextScale,
      0,
      0,
      0,
      0,
      nextScale,
      0,
      translation.dx,
      translation.dy,
      0,
      1,
    );
  }

  void _zoomStep(double factor) {
    final viewport = context.size;
    _zoomAt(
      factor,
      viewport == null
          ? Offset(widget.size.width / 2, widget.size.height / 2)
          : Offset(viewport.width / 2, viewport.height / 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final controls = <(IconData, String, VoidCallback)>[
      (Icons.add, l10n.mapZoomIn, () => _zoomStep(_zoomInFactor)),
      (Icons.remove, l10n.mapZoomOut, () => _zoomStep(_zoomOutFactor)),
      (
        Icons.center_focus_weak,
        l10n.mapZoomReset,
        () => _transform.value = Matrix4.identity(),
      ),
    ];
    return Stack(
      children: [
        SizedBox(
          width: widget.size.width,
          height: widget.size.height,
          child: Listener(
            onPointerSignal: _onPointerSignal,
            child: InteractiveViewer(
              transformationController: _transform,
              minScale: _minScale,
              maxScale: _maxScale,
              panEnabled: true,
              scaleEnabled: true,
              child: widget.child,
            ),
          ),
        ),
        // Controles de zoom abajo a la derecha: arriba está la fila del
        // título (y en el modal la X de cierre), así no chocan con nada.
        Positioned(
          right: 6,
          bottom: 10,
          child: Material(
            color: dark ? const Color(0xDD202620) : const Color(0xEEFFFFFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
              side: BorderSide(color: kBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: IconTheme(
              data: IconThemeData(
                size: 15,
                color: dark ? const Color(0xFFD9DED9) : const Color(0xFF2A2A2A),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (icon, tooltip, onPressed) in controls)
                    Tooltip(
                      message: tooltip,
                      child: IconButton(
                        tooltip: tooltip,
                        icon: Icon(icon),
                        iconSize: 15,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 30,
                          height: 30,
                        ),
                        onPressed: onPressed,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
