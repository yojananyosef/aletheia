/// Ventana de la aplicación (M3): Vista → Pantalla completa.
///
/// Aislado de `window_manager` para que las pruebas de widget (sin plugin) no
/// fallen: cualquier error de plataforma se traduce en «no disponible».
library;

import 'package:window_manager/window_manager.dart';

Future<bool> isWindowFullScreen() async {
  try {
    return await windowManager.isFullScreen();
  } catch (_) {
    return false;
  }
}

/// Alterna la pantalla completa. Devuelve el estado final (o el actual si la
/// plataforma no lo permite).
Future<bool> setWindowFullScreen(bool value) async {
  try {
    await windowManager.setFullScreen(value);
    return value;
  } catch (_) {
    return isWindowFullScreen();
  }
}
