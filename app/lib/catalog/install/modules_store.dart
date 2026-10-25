/// Módulos del catálogo desacoplado: instalar, actualizar y desinstalar.
///
/// La app de escritorio no lleva todo el contenido dentro del ejecutable: la
/// Tienda lista los módulos publicados en `aletheia-mods` (v2, con listado de
/// archivos y sha256) y el usuario decide qué instalar. Los archivos bajan a
/// `<datos>/modules/<ruta relativa del catálogo>` con progreso y cancelación,
/// y la lectura pasa por el router de fuentes (instalado → empaquetado → no
/// instalado).
///
/// La web no usa este store: allí el service worker cachea lo descargado y la
/// Tienda queda en modo descubrimiento. Por eso las pruebas escriben en un
/// directorio temporal y `main()` crea el store con el directorio real.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart'
    show ValueNotifier, debugPrint;
import 'package:http/http.dart' as http;

import '../catalog_asset_source.dart';
import '../mods_catalog_source.dart' show kDefaultModsBaseUrl;
import 'mods_manifest.dart';

/// Fase visible de una instalación.
enum ModuleInstallPhase { running, error, done }

/// Progreso de la instalación de un módulo (bytes recibidos y totales).
class ModuleInstallProgress {
  const ModuleInstallProgress({
    required this.phase,
    required this.received,
    required this.total,
    this.error,
  });

  final ModuleInstallPhase phase;
  final int received;
  final int total;
  final Object? error;

  /// 0..1, o `null` si el total no se conoce todavía.
  double? get fraction {
    if (total <= 0) return null;
    return (received / total).clamp(0.0, 1.0);
  }
}

/// Un módulo ya instalado, tal como vive en `modules.json`.
class InstalledModule {
  const InstalledModule({
    required this.id,
    required this.version,
    required this.files,
    required this.bytes,
    required this.installedAt,
  });

  final String id;
  final String version;

  /// Rutas relativas al catálogo (`asv/manifest.json`, `asv/books/GEN.…`).
  final List<String> files;
  final int bytes;
  final String installedAt;

  /// `true` si la ruta lógica pertenece a este módulo instalado.
  bool ownsPath(String logicalPath) =>
      files.contains(catalogRelativePath(logicalPath));

  factory InstalledModule.fromJson(Map<String, dynamic> json) =>
      InstalledModule(
        id: json['id'] as String? ?? '',
        version: json['version'] as String? ?? '',
        files: ((json['files'] as List?) ?? const [])
            .map((file) => file.toString())
            .toList(),
        bytes: (json['bytes'] as num?)?.toInt() ?? 0,
        installedAt: json['installedAt'] as String? ?? '',
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'version': version,
    'files': files,
    'bytes': bytes,
    'installedAt': installedAt,
  };
}

/// Índice de módulos instalados, persistido en `<modules>/modules.json`.
class InstalledModulesIndex {
  const InstalledModulesIndex({
    this.catalogVersion = '',
    this.modules = const {},
  });

  /// Versión del catálogo que quedó instalada por última vez (para detectar
  /// «hay actualizaciones» en la Tienda).
  final String catalogVersion;
  final Map<String, InstalledModule> modules;

  static const empty = InstalledModulesIndex();

  static InstalledModulesIndex fromJson(Object? json) {
    if (json is! Map) return empty;
    final entries = (json['modules'] as Map?) ?? const {};
    final modules = <String, InstalledModule>{};
    entries.forEach((key, value) {
      if (value is! Map) return;
      final module = InstalledModule.fromJson(Map<String, dynamic>.from(value));
      if (module.id.isNotEmpty) modules[module.id] = module;
    });
    return InstalledModulesIndex(
      catalogVersion: json['catalogVersion'] as String? ?? '',
      modules: modules,
    );
  }

  Map<String, Object?> toJson() => {
    'catalogVersion': catalogVersion,
    'modules': {
      for (final entry in modules.entries) entry.key: entry.value.toJson(),
    },
  };
}

/// Controlador de la Tienda de módulos: instalar · cancelar · desinstalar.
///
/// Sin Riverpod: se instancia en `main()` con el directorio de datos real y
/// se expone por `modulesStoreProvider` (nulo en web). Las consultas
/// [isInstalled]/[ownsPath] son síncronas porque el router del catálogo las
/// pregunta por cada lectura.
class ModulesStore {
  ModulesStore({
    required this.baseDirectory,
    required this.loadManifest,
    String? modsBaseUrl,
    http.Client? client,
  }) : _modsBaseUrl = modsBaseUrl ?? kDefaultModsBaseUrl,
       _client = client ?? http.Client();

  /// Directorio raíz de módulos (`<datos>/modules`). Vacío = sin acciones.
  final String baseDirectory;

  /// Base del catálogo remoto; las pruebas la apuntan a un servidor local.
  final String _modsBaseUrl;

  /// Carga perezosa del manifiesto remoto (`mods.json`). Si no hay red,
  /// `install` terminar con un error visible en la tarjeta.
  final Future<CatalogModulesManifest?> Function() loadManifest;

  http.Client _client;
  bool _disposed = false;
  final Set<String> _cancelling = {};
  final Set<String> _installing = {};

  /// Módulos instalados.
  final ValueNotifier<InstalledModulesIndex> index = ValueNotifier(
    InstalledModulesIndex.empty,
  );

  /// Progresos visibles (`id → progreso`); lo observa la Tienda.
  final ValueNotifier<Map<String, ModuleInstallProgress>> transfers =
      ValueNotifier(const {});

  static const modulesFileName = 'modules.json';

  // ------------------------------------------------------------- consultas

  /// El módulo está instalado (vigente o desactualizado).
  bool isInstalled(String moduleId) => index.value.modules.containsKey(moduleId);

  String? versionOf(String moduleId) => index.value.modules[moduleId]?.version;

  /// `true` si el módulo está instalado pero el catálogo remoto publicó otra
  /// versión. Consulta el manifiesto, así que conviene llamarlo desde la UI
  /// con el manifiesto ya cargado.
  bool hasUpdateFor(String moduleId, CatalogModulesManifest? manifest) {
    if (!isInstalled(moduleId)) return false;
    final remote = manifest?.version;
    if (remote == null || remote.isEmpty) return false;
    final local = index.value.modules[moduleId]?.version ?? '';
    return local.isNotEmpty && remote != local;
  }

  int installedBytes(String moduleId) =>
      index.value.modules[moduleId]?.bytes ?? 0;

  /// `true` si la ruta lógica vive en un módulo ya instalado. El router la
  /// consulta por cada lectura: debe ser barata y síncrona.
  bool ownsPath(String logicalPath) {
    if (baseDirectory.isEmpty || _disposed) return false;
    final moduleId = ModuleEntry.idForPath(logicalPath);
    if (moduleId == null) return false;
    return index.value.modules[moduleId]?.ownsPath(logicalPath) ?? false;
  }

  // ------------------------------------------------------------------ carga

  /// Lee `modules.json`. Idempotente; se llama justo tras crear el store.
  Future<void> load() async {
    if (baseDirectory.isEmpty) return;
    try {
      final file = indexFile;
      if (!await file.exists()) {
        if (index.value.modules.isNotEmpty) {
          index.value = InstalledModulesIndex.empty;
        }
        return;
      }
      index.value = InstalledModulesIndex.fromJson(
        jsonDecode(await file.readAsString()),
      );
    } catch (error) {
      // Índice corrupto: no bloquear la app; la próxima instalación lo
      // reescribe desde cero.
      debugPrint('modules.json ilegible, arranco sin módulos: $error');
    }
  }

  File get indexFile =>
      File('$baseDirectory${Platform.pathSeparator}$modulesFileName');

  Future<void> _writeIndex() async {
    if (baseDirectory.isEmpty || _disposed) return;
    await Directory(baseDirectory).create(recursive: true);
    final temp = File(
      '${indexFile.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    await temp.writeAsString(jsonEncode(index.value.toJson()), flush: true);
    if (await indexFile.exists()) await indexFile.delete();
    await temp.rename(indexFile.path);
  }

  // ------------------------------------------------------------ instalación

  /// Instala (o reinstala) un módulo completo desde el catálogo remoto.
  ///
  /// Los archivos se escriben atómicamente (`.tmp` → renombrar) y se
  /// verifican con el sha256 publicado. Devuelve `true` si quedó instalado.
  Future<bool> install(ModuleEntry cardEntry) async {
    if (baseDirectory.isEmpty || _disposed) return false;
    final id = cardEntry.id;
    if (_installing.contains(id)) return false;
    _installing.add(id);
    _cancelling.remove(id);
    _set(
      id,
      ModuleInstallProgress(
        phase: ModuleInstallPhase.running,
        received: 0,
        total: cardEntry.size,
      ),
    );
    try {
      final manifest = await loadManifest();
      if (manifest == null) {
        throw CatalogException(
          'no hay catálogo remoto accesible; revisa la conexión',
        );
      }
      // Si el catálogo cambió entre el render y el tap, se instala el
      // listado vigente, no el que pidió la tarjeta.
      ModuleEntry? target;
      for (final candidate in manifest.entries) {
        if (candidate.id == id) {
          target = candidate;
          break;
        }
      }
      final files = target?.files ?? cardEntry.files;
      final total = target?.size ?? cardEntry.size;
      var received = 0;
      for (final file in files) {
        _throwIfCancelled(id);
        // Actualización delta: si el archivo ya está en disco con el sha256
        // publicado, no se vuelve a bajar (reinstalar/actualizar una
        // biblioteca sólo transfiere lo cambiado).
        if (await _localFileMatches(file)) {
          received += file.bytes;
          _set(
            id,
            ModuleInstallProgress(
              phase: ModuleInstallPhase.running,
              received: received,
              total: total,
            ),
          );
          continue;
        }
        received += await _downloadAndVerify(id, file, received, total);
      }
      await _commit(
        InstalledModule(
          id: id,
          version: manifest.version,
          files: [for (final file in files) file.path],
          bytes: received,
          installedAt: DateTime.now().toIso8601String(),
        ),
      );
      _set(
        id,
        ModuleInstallProgress(
          phase: ModuleInstallPhase.done,
          received: received,
          total: total,
        ),
      );
      _clearSoon(id);
      return true;
    } on CatalogDownloadCancelled {
      _clear(id);
      return false;
    } catch (error) {
      if (_disposed) return false;
      if (_cancelling.contains(id)) {
        _clear(id);
        return false;
      }
      _set(
        id,
        ModuleInstallProgress(
          phase: ModuleInstallPhase.error,
          received: transfers.value[id]?.received ?? 0,
          total: transfers.value[id]?.total ?? 0,
          error: error,
        ),
      );
      _clearSoon(id);
      debugPrint('instalación de $id falló: $error');
      return false;
    } finally {
      _installing.remove(id);
    }
  }

  void _throwIfCancelled(String id) {
    if (_cancelling.contains(id) || _disposed) {
      throw const CatalogDownloadCancelled();
    }
  }

  /// ¿El archivo local ya coincide con el sha256 publicado? Sólo sirve para
  /// saltar la descarga (actualización delta); sin sha en el manifiesto no se
  /// puede decidir y se baja de nuevo.
  Future<bool> _localFileMatches(ModuleFile file) async {
    if (file.sha256.isEmpty) return false;
    final local = File(absolutePath(file.path));
    if (!await local.exists()) return false;
    if (file.bytes > 0 && await local.length() != file.bytes) return false;
    if (file.bytes == 0) {
      final bytes = await local.readAsBytes();
      return sha256.convert(bytes).toString() == file.sha256;
    }
    final digest = await sha256.bind(local.openRead()).first;
    return digest.toString() == file.sha256;
  }

  /// Descarga un archivo a disco (atómico) y verifica su sha256.
  Future<int> _downloadAndVerify(
    String id,
    ModuleFile file,
    int receivedBefore,
    int total,
  ) async {
    _throwIfCancelled(id);
    final response = await _client
        .send(
          http.Request(
            'GET',
            Uri.parse('$_modsBaseUrl/${file.path}'),
          ),
        )
        .timeout(const Duration(seconds: 60));
    if (response.statusCode != 200) {
      throw CatalogException(
        'no se pudo descargar ${file.path} (HTTP ${response.statusCode})',
        status: response.statusCode,
      );
    }
    final target = File(absolutePath(file.path));
    await target.parent.create(recursive: true);
    final temp = File('${target.path}.part');
    final sink = temp.openWrite();
    var received = 0;
    try {
      await for (final chunk in response.stream) {
        _throwIfCancelled(id);
        sink.add(chunk);
        received += chunk.length;
        if (received % (256 * 1024) <= chunk.length) {
          _set(
            id,
            ModuleInstallProgress(
              phase: ModuleInstallPhase.running,
              received: receivedBefore + received,
              total: total,
            ),
          );
        }
      }
      await sink.flush();
      await sink.close();
      final bytes = await temp.readAsBytes();
      final digest = sha256.convert(bytes).toString();
      if (file.sha256.isNotEmpty && digest != file.sha256) {
        throw ModuleVerificationException(file.path);
      }
      if (await target.exists()) await target.delete();
      await temp.rename(target.path);
    } finally {
      if (await temp.exists()) {
        try {
          await temp.delete();
        } catch (_) {}
      }
    }
    return received;
  }

  /// Ruta absoluta en disco de un archivo del módulo: la misma ruta relativa
  /// que el catálogo empaquetado, bajo el directorio de módulos.
  String absolutePath(String logicalOrRelative) {
    final relative = catalogRelativePath(logicalOrRelative);
    return '$baseDirectory${Platform.pathSeparator}'
        '${relative.replaceAll('/', Platform.pathSeparator)}';
  }

  Future<void> _commit(InstalledModule module) async {
    final next = Map<String, InstalledModule>.of(index.value.modules);
    next[module.id] = module;
    index.value = InstalledModulesIndex(
      catalogVersion: module.version,
      modules: next,
    );
    await _writeIndex();
  }

  void _set(String id, ModuleInstallProgress progress) {
    if (_disposed) return;
    final next = Map<String, ModuleInstallProgress>.of(transfers.value);
    next[id] = progress;
    transfers.value = next;
  }

  void _clear(String id) {
    if (_disposed) return;
    final next = Map<String, ModuleInstallProgress>.of(transfers.value);
    next.remove(id);
    transfers.value = next;
  }

  void _clearSoon(String id) {
    unawaited(
      Future<void>.delayed(const Duration(seconds: 3), () {
        final phase = transfers.value[id]?.phase;
        if (phase == ModuleInstallPhase.done ||
            phase == ModuleInstallPhase.error) {
          _clear(id);
        }
      }),
    );
  }

  // ---------------------------------------------------------- desinstalar

  /// Quita un módulo: borra su carpeta (o el archivo suelto) y la fila del
  /// índice. Las lecturas caen al empaquetado o a «no instalado».
  Future<void> uninstall(String moduleId) async {
    if (baseDirectory.isEmpty || _disposed) return;
    final module = index.value.modules[moduleId];
    if (module != null) {
      final dir = ModuleEntry.dirFor(moduleId);
      if (dir == null) {
        // Módulos con archivos del raíz (`catalog.search`): borra uno a uno.
        for (final relative in module.files) {
          final file = File(absolutePath(relative));
          if (await file.exists()) await file.delete();
        }
      } else {
        final directory = Directory(absolutePath('$dir/'));
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      }
    }
    final next = Map<String, InstalledModule>.of(index.value.modules);
    next.remove(moduleId);
    index.value = InstalledModulesIndex(
      catalogVersion: index.value.catalogVersion,
      modules: next,
    );
    await _writeIndex();
  }

  // ---------------------------------------------------------------- cancel

  /// Cancela una instalación en curso (o todas si no hay id). Termina ni
  /// bien llegue el próximo chunk; los parciales se limpian solos.
  void cancel([String? id]) {
    if (id == null) {
      _cancelling.addAll(transfers.value.keys);
    } else {
      _cancelling.add(id);
    }
    // Cerrar el cliente aborta la conexión abierta por el chunk stream.
    _client.close();
    _client = http.Client();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _client.close();
    index.dispose();
    transfers.dispose();
  }
}
