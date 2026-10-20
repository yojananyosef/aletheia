import 'package:window_manager/window_manager.dart';

Future<bool> platformIsWindowFullScreen() async {
  try {
    return await windowManager.isFullScreen();
  } catch (_) {
    return false;
  }
}

/// Alterna la pantalla completa. Devuelve el estado final (o el actual si la
/// plataforma no lo permite).
Future<bool> platformSetWindowFullScreen(bool value) async {
  try {
    await windowManager.setFullScreen(value);
    return value;
  } catch (_) {
    return platformIsWindowFullScreen();
  }
}
