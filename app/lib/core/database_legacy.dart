/// Importación de los JSON heredados de M0–M4 (solo plataformas nativas).
library;

export 'database_legacy_stub.dart'
    if (dart.library.io) 'database_legacy_io.dart';
