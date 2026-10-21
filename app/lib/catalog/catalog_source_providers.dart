/// Selección de la fuente del catálogo según la plataforma.
library;

import 'package:flutter/foundation.dart' show ValueNotifier, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'catalog_asset_source.dart';
import 'mods_catalog_source.dart';

/// En web el catálogo se descarga de `aletheia-mods`; en escritorio se sigue
/// usando el catálogo empaquetado (que también permite trabajar sin red).
final modsCatalogSourceProvider = Provider<ModsCatalogSource?>((ref) {
  if (!kIsWeb) return null;
  final source = ModsCatalogSource();
  ref.onDispose(source.dispose);
  return source;
});

/// Fuente que usan el lector, la búsqueda y las secciones.
///
/// En web intenta primero el repositorio remoto y conserva la RV1909 y los
/// metadatos pequeños empaquetados como respaldo inmediato.
final catalogAssetSourceProvider = Provider<CatalogAssetSource>((ref) {
  final mods = ref.watch(modsCatalogSourceProvider);
  if (mods == null) return AssetCatalogSource();
  return FallbackCatalogSource(primary: mods, fallback: AssetCatalogSource());
});

/// Progreso de la descarga del índice, o `null` cuando no hay una activa.
final catalogTransferProvider = Provider<ValueNotifier<CatalogTransfer?>?>(
  (ref) => ref.watch(modsCatalogSourceProvider)?.transfer,
);
