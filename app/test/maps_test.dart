/// Bloques de mapa: parseo, renderizado offline y navegación por marcador.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aletheia/catalog/document_models.dart';
import 'package:aletheia/l10n/app_localizations.dart';
import 'package:aletheia/maps/bible_map.dart';

const _block = MapBlock(
  title: 'Jerusalén y Belén',
  caption: 'Mapa de prueba.',
  centerLat: 31.75,
  centerLon: 35.22,
  latSpan: 0.45,
  lonSpan: 0.55,
  markers: [
    MapMarker(
      name: 'Jerusalén',
      lat: 31.776667,
      lon: 35.234167,
      ref: 'JHN.3.1',
    ),
    MapMarker(name: 'Belén', lat: 31.704306, lon: 35.207639),
  ],
);

Widget _app({
  ValueChanged<String>? onNavigate,
  bool failGeometry = false,
  MapBlock block = _block,
}) => ProviderScope(
  overrides: [
    mapGeometryProvider.overrideWith(
      (ref) => failGeometry
          ? Future<MapGeometry>.error(StateError('sin geometría'))
          : const MapGeometry(land: [], lakes: []),
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
          child: BibleMap(block: block, onNavigate: onNavigate),
        ),
      ),
    ),
  ),
);

void main() {
  test('MapBlock.fromJson conserva el encuadre y los marcadores', () {
    final block = MapBlock.fromJson({
      'type': 'map',
      'title': 'Mapa de prueba',
      'center': [31.75, 35.22],
      'latSpan': 0.5,
      'lonSpan': 0.7,
      'markers': [
        {'name': 'Belén', 'lat': 31.704306, 'lon': 35.207639, 'ref': 'LUK.2.4'},
      ],
    });

    expect(block.title, 'Mapa de prueba');
    expect(block.centerLat, 31.75);
    expect(block.centerLon, 35.22);
    expect(block.latSpan, 0.5);
    expect(block.lonSpan, 0.7);
    expect(block.markers.single.name, 'Belén');
    expect(block.markers.single.ref, 'LUK.2.4');
  });

  testWidgets(
    'BibleMap dibuja marcadores y navega al pulsar uno con referencia',
    (tester) async {
      String? opened;
      await tester.pumpWidget(_app(onNavigate: (ref) => opened = ref));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('bible-map')), findsOneWidget);
      expect(find.text('Jerusalén y Belén'), findsOneWidget);
      expect(find.textContaining('Natural Earth'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('map-marker-Jerusalén')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('map-marker-Belén')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('map-marker-Jerusalén')));
      await tester.pumpAndSettle();
      expect(opened, 'JHN.3.1');
    },
  );

  testWidgets('BibleMap separa las etiquetas de marcadores cercanos', (
    tester,
  ) async {
    const clustered = MapBlock(
      title: 'Marcadores cercanos',
      centerLat: 31.75,
      centerLon: 35.22,
      latSpan: 0.45,
      lonSpan: 0.55,
      markers: [
        MapMarker(name: 'Uno', lat: 31.776, lon: 35.234),
        MapMarker(name: 'Dos', lat: 31.778, lon: 35.236),
        MapMarker(name: 'Tres', lat: 31.780, lon: 35.238),
      ],
    );
    await tester.pumpWidget(_app(block: clustered));
    await tester.pumpAndSettle();

    final one = tester.getRect(find.byKey(const ValueKey('map-marker-Uno')));
    final two = tester.getRect(find.byKey(const ValueKey('map-marker-Dos')));
    final three = tester.getRect(find.byKey(const ValueKey('map-marker-Tres')));
    expect(one.overlaps(two), isFalse);
    expect(one.overlaps(three), isFalse);
    expect(two.overlaps(three), isFalse);
  });

  testWidgets('BibleMap muestra un error controlado si falla la geometría', (
    tester,
  ) async {
    await tester.pumpWidget(_app(failGeometry: true));
    await tester.pumpAndSettle();
    expect(find.text('No se pudo cargar el mapa.'), findsOneWidget);
    expect(find.byKey(const ValueKey('bible-map')), findsOneWidget);
  });
}
