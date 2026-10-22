/// Pruebas del store de módulos (catálogo desacoplado).
///
/// Monta un servidor HTTP efímero con un `mods.json` de prueba y dos archivos,
/// y verifica el ciclo completo de la Tienda: instalar —con verificación
/// sha256 y escritura atómica—, detectar corrupción (sha distinto), cancelar a
/// mitad de descarga, desinstalar y el mapeo ruta→módulo que usa el router del
/// catálogo.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show sha256;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:aletheia/catalog/install/mods_manifest.dart';
import 'package:aletheia/catalog/install/modules_store.dart';
import 'package:aletheia/catalog/mods_catalog_source.dart';

String _sha(Uint8List bytes) => sha256.convert(bytes).toString();

/// Servidor efímero que sirve una carpeta: `GET /ruta` → `<raíz>/ruta`
/// (ignora la query de caché `?v=…` del cliente).
class _FakeModsServer {
  _FakeModsServer(this.root);

  final Directory root;
  HttpServer? _server;
  Duration _delay = Duration.zero;

  Future<String> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    unawaited(
      server.forEach((request) async {
        final path = request.uri.path.replaceFirst(RegExp(r'^/'), '');
        if (_delay > Duration.zero) {
          await Future<void>.delayed(_delay);
        }
        final file = File(
          '${root.path}${Platform.pathSeparator}'
          '${path.replaceAll('/', Platform.pathSeparator)}',
        );
        if (path.isEmpty || !await file.exists()) {
          request.response.statusCode = 404;
          await request.response.close();
          return;
        }
        request.response.add(await file.readAsBytes());
        await request.response.close();
      }),
    );
    return 'http://127.0.0.1:${server.port}';
  }

  Future<void> close() async {
    await _server?.close(force: true);
    _server = null;
  }
}

/// Los dos archivos del módulo de prueba y su contenido.
const _asvManifestBody = '{"resourceId":"bible.asv","title":"ASV"}';
const _asvGenesisBody = '[{"texto plano de Genesis 1"}]';

Uint8List _gzip(String text) => Uint8List.fromList(gzip.encode(utf8.encode(text)));

/// Escribe la raíz del servidor (mods.json + módulo) y crea el manifiesto.
Future<(CatalogModulesManifest, String)> _seed(Directory root) async {
  final asvManifest = utf8.encode(_asvManifestBody);
  final asvGenesis = _gzip(_asvGenesisBody);
  await Directory('${root.path}/asv/books').create(recursive: true);
  await File('${root.path}/asv/manifest.json').writeAsBytes(asvManifest);
  await File('${root.path}/asv/books/GEN.json.gz').writeAsBytes(asvGenesis);
  final module = ModuleEntry(
    id: 'bible.asv',
    type: 'bible',
    title: 'American Standard Version',
    language: 'en',
    files: [
      ModuleFile(
        path: 'asv/manifest.json',
        bytes: asvManifest.length,
        sha256: _sha(Uint8List.fromList(asvManifest)),
      ),
      ModuleFile(
        path: 'asv/books/GEN.json.gz',
        bytes: asvGenesis.length,
        sha256: _sha(asvGenesis),
      ),
    ],
    size: asvManifest.length + asvGenesis.length,
  );
  final manifest = CatalogModulesManifest(
    version: '2026.01',
    publishedAt: '2026-01-05',
    entries: [module],
  );
  final modsJson = jsonEncode({
    'schema': 2,
    'version': manifest.version,
    'publishedAt': manifest.publishedAt,
    'resources': [
      {
        'id': module.id,
        'type': module.type,
        'title': module.title,
        'language': module.language,
        'size': module.size,
        'files': [
          {'path': 'asv/manifest.json', 'bytes': asvManifest.length, 'sha256': _sha(Uint8List.fromList(asvManifest))},
          {'path': 'asv/books/GEN.json.gz', 'bytes': asvGenesis.length, 'sha256': _sha(asvGenesis)},
        ],
      },
    ],
  });
  await File('${root.path}/mods.json').writeAsString(modsJson);
  return (manifest, manifest.version);
}

/// Store nuevo con servidor limpio. Devuelve también la ruta de módulos y el
/// manifiesto.
Future<(ModulesStore, _FakeModsServer, String, CatalogModulesManifest)>
_freshInstall() async {
  final root = await Directory.systemTemp.createTemp('aletheia-mods-');
  final (manifest, _) = await _seed(root);
  final server = _FakeModsServer(root);
  final baseUrl = await server.start();
  final modulesDir =
      '${(await Directory.systemTemp.createTemp('aletheia-app-')).path}'
      '${Platform.pathSeparator}modules';
  final store = ModulesStore(
    baseDirectory: modulesDir,
    loadManifest: () async => manifest,
    modsBaseUrl: baseUrl,
    client: http.Client(),
  );
  await store.load();
  return (store, server, modulesDir, manifest);
}

void main() {
  test('ModuleEntry.idForPath mapea las rutas lógicas del catálogo', () {
    expect(
      ModuleEntry.idForPath('assets/catalog/rv1909/manifest.json'),
      'bible.rv1909',
    );
    expect(ModuleEntry.idForPath('assets/catalog/asv/books/JHN.json.gz'), 'bible.asv');
    expect(ModuleEntry.idForPath('assets/catalog/easton/sections.json.gz'), 'dictionary.easton');
    expect(
      ModuleEntry.idForPath('assets/catalog/matthew-henry-concise/sections/GEN.1.json.gz'),
      'commentary.matthew-henry-concise',
    );
    expect(ModuleEntry.idForPath('assets/catalog/search.sqlite.gz'), 'catalog.search');
    expect(ModuleEntry.idForPath('assets/catalog/search.meta.json'), 'catalog.search');
    // Metadatos compartidos: siempre empaquetados, sin módulo.
    expect(ModuleEntry.idForPath('assets/catalog/index.json'), isNull);
    expect(ModuleEntry.idForPath('assets/catalog/morphology.json'), isNull);
    expect(ModuleEntry.idForPath('assets/catalog/map_sections.json'), isNull);
  });

  test('la Tienda parsea mods.json remoto (v2) con archivos y sha256', () async {
    final root = await Directory.systemTemp.createTemp('aletheia-mods-');
    addTearDown(() => root.delete(recursive: true));
    await _seed(root);
    final server = _FakeModsServer(root);
    final baseUrl = await server.start();
    addTearDown(server.close);

    final source = ModsCatalogSource(baseUrl: baseUrl, client: http.Client());
    addTearDown(source.dispose);
    final manifest = await source.loadManifest();
    expect(manifest, isNotNull);
    expect(manifest!.version, '2026.01');
    expect(manifest.entries, hasLength(1));
    final entry = manifest.entries.single;
    expect(entry.id, 'bible.asv');
    expect(entry.files, hasLength(2));
    expect(entry.size, greaterThan(0));
    expect(entry.files[0].sha256, hasLength(64));
  });

  test('instala un módulo completo: archivos, índice y rutas propias', () async {
    final (store, server, modulesDir, manifest) = await _freshInstall();
    addTearDown(server.close);
    final moduleDir = Directory(modulesDir);

    final entry = manifest.entries.single;
    final ok = await store.install(entry);
    expect(ok, isTrue, reason: 'instalación con sha correcto debe terminar');

    // Archivos en disco con la misma ruta relativa del catálogo.
    final manifestFile = File(
      '$modulesDir${Platform.pathSeparator}asv'
      '${Platform.pathSeparator}manifest.json',
    );
    expect(await manifestFile.exists(), isTrue);
    expect(await manifestFile.readAsString(), _asvManifestBody);
    final genesis = File(
      '$modulesDir${Platform.pathSeparator}asv'
      '${Platform.pathSeparator}books${Platform.pathSeparator}GEN.json.gz',
    );
    expect(await genesis.exists(), isTrue);

    // Sin restos de la descarga parcial.
    expect(
      await moduleDir.list(recursive: true).any((e) => e.path.endsWith('.part')),
      isFalse,
    );

    // Índice persistido: módulo vigente con su versión y archivos.
    expect(store.isInstalled('bible.asv'), isTrue);
    expect(store.versionOf('bible.asv'), '2026.01');
    expect(
      store.ownsPath('assets/catalog/asv/manifest.json'),
      isTrue,
      reason: 'el router debe leer del disco tras instalar',
    );
    expect(store.ownsPath('assets/catalog/asv/books/JHN.json.gz'), isFalse);
    expect(store.ownsPath('assets/catalog/kjv/manifest.json'), isFalse);

    // El índice vive en un modules.json legible.
    final persisted = await store.indexFile.readAsString();
    expect(persisted, contains('bible.asv'));
    expect(persisted, contains('2026.01'));

    store.dispose();
  });

  test('un sha que no coincide corrompe la instalación y no se confirma', () async {
    final (store, server, modulesDir, manifest) = await _freshInstall();
    addTearDown(server.close);

    // Corrompe el segundo archivo DESPUÉS de publicar el sha original.
    await File(
      '${server.root.path}${Platform.pathSeparator}asv'
      '${Platform.pathSeparator}books${Platform.pathSeparator}GEN.json.gz',
    ).writeAsBytes(_gzip('contenido corrompido'));

    final ok = await store.install(manifest.entries.single);
    expect(ok, isFalse);
    final progress = store.transfers.value['bible.asv'];
    expect(progress, isNotNull);
    expect(progress!.phase, ModuleInstallPhase.error);
    expect(progress.error, isA<ModuleVerificationException>());
    expect(store.isInstalled('bible.asv'), isFalse);

    // Sin archivo válido instalado ni restos .part.
    final genesis = File(
      '$modulesDir${Platform.pathSeparator}asv'
      '${Platform.pathSeparator}books${Platform.pathSeparator}GEN.json.gz',
    );
    expect(await genesis.exists(), isFalse);
    final dir = Directory(modulesDir);
    expect(
      await dir.list(recursive: true).any((e) => e.path.endsWith('.part')),
      isFalse,
    );

    store.dispose();
  });

  test('cancelar a mitad de descarga deja el módulo sin confirmar', () async {
    final (store, server, modulesDir, manifest) = await _freshInstall();
    addTearDown(server.close);

    // Cada petición tarda: el cancel cierra el cliente y aborta en vuelo.
    server._delay = const Duration(milliseconds: 350);
    final entry = manifest.entries.single;
    final future = store.install(entry);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    store.cancel('bible.asv');
    final ok = await future;
    expect(ok, isFalse);
    expect(store.isInstalled('bible.asv'), isFalse);
    // Puede quedar el primer archivo (progreso parcial) pero no el .part.
    await Future<void>.delayed(const Duration(milliseconds: 30));
    final modules = Directory(modulesDir);
    if (await modules.exists()) {
      expect(
        await modules
            .list(recursive: true)
            .any((e) => e.path.endsWith('.part')),
        isFalse,
      );
    }

    store.dispose();
  });

  test('sin manifest remoto la instalación falla con un error claro', () async {
    final root = await Directory.systemTemp.createTemp('aletheia-mods-');
    addTearDown(() => root.delete(recursive: true));
    final (manifest, _) = await _seed(root);
    final server = _FakeModsServer(root);
    final baseUrl = await server.start();
    addTearDown(server.close);
    final modulesDir =
        '${(await Directory.systemTemp.createTemp('aletheia-app-')).path}'
        '${Platform.pathSeparator}modules';
    final store = ModulesStore(
      baseDirectory: modulesDir,
      loadManifest: () async => null,
      modsBaseUrl: baseUrl,
    );
    await store.load();

    final ok = await store.install(manifest.entries.single);
    expect(ok, isFalse);
    final progress = store.transfers.value['bible.asv'];
    expect(progress?.phase, ModuleInstallPhase.error);
    expect(store.isInstalled('bible.asv'), isFalse);

    store.dispose();
  });

  test('desinstalar borra la carpeta y vacía el índice', () async {
    final (store, server, modulesDir, manifest) = await _freshInstall();
    addTearDown(server.close);
    final ok = await store.install(manifest.entries.single);
    expect(ok, isTrue);

    await store.uninstall('bible.asv');
    expect(store.isInstalled('bible.asv'), isFalse);
    expect(store.ownsPath('assets/catalog/asv/manifest.json'), isFalse);
    expect(await Directory('$modulesDir/asv').exists(), isFalse);
    final persisted = await store.indexFile.readAsString();
    expect(persisted, isNot(contains('bible.asv')));

    // Recargar el índice no trae de vuelta el módulo.
    final reloaded = ModulesStore(
      baseDirectory: modulesDir,
      loadManifest: () async => manifest,
      modsBaseUrl: 'http://127.0.0.1:1',
    );
    addTearDown(reloaded.dispose);
    await reloaded.load();
    expect(reloaded.isInstalled('bible.asv'), isFalse);
    store.dispose();
  });

  test('el índice persistido sobrevive un reinicio del store', () async {
    final (store, server, modulesDir, manifest) = await _freshInstall();
    addTearDown(server.close);
    await store.install(manifest.entries.single);
    store.dispose();

    final revived = ModulesStore(
      baseDirectory: modulesDir,
      loadManifest: () async => manifest,
      modsBaseUrl: 'http://127.0.0.1:1',
    );
    addTearDown(revived.dispose);
    expect(revived.isInstalled('bible.asv'), isFalse);
    await revived.load();
    expect(revived.isInstalled('bible.asv'), isTrue);
    expect(revived.versionOf('bible.asv'), '2026.01');
  });
}
