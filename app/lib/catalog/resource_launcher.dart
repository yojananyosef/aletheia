import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../workspace/models.dart';
import '../workspace/workspace_controller.dart';
import 'catalog_models.dart';

/// Abre (o reactiva) un recurso del catálogo en el workspace.
///
/// Biblioteca, Tienda local y otros puntos de entrada comparten esta regla:
/// una Biblia abre el lector, Factbook/devocional sus paneles y el resto el
/// lector genérico de recursos.
void openCatalogResource(WidgetRef ref, ResourceSummary resource) {
  final ctrl = ref.read(workspaceProvider.notifier);
  if (ctrl.revealResourceTab(resource.id)) return;
  final kind = resource.isBible
      ? PanelKind.bible
      : switch (resource.type) {
          'factbook' => PanelKind.factbook,
          'devotional' => PanelKind.devotional,
          _ => PanelKind.resource,
        };
  ctrl.openTab(
    TabSpec(
      kind: kind,
      title: resource.isBible
          ? (resource.abbrev ?? resource.title)
          : resource.title,
      reference: resource.isBible ? 'GEN.1.1' : null,
      resourceId: resource.id,
      resourceType: resource.type,
    ),
  );
}
