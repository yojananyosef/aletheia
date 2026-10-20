/// Apertura de la base de datos de la aplicación en cada plataforma.
library;

export 'app_database_stub.dart'
    if (dart.library.io) 'app_database_io.dart'
    if (dart.library.js_interop) 'app_database_web.dart';
