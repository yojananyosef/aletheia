/// Catálogo desacoplado (mods): modelos del manifiesto `mods.json`.
///
/// `aletheia-mods` publica `mods.json` con cada recurso (y el índice de
/// búsqueda) como **módulo describable e instalable**: listado de archivos con
/// tamaño y sha256. La app de escritorio instala esos módulos en el directorio
/// de datos (con progreso y cancelación desde la Tienda) en vez de llevar el
/// contenido dentro del ejecutable; la web los descarga al usarlos y el
/// service worker los cachea.
library;

import '../catalog_asset_source.dart' show CatalogException;

/// Un archivo de módulo: ruta relativa al catálogo (`asv/books/GEN.json.gz`),
/// tamaño y sha256 para verificar la descarga.
class ModuleFile {
  const ModuleFile({required this.path, required this.bytes, required this.sha256});

  final String path;
  final int bytes;
  final String sha256;

  factory ModuleFile.fromJson(Map<String, dynamic> json) => ModuleFile(
    path: json['path'] as String? ?? '',
    bytes: (json['bytes'] as num?)?.toInt() ?? 0,
    sha256: json['sha256'] as String? ?? '',
  );

  Map<String, Object?> toJson() => {
    'path': path,
    'bytes': bytes,
    'sha256': sha256,
  };
}

/// Un módulo instalable del catálogo remoto.
///
/// Los recursos use el mismo id (`bible.asv`, `commentary.…`); el índice de
/// búsqueda es el módulo especial `catalog.search`.
class ModuleEntry {
  const ModuleEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.language,
    required this.files,
    required this.size,
    this.licenseKind = 'unknown',
    this.licenseText = '',
    this.verses = 0,
    this.sections = 0,
    this.entriesCount = 0,
  });

  static const searchModuleId = 'catalog.search';

  /// Mapa completo carpeta→id del catálogo (espeja `dirFor`). Las Biblias
  /// nuevas funcionan por regla general (`bible.<carpeta>`) sin tocar esto.
  static const _dirToId = <String, String>{
    'easton': 'dictionary.easton',
    'matthew-henry-concise': 'commentary.matthew-henry-concise',
    'lexicon.strongs': 'lexicon.strongs',
    'factbook.core': 'factbook.core',
    'devotional.daily': 'devotional.daily',
  };

  /// Recursos cuyo id **es** su carpeta (con punto): no se segmenta.
  static const _dirIsId = <String>{
    'lexicon.strongs',
    'factbook.core',
    'devotional.daily',
  };

  final String id;
  final String type;
  final String title;
  final String language;
  final List<ModuleFile> files;
  final int size;
  final String licenseKind;
  final String licenseText;
  final int verses;
  final int sections;
  final int entriesCount;

  /// Directorio del catálogo del recurso (`bible.asv` → `asv`,
  /// `factbook.core` → `factbook.core`). Espeja `DocumentRepository.dirFor`.
  static String? dirFor(String moduleId) {
    if (moduleId == searchModuleId) return null;
    if (_dirIsId.contains(moduleId)) return moduleId;
    if (!moduleId.contains('.')) return moduleId;
    return moduleId.split('.').last;
  }

  /// Módulo al que pertenece una ruta lógica del catálogo
  /// (`assets/catalog/asv/manifest.json` → `bible.asv`). `null` = archivos
  /// compartidos siempre empaquetados (índice, morfología, mapa).
  static String? idForPath(String path) {
    const prefix = 'assets/catalog/';
    if (!path.startsWith(prefix)) return null;
    final relative = path.substring(prefix.length);
    final top = relative.contains('/') ? relative.split('/').first : relative;
    switch (top) {
      case 'search.sqlite.gz':
      case 'search.meta.json':
        return searchModuleId;
      case 'index.json':
      case 'morphology.json':
      case 'map_sections.json':
        return null;
    }
    return _dirToId[top] ?? 'bible.$top';
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'language': language,
    'size': size,
    'files': [for (final file in files) file.toJson()],
  };
}

/// Manifiesto completo del catálogo remoto (`mods.json`).
class CatalogModulesManifest {
  const CatalogModulesManifest({
    required this.version,
    required this.publishedAt,
    required this.entries,
  });

  final String version;

  /// Fecha ISO de la publicación (para mostrar «Actualizado el …»).
  final String publishedAt;
  final List<ModuleEntry> entries;

  static CatalogModulesManifest? fromJson(Object? json) {
    if (json is! Map) return null;
    final resources = json['resources'];
    if (resources is! List) return null;
    final entries = <ModuleEntry>[];
    for (final item in resources) {
      if (item is! Map) continue;
      final files = [
        for (final file in (item['files'] as List?) ?? const [])
          if (file is Map) ModuleFile.fromJson(Map<String, dynamic>.from(file)),
      ];
      // Sin listado de archivos no se puede instalar (catálogo antiguo).
      if (files.isEmpty) continue;
      final license = item['license'];
      final stats = item['stats'];
      entries.add(
        ModuleEntry(
          id: item['id'] as String? ?? '',
          type: item['type'] as String? ?? 'dataset',
          title: item['title'] as String? ?? '',
          language: item['language'] as String? ?? '',
          size: (item['size'] as num?)?.toInt() ??
              files.fold(0, (total, file) => total + file.bytes),
          files: files,
          licenseKind: license is Map
              ? license['kind'] as String? ?? 'unknown'
              : 'unknown',
          licenseText: license is Map ? license['text'] as String? ?? '' : '',
          verses: stats is Map ? (stats['verses'] as num?)?.toInt() ?? 0 : 0,
          sections: stats is Map ? (stats['sections'] as num?)?.toInt() ?? 0 : 0,
          entriesCount: stats is Map
              ? (stats['entries'] as num?)?.toInt() ?? 0
              : 0,
        ),
      );
    }
    final version = json['version'] as String?;
    if (version == null || version.isEmpty || entries.isEmpty) return null;
    return CatalogModulesManifest(
      version: version,
      publishedAt: json['publishedAt'] as String? ?? '',
      entries: entries,
    );
  }
}

/// Los bytes descargados no corresponden al archivo publicado.
class ModuleVerificationException extends CatalogException {
  ModuleVerificationException(String path)
    : super('el archivo descargado no coincide (sha256): $path');
}
