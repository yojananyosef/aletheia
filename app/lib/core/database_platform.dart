/// Selección de la implementación nativa de SQLite.
library;

export 'database_platform_stub.dart'
    if (dart.library.io) 'database_platform_io.dart';
