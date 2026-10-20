/// Ventana de la aplicación (M3): Vista → Pantalla completa.
///
/// La implementación nativa usa `window_manager`; la web usa la API
/// `Fullscreen` del navegador. Cualquier error de plataforma se traduce en
/// «no disponible» para no romper la UI.
library;

import 'window_platform.dart';

Future<bool> isWindowFullScreen() => platformIsWindowFullScreen();

/// Alterna la pantalla completa. Devuelve el estado final (o el actual si la
/// plataforma no lo permite).
Future<bool> setWindowFullScreen(bool value) =>
    platformSetWindowFullScreen(value);
