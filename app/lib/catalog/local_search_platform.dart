/// Apertura del índice FTS5 empaquetado en cada plataforma.
library;

export 'local_search_platform_stub.dart'
    if (dart.library.io) 'local_search_platform_io.dart'
    if (dart.library.js_interop) 'local_search_platform_web.dart';
