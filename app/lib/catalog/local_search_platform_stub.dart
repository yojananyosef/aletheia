import 'package:sqlite3/common.dart';

import 'catalog_asset_source.dart';

/// Plataformas sin SQLite nativo ni WASM (no debería alcanzarse).
Future<CommonDatabase> openLocalSearchDatabase({
  required CatalogAssetSource source,
  Future<String> Function()? cacheDirectoryProvider,
}) {
  throw UnsupportedError('La búsqueda FTS5 no está disponible aquí.');
}
