/// Registro local de fallos (sin telemetría): captura errores no controlados
/// del framework y de la zona de la app en archivos rotativos bajo el
/// directorio de datos, para que el usuario pueda exportarlos desde Ajustes.
///
/// Sólo escritorio: en web los errores quedan en la consola del navegador.
library;

import 'dart:async';
import 'dart:io' show Directory, File, FileMode, Platform;
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show FlutterError, kIsWeb;

/// Escribe líneas de diagnóstico en un archivo rotativo.
///
/// Inyectable para las pruebas (la rotación y el tamaño son verificables).
class CrashLog {
  CrashLog({required this.resolveFile, this.maxBytes = 256 * 1024});

  /// Resuelve el archivo destino (p. ej. `<datos>/crash.log`).
  final Future<File> Function() resolveFile;

  /// Tamaño máximo por archivo; al superarlo se rota a `.1` (una copia).
  final int maxBytes;

  /// Instala los ganchos globales de error (framework y zona) y devuelve el
  /// registro; en web devuelve null y no toca los ganchos.
  static CrashLog? install({required Future<Directory> Function() resolveDir}) {
    if (kIsWeb) return null;
    final log = CrashLog(resolveFile: () async {
      final dir = await resolveDir();
      return File('${dir.path}${Platform.pathSeparator}crash.log');
    });
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      log.record(
        'FlutterError',
        details.exception,
        details.stack,
        context: details.context?.toDescription(),
      );
      previous?.call(details);
    };
    final previousDispatcher = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      log.record('Zone', error, stack);
      return previousDispatcher?.call(error, stack) ?? false;
    };
    return log;
  }

  Future<void> record(
    String source,
    Object error,
    StackTrace? stack, {
    String? context,
  }) async {
    try {
      final file = await resolveFile();
      await file.parent.create(recursive: true);
      await _rotateIfLarge(file);
      final buffer = StringBuffer()
        ..write('=== ')
        ..write(DateTime.now().toIso8601String())
        ..write(' · ')
        ..write(source)
        ..writeln(' ===');
      if (context != null && context.isNotEmpty) {
        buffer.writeln('contexto: $context');
      }
      buffer.writeln(error);
      if (stack != null) buffer.writeln(stack);
      buffer.writeln();
      await file.writeAsString(buffer.toString(), mode: FileMode.append);
    } on Object {
      // Nunca romper la app por un fallo del propio registro.
    }
  }

  Future<void> _rotateIfLarge(File file) async {
    try {
      if (!await file.exists()) return;
      if (await file.length() < maxBytes) return;
      final previous = File('${file.path}.1');
      await previous.writeAsBytes(await file.readAsBytes(), flush: true);
      await file.delete();
    } on Object {
      // La rotación es best-effort.
    }
  }

  /// Contenido del registro (o null si no hay nada).
  Future<String?> read() async {
    final file = await resolveFile();
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  /// Borra el registro y su rotación anterior.
  Future<void> clear() async {
    final file = await resolveFile();
    for (final target in [file, File('${file.path}.1')]) {
      if (await target.exists()) await target.delete();
    }
  }
}
