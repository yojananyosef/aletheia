/// Viajes de Pablo en el Atlas: datos empaquetados, modelos, flechas y vista.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aletheia/catalog/document_models.dart';
import 'package:aletheia/l10n/app_localizations.dart';
import 'package:aletheia/maps/bible_map.dart';
import 'package:aletheia/maps/visual_sections.dart';
import 'package:aletheia/references/reference_parser.dart';

/// Cargador directo del manifiesto empaquetado (el cwd de los tests es `app/`).
List<VisualJourney> _repoJourneys() {
  final json = jsonDecode(
    File('assets/catalog/map_sections.json').readAsStringSync(),
  );
  return [
    for (final journey in (json['journeys'] as List? ?? const []))
      if (journey is Map<String, dynamic>) VisualJourney.fromJson(journey),
  ];
}

void main() {
  group('datos empaquetados de viajes', () {
    test('los viajes existen, únicos y ordenados', () {
      final journeys = _repoJourneys();
      expect(journeys, isNotEmpty);
      final ids = journeys.map((journey) => journey.id).toList();
      expect(ids.length, ids.toSet().length);
      final orders = journeys.map((journey) => journey.order);
      expect(orders, orders.toList()..sort());
    });

    test('cada viaje tiene paradas con nombre y coordenadas válidas', () {
      for (final journey in _repoJourneys()) {
        expect(journey.stops.length, greaterThanOrEqualTo(2));
        expect(journey.title, isNotEmpty);
        for (final stop in journey.stops) {
          expect(stop.name, isNotEmpty);
          expect(stop.lat, inInclusiveRange(25, 50), reason: stop.name);
          expect(stop.lon, inInclusiveRange(0, 40), reason: stop.name);
        }
      }
    });

    test('los destinos de cada parada son referencias canónicas de Hechos', () {
      for (final journey in _repoJourneys()) {
        for (final stop in journey.stops) {
          expect(stop.ref, isNotNull, reason: stop.name);
          final match = RegExp(r'^([1-3]?[A-Z]{2,3})\.(\d+)(?:\.(\d+))?$')
              .firstMatch(stop.ref!);
          expect(match, isNotNull, reason: stop.ref);
          expect(bookCodeForInput(match!.group(1)!), isNotNull);
        }
        for (final ref in journey.refs) {
          expect(RegExp(r'^ACT\.\d+\.\d+$').hasMatch(ref), isTrue, reason: ref);
        }
        expect(journey.toMapBlock(), isNotNull);
      }
    });
  });

  group('VisualJourney.toMapBlock', () {
    test('encuadre según la caja de paradas y una sola ruta', () {
      final journeys = _repoJourneys();
      final second = journeys.firstWhere((journey) => journey.id == 'pablo-02');
      final block = second.toMapBlock()!;
      final lats = second.stops.map((stop) => stop.lat);
      final lons = second.stops.map((stop) => stop.lon);
      expect(
        block.centerLat,
        closeTo((lats.reduce(math.min) + lats.reduce(math.max)) / 2, 0.01),
      );
      expect(
        block.centerLon,
        closeTo((lons.reduce(math.min) + lons.reduce(math.max)) / 2, 0.01),
      );
      expect(
        block.latSpan,
        greaterThan(lats.reduce(math.max) - lats.reduce(math.min)),
      );
      expect(
        block.lonSpan,
        greaterThan(lons.reduce(math.max) - lons.reduce(math.min)),
      );
      expect(block.markers, hasLength(second.stops.length));
      expect(block.routes, hasLength(1));
      expect(block.routes.single.stops, second.stops);
      expect(block.title, second.title);
    });

    test('viaje con una sola parada no produce bloque', () {
      const short = VisualJourney(
        id: 'x',
        title: 'Corto',
        order: 9,
        stops: [MapMarker(name: 'A', lat: 10, lon: 10)],
      );
      expect(short.toMapBlock(), isNull);
      expect(short.entry.resource, 'atlas');
    });
  });

  group('flechas de dirección', () {
    test('chevron anclado al medio del tramo, punta en la dirección del avance', () {
      final from = const Offset(20, 100);
      final to = const Offset(120, 100);
      final chevron = routeArrowChevron(from, to)!;
      // Anclada al punto medio del tramo (t = 0.5); la punta apunta hacia `to`.
      expect(chevron[0].dy, closeTo(100, 0.01));
      expect(chevron[0].dx, closeTo(70, 0.01));
      // Alas detrás de la punta, separadas perpendicularmente.
      expect(chevron[1].dx, closeTo(65, 0.01));
      expect(chevron[1].dy, closeTo(104, 0.01));
      expect(chevron[2].dx, closeTo(65, 0.01));
      expect(chevron[2].dy, closeTo(96, 0.01));
      // La punta queda por delante de las alas (dirección de avance).
      expect(chevron[0].dx, greaterThan(chevron[1].dx));
      // El ancla se puede mover a lo largo del tramo (tramos largos llevan
      // dos flechas).
      final lateArrow = routeArrowChevron(from, to, anchor: 0.72)!;
      expect(lateArrow[0].dx, closeTo(92, 0.01));
    });

    test('tramo corto o degenerado no dibuja flecha', () {
      expect(
        routeArrowChevron(const Offset(10, 10), const Offset(14, 10)),
        isNull,
      );
      expect(
        routeArrowChevron(const Offset(10, 10), const Offset(10, 10)),
        isNull,
      );
    });

    test('orientación: apunta en el sentido del tramo', () {
      final down = routeArrowChevron(
        const Offset(50, 20),
        const Offset(50, 130),
      )!;
      final up = routeArrowChevron(
        const Offset(50, 130),
        const Offset(50, 20),
      )!;
      // En ambos casos las dos alas quedan al otro lado del eje del tramo.
      expect(down[1].dx, lessThan(50));
      expect(up[1].dx, greaterThan(50));
    });
  });

  group('BibleMap con rutas', () {
    const stops = [
      MapMarker(name: 'Antioquía', lat: 36.2, lon: 36.16, ref: 'ACT.13.1'),
      MapMarker(name: 'Derbe', lat: 37.4, lon: 33.5, ref: 'ACT.14.6'),
    ];
    final journeyBlock = MapBlock(
      title: '1.er viaje',
      centerLat: 36.8,
      centerLon: 34.8,
      latSpan: 3.4,
      lonSpan: 7.4,
      markers: stops,
      routes: [const MapRoute(label: '1.er viaje', stops: stops)],
    );

    testWidgets('pinta la capa de rutas sin leyenda si hay una sola', (
      tester,
    ) async {
      await tester.pumpWidget(_mapApp(journeyBlock));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('map-route-layer')), findsOneWidget);
      expect(find.byKey(const ValueKey('map-route-legend')), findsNothing);
      expect(find.byType(BibleMap), findsOneWidget);
    });

    testWidgets('con varias rutas muestra leyenda', (tester) async {
      final multi = MapBlock(
        title: 'Rutas',
        centerLat: 36.8,
        centerLon: 34.8,
        latSpan: 3.4,
        lonSpan: 7.4,
        markers: stops,
        routes: [
          const MapRoute(label: 'Ida', stops: stops),
          MapRoute(label: 'Vuelta', stops: [stops[1], stops[0]]),
        ],
      );
      await tester.pumpWidget(_mapApp(multi));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('map-route-legend')), findsOneWidget);
      expect(find.text('Ida'), findsOneWidget);
      expect(find.text('Vuelta'), findsOneWidget);
    });
  });
}

Widget _mapApp(MapBlock block) => ProviderScope(
  overrides: [
    mapGeometryProvider.overrideWith(
      (ref) => const MapGeometry(land: [], lakes: []),
    ),
  ],
  child: MaterialApp(
    locale: const Locale('es'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 480,
          child: BibleMap(block: block, onNavigate: (_) {}),
        ),
      ),
    ),
  ),
);
