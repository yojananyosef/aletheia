/// Selección de la implementación de pantalla completa.
library;

export 'window_platform_stub.dart'
    if (dart.library.io) 'window_platform_io.dart'
    if (dart.library.js_interop) 'window_platform_web.dart';
