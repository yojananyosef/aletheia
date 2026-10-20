/// Descompresión gzip con la implementación adecuada a cada plataforma.
library;

export 'gzip_stub.dart'
    if (dart.library.io) 'gzip_io.dart'
    if (dart.library.js_interop) 'gzip_web.dart';
