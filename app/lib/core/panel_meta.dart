import 'package:flutter/material.dart';

import '../core/localization.dart';
import '../workspace/models.dart';

/// Icono de sidebar/pestaña por tipo de panel.
IconData iconForKind(PanelKind kind) => switch (kind) {
  PanelKind.dashboard => Icons.space_dashboard_outlined,
  PanelKind.library => Icons.local_library_outlined,
  PanelKind.store => Icons.storefront_outlined,
  PanelKind.search => Icons.search,
  PanelKind.bible => Icons.menu_book_outlined,
  PanelKind.resource => Icons.auto_stories_outlined,
  PanelKind.studyAssistant => Icons.smart_toy_outlined,
  PanelKind.factbook => Icons.fact_check_outlined,
  PanelKind.guidedStudy => Icons.explore_outlined,
  PanelKind.notes => Icons.sticky_note_2_outlined,
  PanelKind.readingPlans => Icons.calendar_month_outlined,
  PanelKind.tools => Icons.grid_view_outlined,
  PanelKind.atlas => Icons.public,
  PanelKind.courses => Icons.school_outlined,
  PanelKind.documents => Icons.description_outlined,
  PanelKind.media => Icons.perm_media_outlined,
  PanelKind.favorites => Icons.star_outline,
  PanelKind.psalmsExplorer => Icons.music_note_outlined,
  PanelKind.textComparison => Icons.compare_arrows,
  PanelKind.devotional => Icons.wb_twilight,
  PanelKind.settings => Icons.settings_outlined,
};

/// Título traducido de un tipo de panel: se usa cuando la pestaña no guarda
/// uno propio (las herramientas del original se llaman igual en cualquier
/// idioma, así que no se persiste texto fijo).
String panelKindTitle(AppLocalizations l10n, PanelKind kind) => switch (kind) {
  PanelKind.dashboard => l10n.panelTitleDashboard,
  PanelKind.library => l10n.panelTitleLibrary,
  PanelKind.store => l10n.panelTitleStore,
  PanelKind.search => l10n.panelTitleSearch,
  PanelKind.bible => l10n.panelTitleBible,
  PanelKind.resource => l10n.panelTitleResource,
  PanelKind.studyAssistant => l10n.panelTitleStudyAssistant,
  PanelKind.factbook => l10n.panelTitleFactbook,
  PanelKind.guidedStudy => l10n.panelTitleGuidedStudy,
  PanelKind.notes => l10n.panelTitleNotes,
  PanelKind.readingPlans => l10n.panelTitleReadingPlans,
  PanelKind.tools => l10n.panelTitleTools,
  PanelKind.atlas => l10n.panelTitleAtlas,
  PanelKind.courses => l10n.panelTitleCourses,
  PanelKind.documents => l10n.panelTitleDocuments,
  PanelKind.media => l10n.panelTitleMedia,
  PanelKind.favorites => l10n.panelTitleFavorites,
  PanelKind.psalmsExplorer => l10n.panelTitlePsalms,
  PanelKind.textComparison => l10n.panelTitleTextComparison,
  PanelKind.devotional => l10n.panelTitleDevotional,
  PanelKind.settings => l10n.panelTitleSettings,
};

/// Título traducido de un tipo de recurso abierto como panel genérico
/// (acciones rápidas); `null` si el tipo no tiene nombre propio.
String? resourceTypeTitle(AppLocalizations l10n, String resourceType) =>
    switch (resourceType) {
      'commentary' => l10n.resourceTitleCommentary,
      'studyBible' => l10n.resourceTitleStudyBible,
      'dictionary' => l10n.resourceTitleDictionary,
      _ => null,
    };

/// Título visible de una pestaña (el suyo o el del tipo traducido).
String tabTitle(BuildContext context, WorkspaceTab tab) {
  if (tab.title.isNotEmpty) return tab.title;
  final l10n = context.l10n;
  final type = tab.resourceType;
  if (tab.kind == PanelKind.resource && type != null) {
    final title = resourceTypeTitle(l10n, type);
    if (title != null) return title;
  }
  return panelKindTitle(l10n, tab.kind);
}
