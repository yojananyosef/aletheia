import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<bool> platformIsWindowFullScreen() async =>
    web.document.fullscreenElement != null;

Future<bool> platformSetWindowFullScreen(bool value) async {
  try {
    if (value) {
      final element = web.document.documentElement;
      if (element != null) await element.requestFullscreen().toDart;
    } else if (web.document.fullscreenElement != null) {
      await web.document.exitFullscreen().toDart;
    }
  } catch (_) {
    // El navegador puede rechazar la petición si no hay gesto de usuario.
  }
  return platformIsWindowFullScreen();
}
