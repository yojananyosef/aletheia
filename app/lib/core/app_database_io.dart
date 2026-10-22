import 'dart:io' show Directory;

import 'package:path_provider/path_provider.dart';

import 'database.dart';

/// Abre la base en el directorio de datos de la app e importa los JSON de
/// versiones anteriores.
Future<AletheiaDatabase> openAppDatabase() async {
  final dir = await getApplicationSupportDirectory();
  final database = AletheiaDatabase.open('${dir.path}/aletheia.db');
  await AletheiaDatabase.importLegacyJson(database, dir);
  return database;
}

/// Directorio de datos de la app (el mismo que usa la base) para guardar a
/// su lado los módulos del catálogo desacoplado.
Future<Directory> openAppSupportDirectory() => getApplicationSupportDirectory();
