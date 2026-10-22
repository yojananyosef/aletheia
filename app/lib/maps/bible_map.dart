/// Mapas bíblicos offline.
///
/// La geometría de costas y lagos viene de Natural Earth (dominio público);
/// las coordenadas de los lugares, de OpenBible.info (CC BY 4.0). El widget
/// dibuja un encuadre esquemático con `CustomPainter`, sin teselas ni red.
library;

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/document_models.dart';
import '../core/localization.dart';
import '../core/theme.dart';
import '../references/reference_parser.dart';

class MapGeometry {
  const MapGeometry({required this.land, required this.lakes});

  final List<List<Offset>> land;
  final List<List<Offset>> lakes;
}

final mapGeometryProvider = FutureProvider<MapGeometry>((ref) async {
  final loaded = await Future.wait([
    rootBundle.loadString('assets/maps/ne_110m_land.geojson'),
    rootBundle.loadString('assets/maps/ne_110m_lakes.geojson'),
  ]);
  return MapGeometry(land: _polygons(loaded[0]), lakes: _polygons(loaded[1]));
});

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

/// Mapa de una sección con marcadores interactivos.
///
/// Si un marcador trae `ref`, al pulsarlo se llama a [onNavigate] con la
/// referencia canónica; así el mapa funciona como un índice del pasaje.
class BibleMap extends ConsumerWidget {
  const BibleMap({super.key, required this.block, this.onNavigate});

  final MapBlock block;
  final ValueChanged<String>? onNavigate;

  VoidCallback? _openMarker(MapMarker marker) =>
      marker.ref == null || onNavigate == null
      ? null
      : () => onNavigate!(marker.ref!);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final asyncGeometry = ref.watch(mapGeometryProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final aspect =
        (block.lonSpan *
                math.cos(block.centerLat * math.pi / 180) /
                block.latSpan)
            .clamp(0.65, 2.8);

    return Container(
      key: const ValueKey('bible-map'),
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E2420) : const Color(0xFFFBF9F3),
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
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
          AspectRatio(
            aspectRatio: aspect,
            child: asyncGeometry.when(
              loading: () => Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              error: (error, _) => Center(
                child: Text(
                  l10n.mapLoadError,
                  style: TextStyle(fontSize: 12, color: kTextSecondary),
                ),
              ),
              data: (geometry) => LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  final projection = _MapProjection(block, size);
                  final markers = <_MarkerPlacement>[];
                  final occupied = <Rect>[];
                  for (final marker in block.markers) {
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
                    markers.add(
                      _MarkerPlacement(
                        marker: marker,
                        point: point,
                        labelRect: labelRect,
                      ),
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
                              key: ValueKey(
                                'map-marker-dot-${entry.marker.name}',
                              ),
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
                    child: ClipRect(
                      child: InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        panEnabled: true,
                        scaleEnabled: true,
                        child: map,
                      ),
                    ),
                  );
                },
              ),
            ),
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
  }
}

const _markerLabelStyle = TextStyle(
  fontSize: 9.5,
  height: 1.1,
  fontWeight: FontWeight.w600,
);

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

Color mapRouteColor(int index) =>
    mapRouteColors[index % mapRouteColors.length];

/// Triángulo de la flecha de dirección de un tramo `from → to`.
///
/// La punta se coloca [inset] píxeles antes de `to`, sobre la línea; los
/// otros dos puntos se apartan perpendicular a la dirección. Devuelve null
/// si el tramo es demasiado corto para dibujar una flecha legible.
@visibleForTesting
List<Offset>? routeArrowTriangle(
  Offset from,
  Offset to, {
  double inset = 8,
  double halfHeight = 3.2,
  double length = 8,
  double minLeg = 17,
}) {
  final delta = to - from;
  final distance = delta.distance;
  if (distance < minLeg) return null;
  final unit = delta / distance;
  final tip = to - unit * inset;
  final perpendicular = Offset(-unit.dy, unit.dx);
  return [
    tip,
    tip + unit * length + perpendicular * halfHeight,
    tip + unit * length - perpendicular * halfHeight,
  ];
}

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
  final candidates = [
    Offset(-width / 2, 7), // debajo
    Offset(-width / 2, -height - 7), // encima
    Offset(7, -height / 2), // derecha
    Offset(-width - 7, -height / 2), // izquierda
    Offset(5, 7),
    Offset(-width - 5, 7),
    Offset(5, -height - 6),
    Offset(-width - 5, -height - 6),
    Offset(-width / 2, 22),
    Offset(-width / 2, -height - 22),
    Offset(20, -height / 2),
    Offset(-width - 20, -height / 2),
  ];
  Rect? fallback;
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
    fallback ??= rect;
    if (!occupied.any((other) => other.inflate(1.5).overlaps(rect))) {
      return rect;
    }
  }
  if (fallback != null) return fallback;
  final left = (point.dx - width / 2)
      .clamp(2.0, math.max(2.0, bounds.width - width - 2))
      .toDouble();
  final top = (point.dy - height / 2)
      .clamp(2.0, math.max(2.0, bounds.height - height - 2))
      .toDouble();
  return Rect.fromLTWH(left, top, width, height);
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

      // Halo bajo la línea para separarla de la geografía.
      _paintPolyline(canvas, points, dark
          ? Colors.black.withValues(alpha: 0.55)
          : Colors.white.withValues(alpha: 0.85), 3.6);
      _paintPolyline(canvas, points, color.withValues(alpha: 0.88), 2.0);
      _paintArrows(canvas, points, color);
      _paintStopBadges(canvas, points, color, size);
    }
    canvas.restore();
  }

  void _paintPolyline(Canvas canvas, List<Offset> points, Color color, double width) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = width;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  void _paintArrows(Canvas canvas, List<Offset> points, Color color) {
    final paint = Paint()..color = color.withValues(alpha: 0.92);
    for (var i = 0; i < points.length - 1; i++) {
      final triangle = routeArrowTriangle(points[i], points[i + 1]);
      if (triangle == null) continue;
      final path = Path()
        ..moveTo(triangle[0].dx, triangle[0].dy)
        ..lineTo(triangle[1].dx, triangle[1].dy)
        ..lineTo(triangle[2].dx, triangle[2].dy)
        ..close();
      canvas.drawPath(path, paint);
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
    final textPaint = TextPainter(
      textDirection: TextDirection.ltr,
    );
    final drawn = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final badgeCenter = points[i] + const Offset(-9.5, -9.5);
      if (badgeCenter.dx < 6 ||
          badgeCenter.dy < 6 ||
          badgeCenter.dx > bounds.width - 6 ||
          badgeCenter.dy > bounds.height - 6) {
        continue;
      }
      if (drawn.any(
        (other) => (other - badgeCenter).distance < 5,
      )) {
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
    _paintRings(canvas, geometry.lakes, projection, lake, coast);
    canvas.restore();
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
