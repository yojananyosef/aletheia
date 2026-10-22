import 'dart:io' show Directory;

import 'database.dart';

Future<AletheiaDatabase> openAppDatabase() {
  throw UnsupportedError('Plataforma no soportada por Aletheia.');
}

Future<Directory> openAppSupportDirectory() {
  throw UnsupportedError('Plataforma no soportada por Aletheia.');
}
