import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Descomprime usando la API nativa del navegador (`DecompressionStream`),
/// que evita cargar un decodificador gzip en JavaScript.
Future<Uint8List> decompressGzip(Uint8List bytes) async {
  final decompressor = web.DecompressionStream('gzip');
  final stream = web.Blob(<JSAny>[bytes.toJS].toJS).stream().pipeThrough(
    web.ReadableWritablePair(
      readable: decompressor.readable,
      writable: decompressor.writable,
    ),
  );
  final buffer = await web.Response(stream).arrayBuffer().toDart;
  return buffer.toDart.asUint8List();
}
