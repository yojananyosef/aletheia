import 'dart:io' show gzip;
import 'dart:typed_data';

Future<Uint8List> decompressGzip(Uint8List bytes) async {
  final decoded = gzip.decode(bytes);
  return decoded is Uint8List ? decoded : Uint8List.fromList(decoded);
}
