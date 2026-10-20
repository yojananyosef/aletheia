import 'package:sqlite3/wasm.dart';

WasmSqlite3? _instance;

/// Carga una única instancia del binario `sqlite3.wasm` para toda la sesión.
///
/// El archivo se copia desde el release de `package:sqlite3` a `web/` y se
/// sirve junto a la aplicación. La ruta es relativa al documento para que
/// funcione tanto en la raíz como bajo `/aletheia/` en GitHub Pages.
Future<WasmSqlite3> loadWebSqlite() async {
  final existing = _instance;
  if (existing != null) return existing;

  final sqlite = await WasmSqlite3.loadFromUrl(
    Uri.base.resolve('sqlite3.wasm'),
  );
  return _instance = sqlite;
}
