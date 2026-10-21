import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/catalog_client.dart';
import '../catalog/catalog_gateway.dart';
import '../catalog/catalog_models.dart';
import '../core/localization.dart';
import '../assistant/study_assistant_panel.dart';
import '../courses/courses_panel.dart';
import '../dashboard/dashboard_panel.dart';
import '../documents/documents_panel.dart';
import '../favorites/favorites_panel.dart';
import '../guides/guided_study_panel.dart';
import '../maps/visual_library_panel.dart';
import '../psalms/psalms_explorer_panel.dart';
import '../reading_plans/reading_plans_panel.dart';
import '../core/panel_meta.dart';
import '../core/theme.dart';
import '../notes/notes_panel.dart';
import '../reader/reader_panel.dart';
import '../search/search_panel.dart';
import '../store/store_panel.dart';
import 'catalog_resource_panel.dart';
import 'devotional_panel.dart';
import 'factbook_panel.dart';
import 'text_comparison_panel.dart';
import '../workspace/models.dart';
import '../workspace/workspace_controller.dart';

/// Host de paneles: lector (Biblia), Búsqueda, Notas, Ajustes, las
/// herramientas de M5 (Factbook, Comparación de textos y Devocional) y el
/// lector genérico de recursos (comentario/diccionario) son reales; el resto
/// son placeholders informativos.
class PanelHost extends StatelessWidget {
  const PanelHost({super.key, required this.tile, required this.tab});

  final WorkspaceTile tile;
  final WorkspaceTab tab;

  @override
  Widget build(BuildContext context) {
    return switch (tab.kind) {
      PanelKind.settings => SettingsPanel(tab: tab),
      PanelKind.dashboard => const DashboardPanel(),
      PanelKind.studyAssistant => const StudyAssistantPanel(),
      PanelKind.search => SearchPanel(tile: tile, tab: tab),
      PanelKind.store => const StorePanel(),
      PanelKind.notes => const NotesPanel(),
      PanelKind.bible => ReaderPanel(
        key: ValueKey(tab.id),
        tile: tile,
        tab: tab,
      ),
      PanelKind.factbook => FactbookPanel(tile: tile, tab: tab),
      PanelKind.textComparison => TextComparisonPanel(tile: tile, tab: tab),
      PanelKind.devotional => DevotionalPanel(tile: tile, tab: tab),
      PanelKind.resource => CatalogResourcePanel(tile: tile, tab: tab),
      PanelKind.guidedStudy => GuidedStudyPanel(tile: tile, tab: tab),
      PanelKind.readingPlans => const ReadingPlansPanel(),
      PanelKind.atlas => VisualLibraryPanel(
        mode: VisualLibraryMode.atlas,
        tile: tile,
        tab: tab,
      ),
      PanelKind.media => VisualLibraryPanel(
        mode: VisualLibraryMode.media,
        tile: tile,
        tab: tab,
      ),
      PanelKind.courses => CoursesPanel(tile: tile, tab: tab),
      PanelKind.documents => DocumentsPanel(tile: tile, tab: tab),
      PanelKind.favorites => const FavoritesPanel(),
      PanelKind.psalmsExplorer => const PsalmsExplorerPanel(),
      _ => PlaceholderPanel(tab: tab),
    };
  }
}

class PlaceholderPanel extends ConsumerWidget {
  const PlaceholderPanel({super.key, required this.tab});

  final WorkspaceTab tab;

  String _description(AppLocalizations l10n) => switch (tab.kind) {
    PanelKind.dashboard => l10n.placeholderDashboard,
    PanelKind.library => l10n.placeholderLibrary,
    PanelKind.store => l10n.placeholderStore,
    PanelKind.resource => l10n.placeholderResource,
    PanelKind.studyAssistant => l10n.placeholderStudyAssistant,
    PanelKind.factbook => l10n.placeholderFactbook,
    PanelKind.guidedStudy => l10n.placeholderGuidedStudy,
    PanelKind.tools => l10n.placeholderTools,
    PanelKind.textComparison => l10n.placeholderTextComparison,
    PanelKind.devotional => l10n.placeholderDevotional,
    _ => l10n.placeholderFallback,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final dashboard = tab.kind == PanelKind.dashboard;
    final showBanner = ref.watch(workspaceProvider).bannerVisible;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconForKind(tab.kind), size: 38, color: kTextSecondary),
            const SizedBox(height: 14),
            Text(
              tabTitle(context, tab),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _description(l10n),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: kTextSecondary,
                height: 1.45,
              ),
            ),
            // Banner del panel de inicio (Ajustes 8.3, primera fila del
            // original): en el clon es una tarjeta dentro del inicio.
            if (dashboard && showBanner) ...[
              const SizedBox(height: 18),
              Container(
                key: const ValueKey('dashboard-banner'),
                padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                decoration: BoxDecoration(
                  color: kBannerBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.bannerDev,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 13,
                        tooltip: l10n.bannerClose,
                        onPressed: () => ref
                            .read(workspaceProvider.notifier)
                            .setBannerVisible(false),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ajustes (M3): réplica de las filas del original (aplicación, banners,
// idioma, citas, vista limitada) más la sección propia del catálogo (M2).
class SettingsPanel extends ConsumerStatefulWidget {
  const SettingsPanel({super.key, required this.tab});

  final WorkspaceTab tab;

  @override
  ConsumerState<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends ConsumerState<SettingsPanel> {
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(
      text: ref.read(workspaceProvider).catalogUrl,
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _applyCatalogUrl() {
    ref
        .read(workspaceProvider.notifier)
        .setCatalogSettings(url: _urlController.text);
    ref.invalidate(catalogHealthProvider);
  }

  void _resetDefaults() {
    ref.read(workspaceProvider.notifier).resetSettings();
    _urlController.text = ref.read(workspaceProvider).catalogUrl;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(context.l10n.settingsResetDone),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(workspaceProvider);
    final ctrl = ref.read(workspaceProvider.notifier);
    final health = ref.watch(catalogHealthProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      children: [
        Row(
          children: [
            TextButton(
              key: const ValueKey('settings-reset'),
              onPressed: _resetDefaults,
              child: Text(
                l10n.settingsReset,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const Spacer(),
            PopupMenuButton<String>(
              key: const ValueKey('settings-menu'),
              tooltip: l10n.moreOptions,
              position: PopupMenuPosition.under,
              onSelected: (value) {
                if (value == 'reset') _resetDefaults();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'reset',
                  height: 34,
                  child: Text(
                    l10n.settingsReset,
                    style: const TextStyle(fontSize: 13.5),
                  ),
                ),
              ],
              child: Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.more_vert, size: 17, color: kTextSecondary),
              ),
            ),
          ],
        ),
        const Divider(height: 1),
        const SizedBox(height: 6),
        _ChoiceRow(
          label: l10n.settingsToolbarLocation,
          keyValue: 'settings-toolbar-location',
          value: state.toolbarLocation,
          options: {
            'left': l10n.settingsToolbarLeft,
            'top': l10n.settingsToolbarTop,
          },
          onChanged: ctrl.setToolbarLocation,
        ),
        _YesNoRow(
          label: l10n.settingsQuickActions,
          value: state.quickActionsVisible,
          onChanged: ctrl.setQuickActionsVisible,
          keyValue: 'settings-quick-actions',
        ),
        _YesNoRow(
          label: l10n.settingsBannersDashboard,
          value: state.bannerVisible,
          onChanged: ctrl.setBannerVisible,
          keyValue: 'settings-banners-dashboard',
          help: l10n.settingsBannersDashboardHelp,
        ),
        _YesNoRow(
          label: l10n.settingsBannersLayout,
          value: state.layoutBannersVisible,
          onChanged: ctrl.setLayoutBannersVisible,
          keyValue: 'settings-banners-layout',
          help: l10n.settingsBannersLayoutHelp,
        ),
        _YesNoRow(
          label: l10n.settingsLimitedView,
          value: state.limitedView,
          onChanged: ctrl.setLimitedView,
          keyValue: 'settings-limited-view',
          help: l10n.settingsLimitedViewHelp,
        ),
        _DropdownRow(
          label: l10n.settingsLanguage,
          keyValue: 'settings-language',
          value: state.locale,
          options: {
            'system': l10n.settingsLanguageSystem,
            'es': 'Español',
            'en': 'English',
          },
          onChanged: ctrl.setLocale,
        ),
        _DropdownRow(
          label: l10n.settingsTheme,
          keyValue: 'settings-theme',
          help: l10n.settingsThemeHelp,
          value: state.themeMode,
          options: {
            'system': l10n.settingsThemeSystem,
            'light': l10n.settingsThemeLight,
            'dark': l10n.settingsThemeDark,
          },
          onChanged: ctrl.setThemeMode,
        ),
        _DropdownRow(
          label: l10n.settingsCitationStyle,
          keyValue: 'settings-citation-style',
          help: l10n.settingsCitationHelp,
          value: state.citationStyle,
          options: {
            'turabian': l10n.citationTurabian,
            'sbl': l10n.citationSbl,
            'chicago': l10n.citationChicago,
            'plain': l10n.citationPlain,
          },
          onChanged: (value) => ctrl.setCitationSettings(style: value),
        ),
        _YesNoRow(
          label: l10n.settingsCopyCitations,
          value: state.copyCitations,
          onChanged: (value) => ctrl.setCitationSettings(copy: value),
          keyValue: 'settings-copy-citations',
          help: l10n.settingsCopyHelp,
        ),
        _YesNoRow(
          label: l10n.settingsHyperlinkCitations,
          value: state.hyperlinkCitations,
          onChanged: (value) => ctrl.setCitationSettings(hyperlink: value),
          keyValue: 'settings-hyperlink-citations',
          help: l10n.settingsHyperlinkHelp,
        ),
        const Divider(height: 26),
        _SectionTitle(l10n.settingsCatalog),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('settings-catalog-url'),
                controller: _urlController,
                onSubmitted: (_) => _applyCatalogUrl(),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  labelText: l10n.settingsServiceUrl,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              key: const ValueKey('settings-catalog-apply'),
              onPressed: _applyCatalogUrl,
              child: Text(
                l10n.settingsApply,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SegmentedButton<String>(
          key: const ValueKey('settings-catalog-mode'),
          segments: [
            ButtonSegment(
              value: 'auto',
              label: Text(
                l10n.settingsCatalogModeAuto,
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
            ButtonSegment(
              value: 'local',
              label: Text(
                l10n.settingsCatalogModeLocal,
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
            ButtonSegment(
              value: 'remote',
              label: Text(
                l10n.settingsCatalogModeRemote,
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
          ],
          selected: {state.catalogMode},
          onSelectionChanged: (selection) {
            ctrl.setCatalogSettings(mode: selection.first);
            ref.invalidate(catalogHealthProvider);
          },
        ),
        const SizedBox(height: 8),
        _CatalogStatus(health: health),
        const SizedBox(height: 10),
      ],
    );
  }
}

/// Fila de Ajustes: etiqueta + control a la derecha (con «?» opcional), como
/// el original.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.child, this.help});

  final String label;
  final Widget child;
  final String? help;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13.5),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (help != null)
              Tooltip(
                message: help!,
                child: Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.help_outline,
                    size: 15,
                    color: kTextSecondary,
                  ),
                ),
              ),
            // El control no encoge solo: en paneles estrechos se escala para
            // que nunca desborde la fila.
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.7),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YesNoRow extends StatelessWidget {
  const _YesNoRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.keyValue,
    this.help,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String keyValue;
  final String? help;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _Row(
      label: label,
      help: help,
      child: SegmentedButton<bool>(
        key: ValueKey(keyValue),
        showSelectedIcon: false,
        style: const ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        segments: [
          ButtonSegment(
            value: true,
            label: Text(l10n.yes, style: const TextStyle(fontSize: 12.5)),
          ),
          ButtonSegment(
            value: false,
            label: Text(l10n.no, style: const TextStyle(fontSize: 12.5)),
          ),
        ],
        selected: {value},
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.keyValue,
  });

  final String label;
  final String value;

  /// `valor → etiqueta` (el orden se conserva).
  final Map<String, String> options;
  final ValueChanged<String> onChanged;
  final String keyValue;

  @override
  Widget build(BuildContext context) {
    return _Row(
      label: label,
      child: SegmentedButton<String>(
        key: ValueKey(keyValue),
        showSelectedIcon: false,
        style: const ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        segments: [
          for (final entry in options.entries)
            ButtonSegment(
              value: entry.key,
              label: Text(entry.value, style: const TextStyle(fontSize: 12.5)),
            ),
        ],
        selected: {options.containsKey(value) ? value : options.keys.first},
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}

/// Fila de Ajustes con desplegable (Idioma, Estilo de citas), como el
/// original.
class _DropdownRow extends StatelessWidget {
  const _DropdownRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.keyValue,
    this.help,
  });

  final String label;
  final String value;

  /// `valor → etiqueta` (el orden se conserva).
  final Map<String, String> options;
  final ValueChanged<String> onChanged;
  final String keyValue;
  final String? help;

  @override
  Widget build(BuildContext context) {
    return _Row(
      label: label,
      help: help,
      child: DropdownButton<String>(
        key: ValueKey(keyValue),
        value: options.containsKey(value) ? value : options.keys.first,
        isDense: true,
        borderRadius: BorderRadius.circular(6),
        underline: const SizedBox.shrink(),
        icon: Icon(Icons.arrow_drop_down, size: 18, color: kTextSecondary),
        style: TextStyle(fontSize: 13, color: kTextPrimary),
        items: [
          for (final entry in options.entries)
            DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value, style: const TextStyle(fontSize: 13)),
            ),
        ],
        onChanged: (selection) {
          if (selection != null) onChanged(selection);
        },
      ),
    );
  }
}

class _CatalogStatus extends ConsumerWidget {
  const _CatalogStatus({required this.health});

  final AsyncValue<CatalogHealth?> health;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final (icon, color, message) = health.when(
      loading: () =>
          (Icons.hourglass_empty, kTextSecondary, l10n.settingsChecking),
      error: (error, _) => (
        Icons.cloud_off,
        kTextSecondary,
        l10n.settingsOfflineError('$error'),
      ),
      data: (value) => value == null
          ? (Icons.cloud_off, kTextSecondary, l10n.settingsOffline)
          : value.local
          ? (
              Icons.offline_bolt_outlined,
              Colors.green.shade700,
              l10n.settingsLocalReady(
                value.resources,
                formatCount(value.verses),
                formatCount(value.sections),
              ),
            )
          : (
              Icons.cloud_done,
              Colors.green.shade700,
              l10n.settingsOnline(
                value.resources,
                formatCount(value.verses),
                formatCount(value.sections),
              ),
            ),
    );

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 7),
        Expanded(
          child: Text(message, style: TextStyle(fontSize: 12.5, color: color)),
        ),
        IconButton(
          key: const ValueKey('settings-catalog-refresh'),
          iconSize: 16,
          tooltip: l10n.settingsRecheck,
          onPressed: () => ref.invalidate(catalogHealthProvider),
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: kTextSecondary,
        ),
      ),
    );
  }
}
