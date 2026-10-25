/// Respaldo y restauración de datos sin cuenta (Ajustes ▸ Datos y respaldo).
///
/// Todo lo que el usuario crea vive en un único SQLite (`aletheia.db`:
/// workspace, notas, resaltados, favoritos, planes y progreso de cursos) más
/// el índice de módulos instalados (`modules/modules.json`, que se puede
/// reconstruir reinstalando). El respaldo es un **zip** con la base (y sus
/// acompañantes WAL si los hubiera) y un `meta.json` verificable; la
/// restauración se aplica **al reiniciar** — así funciona también en Windows,
/// donde no se puede reemplazar un archivo abierto.
///
/// Escritorio only: en web la persistencia es IndexedDB y el respaldo no se
/// ofrece (los datos siguen al perfil del navegador).
library;

import 'dart:convert';
import 'dart:io' show Directory, File, Platform;

import 'package:archive/archive.dart' as archive;

import 'app_version.dart';

/// Servicio de respaldo sobre el directorio de datos de la app.
class AppBackup {
  AppBackup({required this.dataDirectory});

  /// El mismo directorio que usa `openAppDatabase()` (`getApplicationSupportDirectory`).
  final Directory dataDirectory;

  File get _databaseFile => File(
    '${dataDirectory.path}${Platform.pathSeparator}aletheia.db',
  );

  /// Nombre estándar para un respaldo nuevo.
  String suggestedFileName() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return 'aletheia-respaldo-'
        '${now.year}${two(now.month)}${two(now.day)}-'
        '${two(now.hour)}${two(now.minute)}.aletheiabackup';
  }

  /// Empaqueta la base (+ WAL/SHM) y los metadatos en [destPath].
  ///
  /// Devuelve el archivo escrito. No toca la base abierta: lee una copia
  /// consistente de los bytes en disco (las tiendas hacen checkpoint al
  /// cerrar y las escrituras son transaccionales).
  Future<File> exportTo(String destPath) async {
    final db = _databaseFile;
    if (!await db.exists()) {
      throw BackupException('No hay base de datos que respaldar ($db).');
    }
    final zip = archive.Archive();
    void addIfExists(String suffix) {
      final file = File('${db.path}$suffix');
      if (file.existsSync()) {
        zip.addFile(
          archive.ArchiveFile.bytes('aletheia.db$suffix', file.readAsBytesSync()),
        );
      }
    }

    addIfExists('');
    addIfExists('-wal');
    addIfExists('-shm');
    zip.addFile(
      archive.ArchiveFile.bytes(
        'meta.json',
        utf8.encode(
          const JsonEncoder.withIndent('  ').convert({
            'app': 'aletheia',
            'schema': 1,
            'version': kAppVersion,
            'exportedAt': DateTime.now().toIso8601String(),
          }),
        ),
      ),
    );
    final modules = File(
      '${dataDirectory.path}${Platform.pathSeparator}modules'
      '${Platform.pathSeparator}modules.json',
    );
    if (modules.existsSync()) {
      zip.addFile(
        archive.ArchiveFile.bytes(
          'modules.json',
          modules.readAsBytesSync(),
        ),
      );
    }
    final encoded = archive.ZipEncoder().encode(zip);
    final dest = File(destPath);
    await dest.parent.create(recursive: true);
    await dest.writeAsBytes(encoded, flush: true);
    return dest;
  }

  /// Valida un respaldo y lo deja listo para aplicarse al reiniciar.
  ///
  /// Copia el contenido del zip a `<datos>/restore-pending/` (atómico: si
  /// algo falla, el estado actual no se toca). Devuelve el resumen para la
  /// confirmación del usuario.
  Future<BackupSummary> stageRestore(String zipPath) async {
    final file = File(zipPath);
    if (!await file.exists()) {
      throw BackupException('No se encontró el respaldo elegido.');
    }
    final archive.Archive zip;
    try {
      zip = archive.ZipDecoder().decodeBytes(await file.readAsBytes());
    } on Object {
      throw BackupException('El archivo no es un respaldo de Aletheia válido.');
    }
    final names = zip.files.map((f) => f.name).toSet();
    if (!names.contains('aletheia.db') || !names.contains('meta.json')) {
      throw BackupException(
        'El respaldo no contiene la base de datos (aletheia.db).',
      );
    }
    final metaEntry = zip.files.firstWhere((f) => f.name == 'meta.json');
    final meta =
        jsonDecode(utf8.decode(metaEntry.content as List<int>))
            as Map<String, dynamic>;
    if (meta['app'] != 'aletheia') {
      throw BackupException('El respaldo no es de Aletheia.');
    }
    final pending = Directory(
      '${dataDirectory.path}${Platform.pathSeparator}restore-pending',
    );
    if (pending.existsSync()) {
      pending.deleteSync(recursive: true);
    }
    pending.createSync(recursive: true);
    for (final entry in zip.files) {
      if (entry.isFile) {
        File(
          '${pending.path}${Platform.pathSeparator}${entry.name}',
        ).writeAsBytesSync(entry.content as List<int>);
      }
    }
    return BackupSummary(
      exportedAt:
          DateTime.tryParse(meta['exportedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      appVersion: meta['version'] as String? ?? '?',
      includesModules: names.contains('modules.json'),
    );
  }

  /// Aplica un respaldo pendiente (llamar **antes** de abrir la base).
  ///
  /// Devuelve true si se aplicó algo. La base actual se conserva en
  /// `aletheia.db.pre-restaurar` por si el usuario quiere volver atrás.
  static Future<bool> applyPendingIfAny(Directory dataDirectory) async {
    final sep = Platform.pathSeparator;
    final pending = Directory(
      '${dataDirectory.path}${sep}restore-pending',
    );
    final stagedDb = File('${pending.path}${sep}aletheia.db');
    if (!stagedDb.existsSync()) return false;
    final db = File('${dataDirectory.path}${sep}aletheia.db');
    // Copia de seguridad del estado actual.
    if (db.existsSync()) {
      final keep = Directory(
        '${dataDirectory.path}${sep}pre-restaurar',
      )..createSync(recursive: true);
      for (final suffix in const ['', '-wal', '-shm']) {
        final source = File('${db.path}$suffix');
        if (source.existsSync()) {
          source.copySync('${keep.path}${sep}aletheia.db$suffix');
        }
      }
    }
    // La base actual (con sus acompañantes) sale antes de mover el staging.
    for (final suffix in const ['', '-wal', '-shm']) {
      final existing = File('${db.path}$suffix');
      if (existing.existsSync()) existing.deleteSync();
    }
    for (final suffix in const ['', '-wal', '-shm']) {
      final source = File('${pending.path}${sep}aletheia.db$suffix');
      if (source.existsSync()) {
        source.renameSync('${db.path}$suffix');
      }
    }
    final stagedModules = File('${pending.path}${sep}modules.json');
    if (stagedModules.existsSync()) {
      final modulesDir = Directory(
        '${dataDirectory.path}${sep}modules',
      )..createSync(recursive: true);
      stagedModules.copySync(
        '${modulesDir.path}${sep}modules.json',
      );
    }
    pending.deleteSync(recursive: true);
    return true;
  }

  /// Copia de seguridad previa a una restauración (para «deshacer»).
  Directory? preRestoreDirectory() {
    final dir = Directory(
      '${dataDirectory.path}${Platform.pathSeparator}pre-restaurar',
    );
    return dir.existsSync() ? dir : null;
  }
}

class BackupSummary {
  const BackupSummary({
    required this.exportedAt,
    required this.appVersion,
    required this.includesModules,
  });

  final DateTime exportedAt;
  final String appVersion;
  final bool includesModules;
}

class BackupException implements Exception {
  BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}
