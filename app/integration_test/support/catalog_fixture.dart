/// Fixture del catálogo para los flows de integración.
///
/// El bundle de la app ya no lleva todo el contenido (catálogo desacoplado):
/// los flows de integración inyectan la fuente de disco con la copia íntegra
/// de `app/assets/catalog`, igual que leerá la app un módulo instalado. Así
/// las pruebas no dependen de red ni de instalar módulos reales.
library;

import 'dart:io';

import 'package:aletheia/catalog/catalog_source_providers.dart';
import 'package:aletheia/catalog/install/disk_catalog_source.dart';

/// Override para el `ProviderScope` de cada flow.
final catalogDiskOverride = catalogAssetSourceProvider.overrideWithValue(
  DiskCatalogSource(
    baseDirectory:
        '${Directory.current.absolute.path}${Platform.pathSeparator}'
        'assets${Platform.pathSeparator}catalog',
  ),
);
