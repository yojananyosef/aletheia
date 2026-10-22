/// Catálogo real para pruebas: se lee del repositorio en disco.
///
/// El bundle de la app ya no lleva todo el contenido (catálogo desacoplado
/// con módulos instalables), pero la copia íntegra sigue en
/// `app/assets/catalog` para construir `aletheia-mods`. Los tests de
/// contenido apuntan ahí con [DiskCatalogSource], exactamente como leerá la
/// app un módulo instalado.
library;

import 'dart:io';

import 'package:aletheia/catalog/catalog_client.dart';
import 'package:aletheia/catalog/catalog_gateway.dart';
import 'package:aletheia/catalog/document_repository.dart';
import 'package:aletheia/catalog/install/disk_catalog_source.dart';
import 'package:aletheia/catalog/sections_repository.dart';

/// Carpeta `app/assets/catalog` del repositorio (el cwd de los tests es
/// `app/`, así que la ruta relativa basta).
final kRepoCatalogPath = '${Directory.current.absolute.path}/assets/catalog';

/// Fuente de disco con TODO el catálogo (como un módulo ya instalado).
DiskCatalogSource repoCatalogSource() =>
    DiskCatalogSource(baseDirectory: kRepoCatalogPath);

/// Repositorio de documentos sobre el catálogo completo del repositorio.
AssetDocumentRepository repoDocumentRepository() =>
    AssetDocumentRepository(source: repoCatalogSource());

/// Repositorio de secciones sobre el catálogo completo del repositorio.
AssetSectionsRepository repoSectionsRepository() =>
    AssetSectionsRepository(source: repoCatalogSource());

/// Gateway local con el catálogo completo del repositorio.
CatalogGateway repoLocalGateway() => CatalogGateway(
  mode: 'local',
  client: CatalogClient(baseUrl: 'http://127.0.0.1:1'),
  source: repoCatalogSource(),
);
