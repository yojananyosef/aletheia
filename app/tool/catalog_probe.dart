// Sonda temporal: ejercita CatalogClient contra el servicio real.
// Uso: dart run tool/catalog_probe.dart
//
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:aletheia/catalog/catalog_client.dart';

Future<void> main() async {
  final client = CatalogClient(baseUrl: 'http://127.0.0.1:8787');
  try {
    final health = await client.health();
    print('health → $health');

    final listing = await client.listResources();
    print('resources → total=${listing.total} '
        'items=${listing.items.map((r) => r.id).toList()} '
        'facets=${listing.facets}');

    final search = await client.search(query: '"In the beginning"', pageSize: 3);
    print('search → total=${search.total} '
        'first=${search.hits.isEmpty ? null : search.hits.first.citation}');

    final manifest = await client.fetchManifestJson('bible.kjv');
    print('manifest → ${manifest['id']} books=${(manifest['books'] as List).length}');

    final book = await client.fetchBookJson('bible.kjv', 'GEN');
    print('book → ${book['code']} chapters=${(book['chapters'] as List).length}');
  } catch (error, stack) {
    print('ERROR: $error');
    print(stack);
  } finally {
    client.close();
  }
  exit(0);
}
