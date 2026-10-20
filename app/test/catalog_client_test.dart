import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:aletheia/catalog/catalog_client.dart';

/// Servicio de catálogo falso servido con `HttpServer` real.
class _FakeService {
  late final HttpServer _server;
  late final CatalogClient client;

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = CatalogClient(baseUrl: 'http://127.0.0.1:${_server.port}');
    _server.listen((request) async {
      final response = request.response;
      switch (request.uri.path) {
        case '/v1/health':
          _json(response, {'status': 'ok', 'resources': 2, 'verses': 62186});
        case '/v1/resources':
          final type = request.uri.queryParameters['type'];
          _json(response, {
            'total': type == 'bible' ? 1 : 2,
            'page': 1,
            'pageSize': 50,
            'items': [
              {
                'id': 'bible.rv1909',
                'type': 'bible',
                'title': 'Reina-Valera 1909',
                'abbrev': 'RV1909',
                'language': 'es',
                'authors': ['Reina, Casiodoro de'],
                'license': {'kind': 'public-domain', 'text': 'Dominio público'},
                'stats': {'books': 66, 'sections': 1189, 'verses': 31102},
                'locked': false,
              },
            ],
            'facets': {
              'type': {'bible': 1},
              'language': {'es': 1},
              'author': {'Reina, Casiodoro de': 1},
            },
          });
        case '/v1/search':
          final query = request.uri.queryParameters['q'] ?? '';
          _json(response, {
            'query': query,
            'scope': request.uri.queryParameters['scope'] ?? 'all',
            'total': 1,
            'page': 1,
            'pageSize': 20,
            'hits': [
              {
                'resourceId': 'bible.rv1909',
                'resourceTitle': 'Reina-Valera 1909',
                'abbrev': 'RV1909',
                'sectionId': 'JHN.1',
                'book': 'JHN',
                'bookName': 'Juan',
                'chapter': 1,
                'verse': 1,
                'ref': 'JHN.1.1',
                'citation': 'Juan 1:1',
                'snippet': 'EN el principio era el <em>Verbo</em>, y el…',
                'locked': false,
              },
            ],
          });
        default:
          response.statusCode = HttpStatus.notFound;
          _json(response, {'error': 'no encontrado'});
      }
    });
  }

  static void _json(HttpResponse response, Map<String, dynamic> body) {
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(body));
    response.close();
  }

  Future<void> stop() => _server.close(force: true);
}

void main() {
  late _FakeService service;

  setUp(() async {
    service = _FakeService();
    await service.start();
  });

  tearDown(() async {
    service.client.close();
    await service.stop();
  });

  test('listResources parsea items, facets y licencia', () async {
    final listing = await service.client.listResources(type: 'bible');
    expect(listing.total, 1);
    final resource = listing.items.single;
    expect(resource.title, 'Reina-Valera 1909');
    expect(resource.abbrev, 'RV1909');
    expect(resource.licenseKind, 'public-domain');
    expect(resource.licenseText, 'Dominio público');
    expect(resource.verses, 31102);
    expect(resource.authors, ['Reina, Casiodoro de']);
    expect(listing.facets['type']?['bible'], 1);
  });

  test('search parsea resultados con cita, ref y snippet', () async {
    final result = await service.client.search(query: 'Verbo', scope: 'bible');
    expect(result.total, 1);
    final hit = result.hits.single;
    expect(hit.ref, 'JHN.1.1');
    expect(hit.citation, 'Juan 1:1');
    expect(hit.abbrev, 'RV1909');
    expect(hit.snippet, contains('<em>Verbo</em>'));
    expect(hit.locked, isFalse);
  });

  test('health informa recursos y versículos', () async {
    final health = await service.client.health();
    expect(health, isNotNull);
    expect(health!.resources, 2);
    expect(health.verses, 62186);
  });

  test('los errores HTTP se convierten en CatalogException', () async {
    await expectLater(
      service.client.fetchManifestJson('bible.nope'),
      throwsA(isA<CatalogException>()
          .having((e) => e.status, 'status', 404)
          .having((e) => e.message, 'mensaje', 'no encontrado')),
    );
  });

  test('health devuelve null si el servicio no responde', () async {
    final probe = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = probe.port;
    await probe.close(force: true);

    final dead = CatalogClient(baseUrl: 'http://127.0.0.1:$port');
    addTearDown(dead.close);
    expect(await dead.health(), isNull);
    await expectLater(
      dead.listResources(),
      throwsA(isA<CatalogException>()),
    );
  });
}
