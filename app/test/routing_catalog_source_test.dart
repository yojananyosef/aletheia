/// Routing del catálogo en escritorio con el desacople slim: lo empaquetado
/// (RV1909, Strong, devocional, Factbook, metadatos) sale de assets, lo
/// instalado sale de `<datos>/modules` y lo demás lanza
/// `CatalogNotInstalledException` (CTA «Instalar en la Tienda»).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:aletheia/catalog/catalog_asset_source.dart';
import 'package:aletheia/catalog/install/disk_catalog_source.dart';
import 'package:aletheia/catalog/install/modules_store.dart';
import 'package:aletheia/catalog/install/routing_catalog_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late ModulesStore store;
  late RoutingCatalogSource source;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('routing-catalog-source-');
    addTearDown(() => directory.deleteSync(recursive: true));

    // Un módulo instalado en disco con un archivo mínimo legible.
    final installedDir =
        Directory('${directory.path}${Platform.pathSeparator}asv')
          ..createSync(recursive: true);
    File('${installedDir.path}${Platform.pathSeparator}manifest.json')
        .writeAsStringSync('{"resourceId":"bible.asv"}');

    store = ModulesStore(
      baseDirectory: directory.path,
      loadManifest: () async => null,
    )
      ..index.value = InstalledModulesIndex(
        catalogVersion: 'test',
        modules: {
          'bible.asv': InstalledModule(
            id: 'bible.asv',
            version: '1',
            files: const ['asv/manifest.json'],
            bytes: 24,
            installedAt: '2026-01-01T00:00:00Z',
          ),
        },
      );
    addTearDown(store.dispose);

    source = RoutingCatalogSource(
      modulesStore: store,
      disk: DiskCatalogSource(baseDirectory: directory.path),
      assets: AssetCatalogSource(),
    );
    addTearDown(source.dispose);
  });

  test('el módulo instalado se lee de disco', () async {
    final text = await source.loadText('assets/catalog/asv/manifest.json');
    expect(text, '{"resourceId":"bible.asv"}');
  });

  test('lo empaquetado (RV1909, Strong, devocional, Factbook) sale de assets',
      () async {
    const bundled = [
      'assets/catalog/rv1909/manifest.json',
      'assets/catalog/lexicon.strongs/manifest.json',
      'assets/catalog/devotional.daily/sections.json.gz',
      'assets/catalog/factbook.core/sections.json.gz',
      'assets/catalog/index.json',
      'assets/catalog/map_sections.json',
      'assets/catalog/morphology.json',
    ];
    for (final path in bundled) {
      // No lanza: existe en los assets del árbol de desarrollo.
      await source.loadText(path);
    }
  });

  test('lo no instalado lanza CatalogNotInstalledException', () async {
    // El meta + índice FTS5 viajan como el módulo `catalog.search`: sin
    // instalarlo, la búsqueda y el estado de Ajustes caen con CTA.
    for (final path in [
      'assets/catalog/bible/asv/books/GEN.json.gz',
      'assets/catalog/kjv/manifest.json',
      'assets/catalog/search.sqlite.gz',
      'assets/catalog/search.meta.json',
    ]) {
      await expectLater(
        source.loadText(path),
        throwsA(isA<CatalogNotInstalledException>()),
      );
    }
  });
}
