import 'dart:io' show Directory;

import 'package:path_provider/path_provider.dart';

import 'app_backup.dart';
import 'database.dart';

/// Abre la base en el directorio de datos de la app e importa los JSON de
/// versiones anteriores. Si hay un respaldo pendiente de aplicar
/// (Ajustes ▸ Restaurar), se aplica antes de abrir.
Future<AletheiaDatabase> openAppDatabase() async {
  final dir = await getApplicationSupportDirectory();
  await AppBackup.applyPendingIfAny(dir);
  final database = AletheiaDatabase.open('${dir.path}/aletheia.db');
  await AletheiaDatabase.importLegacyJson(database, dir);
  return database;
}

/// Directorio de datos de la app (el mismo que usa la base) para guardar a
/// su lado los módulos del catálogo desacoplado.
Future<Directory> openAppSupportDirectory() => getApplicationSupportDirectory();
