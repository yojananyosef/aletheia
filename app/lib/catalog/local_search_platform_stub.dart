import 'package:flutter/services.dart' show AssetBundle;
import 'package:sqlite3/common.dart';

Future<CommonDatabase> openLocalSearchDatabase({
  required AssetBundle bundle,
  Future<String> Function()? cacheDirectoryProvider,
}) {
  throw UnsupportedError(
    'El índice local no está disponible en esta plataforma.',
  );
}
