/// Metadatos del recurso para los drawers del lector (M6.1).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'catalog_gateway.dart';
import 'catalog_models.dart';

/// Ficha del recurso (título, autores, licencia, estadísticas…) por id.
///
/// El lector no consulta la Biblioteca: pide aquí la ficha y el gateway
/// resuelve contra el servicio o los recursos empaquetados.
final resourceSummaryProvider =
    FutureProvider.family<ResourceSummary?, String>((ref, resourceId) async {
  final listing = await ref
      .watch(catalogGatewayProvider)
      .listResources(pageSize: 100, sort: 'title');
  for (final item in listing.items) {
    if (item.id == resourceId) return item;
  }
  return null;
});
