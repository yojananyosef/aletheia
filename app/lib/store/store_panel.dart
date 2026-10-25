/// Tienda del catálogo desacoplado: módulos instalables con un tap.
///
/// El catálogo entero vive en `aletheia-mods`; la app solo empaqueta lo
/// esencial (RV1909 y el léxico). Aquí el usuario decide qué instalar: cada
/// tarjeta descarga sus archivos con progreso y cancelación (sha256
/// verificado), y una vez instalada la lectura sale de disco sin red.
///
/// En web no hay módulos instalables (el service worker cachea al usar), así
/// que la Tienda queda en modo descubrimiento con el botón «Abrir».
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/catalog_gateway.dart';
import '../catalog/catalog_models.dart';
import '../catalog/catalog_source_providers.dart';
import '../catalog/install/mods_manifest.dart';
import '../catalog/install/modules_store.dart';
import '../catalog/install/routing_catalog_source.dart'
    show kBundledCatalogModules;
import '../catalog/resource_launcher.dart';
import '../core/localization.dart';
import '../core/resource_colors.dart';
import '../core/theme.dart';
import '../library/library_overlay.dart';

class StorePanel extends ConsumerStatefulWidget {
  const StorePanel({super.key});

  @override
  ConsumerState<StorePanel> createState() => _StorePanelState();
}

class _StorePanelState extends ConsumerState<StorePanel> {
  final _findController = TextEditingController();
  String _query = '';
  String? _type;
  String? _subject;
  String? _publisher;
  List<ResourceSummary>? _resources;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _findController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final listing = await ref
          .read(catalogGatewayProvider)
          .listResources(sort: 'title', pageSize: 100);
      if (!mounted) return;
      setState(() {
        _resources = listing.items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  List<ResourceSummary> get _visible {
    final query = _query.trim().toLowerCase();
    return [
      for (final resource in _resources ?? const <ResourceSummary>[])
        if ((_type == null || resource.type == _type) &&
            (_subject == null ||
                (resource.tags.isNotEmpty && resource.tags.first == _subject)) &&
            (_publisher == null || resource.publisher == _publisher) &&
            (query.isEmpty ||
                resource.title.toLowerCase().contains(query) ||
                (resource.subtitle ?? '').toLowerCase().contains(query) ||
                resource.authorsLabel.toLowerCase().contains(query) ||
                resource.id.toLowerCase().contains(query)))
          resource,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = context.l10nLang;
    final total = _resources?.length ?? 0;
    final types = {
      for (final resource in _resources ?? const <ResourceSummary>[])
        resource.type,
    }.toList()..sort();
    final subjects = {
      for (final resource in _resources ?? const <ResourceSummary>[])
        if (resource.tags.isNotEmpty) resource.tags.first,
    }.toList()..sort();
    final publishers = {
      for (final resource in _resources ?? const <ResourceSummary>[])
        if (resource.publisher != null && resource.publisher!.isNotEmpty)
          resource.publisher!,
    }.toList()..sort();

    return Container(
      key: const ValueKey('store-panel'),
      color: kPanelBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: kAccent.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.storefront_outlined,
                    size: 22,
                    color: kAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.storeTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.storeIntro,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (!_loading && _error == null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.storeCount(total),
                      key: const ValueKey('store-count'),
                      style: const TextStyle(fontSize: 11.5, color: kAccent),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const ValueKey('store-search'),
                        controller: _findController,
                        onChanged: (value) => setState(() => _query = value),
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: l10n.storeSearch,
                          prefixIcon: const Icon(Icons.search, size: 18),
                          isDense: true,
                          filled: true,
                          fillColor: kFieldFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: l10n.libraryClear,
                                  iconSize: 14,
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _findController.clear();
                                    setState(() => _query = '');
                                  },
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      key: const ValueKey('store-open-library'),
                      tooltip: l10n.storeOpenLibrary,
                      onPressed: () => ref
                          .read(libraryOverlayVisibleProvider.notifier)
                          .open(),
                      icon: const Icon(
                        Icons.local_library_outlined,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    PopupMenuButton<String>(
                      key: const ValueKey('store-type-filter'),
                      tooltip: l10n.storeAllTypes,
                      onSelected: (value) =>
                          setState(() => _type = value == 'all' ? null : value),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'all',
                          child: Text(
                            l10n.storeAllTypes,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        for (final type in types)
                          PopupMenuItem(
                            value: type,
                            child: Text(
                              resourceTypeLabel(type, lang: lang),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                      ],
                      child: _storeFilterChip(
                        label: _type == null
                            ? l10n.storeAllTypes
                            : resourceTypeLabel(_type!, lang: lang),
                      ),
                    ),
                    PopupMenuButton<String>(
                      key: const ValueKey('store-subject-filter'),
                      tooltip: l10n.storeAllSubjects,
                      onSelected: (value) =>
                          setState(() => _subject = value == 'all' ? null : value),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'all',
                          child: Text(
                            l10n.storeAllSubjects,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        for (final subject in subjects)
                          PopupMenuItem(
                            value: subject,
                            child: Text(
                              subject,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                      ],
                      child: _storeFilterChip(
                        label: _subject == null
                            ? l10n.storeAllSubjects
                            : _subject!,
                      ),
                    ),
                    PopupMenuButton<String>(
                      key: const ValueKey('store-publisher-filter'),
                      tooltip: l10n.storeAllPublishers,
                      onSelected: (value) => setState(
                        () => _publisher = value == 'all' ? null : value,
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'all',
                          child: Text(
                            l10n.storeAllPublishers,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        for (final publisher in publishers)
                          PopupMenuItem(
                            value: publisher,
                            child: Text(
                              publisher,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                      ],
                      child: _storeFilterChip(
                        label: _publisher == null
                            ? l10n.storeAllPublishers
                            : _publisher!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildBody(l10n, lang)),
        ],
      ),
    );
  }

  /// Chip desplegable de faceta de la tienda (tipo / tema / editorial).
  Widget _storeFilterChip({required String label}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(
      color: kFieldFill,
      borderRadius: BorderRadius.circular(7),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 190),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.5, color: kTextPrimary),
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.arrow_drop_down, size: 17),
      ],
    ),
  );

  Widget _buildBody(AppLocalizations l10n, String lang) {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 30, color: kTextSecondary),
            const SizedBox(height: 10),
            Text(
              l10n.storeError,
              style: TextStyle(fontSize: 13, color: kTextSecondary),
            ),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: _load, child: Text(l10n.storeRetry)),
          ],
        ),
      );
    }
    final items = _visible;
    if (items.isEmpty) {
      return Center(
        child: Text(
          l10n.storeEmpty,
          style: TextStyle(fontSize: 13, color: kTextSecondary),
        ),
      );
    }
    final store = ref.watch(modulesStoreProvider);
    return ListView.separated(
      key: const ValueKey('store-list'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: items.length + (store == null ? 0 : 1),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (store != null && index == 0) {
          // El índice de búsqueda es un módulo más del catálogo.
          return const _SearchModuleCard();
        }
        final resource = items[index - (store == null ? 0 : 1)];
        return _StoreCard(resource: resource, lang: lang);
      },
    );
  }
}

class _StoreCard extends ConsumerWidget {
  const _StoreCard({required this.resource, required this.lang});

  final ResourceSummary resource;
  final String lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final accent = resourceColorFor(resource.id, resourceType: resource.type);
    final detail = [
      resourceTypeLabel(resource.type, lang: lang),
      if (resource.language.isNotEmpty)
        languageLabel(resource.language, lang: lang),
      if (resource.authorsLabel.isNotEmpty) resource.authorsLabel,
    ].join(' · ');
    final store = ref.watch(modulesStoreProvider);
    final manifest = ref.watch(catalogModulesManifestProvider).value;
    ModuleEntry? moduleEntry;
    if (manifest != null) {
      for (final candidate in manifest.entries) {
        if (candidate.id == resource.id) {
          moduleEntry = candidate;
          break;
        }
      }
    }
    final bundled = kBundledCatalogModules.contains(resource.id);
    final installed = store?.isInstalled(resource.id) ?? false;
    final updatePending = store?.hasUpdateFor(resource.id, manifest) ?? false;

    return Container(
      key: ValueKey('store-resource-${resource.id}'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: kPanelBg,
        border: Border.all(color: kCardBorder),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 68,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(5),
            ),
            alignment: Alignment.center,
            child: Text(
              resource.abbrev ??
                  (resource.typeLabelIn(lang).isEmpty
                      ? '?'
                      : resource.typeLabelIn(lang).substring(0, 1)),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        resource.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (bundled)
                      _badge(
                        text: l10n.storeIncluded,
                        color: kTextSecondary,
                        background: Colors.transparent,
                        border: kCardBorder,
                      )
                    else if (installed) ...[
                      if (updatePending)
                        _badge(
                          text: l10n.storeUpdateBadge,
                          color: kWarning,
                          background: kWarning.withValues(alpha: 0.08),
                          border: kWarning.withValues(alpha: 0.5),
                        )
                      else
                        _badge(
                          text: l10n.storeInstalledBadge,
                          color: kAccent,
                          background: kAccent.withValues(alpha: 0.09),
                          border: kAccent.withValues(alpha: 0.5),
                        ),
                    ] else if (store == null)
                      _badge(
                        text: l10n.storeIncluded,
                        color: kTextSecondary,
                        background: Colors.transparent,
                        border: kCardBorder,
                      )
                    else
                      _badge(
                        text: l10n.libraryNotInstalledChip,
                        color: kTextSecondary,
                        background: Colors.transparent,
                        border: kCardBorder,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: kTextSecondary),
                ),
                if ((resource.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    resource.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: kTextSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 7),
                Row(
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      size: 13,
                      color: kTextSecondary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${l10n.storeLicense}: '
                        '${resource.licenseText.isNotEmpty ? resource.licenseText : licenseLabel(resource.licenseKind, lang: lang)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: kTextSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (store == null)
            FilledButton.tonal(
              key: ValueKey('store-open-${resource.id}'),
              onPressed: () => openCatalogResource(ref, resource),
              child: Text(l10n.storeOpen, style: const TextStyle(fontSize: 12.5)),
            )
          else
            _StoreActions(
              resource: resource,
              moduleId: resource.id,
              store: store,
              entry: moduleEntry,
              installed: installed,
              updatePending: updatePending,
              bundled: bundled,
              lang: lang,
            ),
        ],
      ),
    );
  }

  Widget _badge({
    required String text,
    required Color color,
    required Color background,
    required Color border,
  }) {
    final key = text;
    return Container(
      key: ValueKey('store-state-${key.replaceAll(' ', '-')}'),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(text, style: TextStyle(fontSize: 10.5, color: color)),
    );
  }
}

/// Columna de acciones de la tarjeta: instalar (con progreso) o quitar.
class _StoreActions extends ConsumerWidget {
  const _StoreActions({
    required this.resource,
    required this.moduleId,
    required this.store,
    required this.entry,
    required this.installed,
    required this.updatePending,
    required this.bundled,
    required this.lang,
  });

  final ResourceSummary resource;
  final String moduleId;
  final ModulesStore store;
  final ModuleEntry? entry;
  final bool installed;
  final bool updatePending;
  final bool bundled;
  final String lang;

  static String _sizeMB(double bytes, String lang) {
    final value = (bytes / 1000000).toStringAsFixed(1);
    return '${lang == 'es' ? value.replaceAll('.', ',') : value} MB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sizeLabel = entry == null ? '' : _sizeMB(entry!.size.toDouble(), lang);
    return ValueListenableBuilder<Map<String, ModuleInstallProgress>>(
      valueListenable: store.transfers,
      builder: (context, transfers, _) {
        final progress = transfers[moduleId];
        final running = progress?.phase == ModuleInstallPhase.running;
        final openAction = TextButton(
          key: ValueKey('store-open-${resource.id}'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(0, 32),
          ),
          onPressed: () => openCatalogResource(ref, resource),
          child: Text(l10n.storeOpen, style: const TextStyle(fontSize: 12)),
        );

        if (running) {
          return SizedBox(
            width: 118,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(
                  value: progress?.fraction,
                  minHeight: 3.5,
                ),
                const SizedBox(height: 5),
                Text(
                  entry == null
                      ? _sizeMB((progress?.received ?? 0).toDouble(), lang)
                      : '${_sizeMB((progress?.received ?? 0).toDouble(), lang)} / ${_sizeMB(entry!.size.toDouble(), lang)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: kTextSecondary),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(0, 28),
                  ),
                  onPressed: () => store.cancel(moduleId),
                  child: Text(
                    l10n.storeCancelInstall,
                    style: const TextStyle(fontSize: 11.5),
                  ),
                ),
              ],
            ),
          );
        }

        if (bundled) {
          return SizedBox(
            width: 118,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                openAction,
                Text(
                  l10n.storeIncluded,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: kTextSecondary),
                ),
              ],
            ),
          );
        }

        if (installed && !updatePending) {
          return SizedBox(
            width: 118,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                openAction,
                TextButton(
                  key: ValueKey('store-uninstall-${resource.id}'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(0, 28),
                    foregroundColor: kDangerText,
                  ),
                  onPressed: () => _uninstall(context, ref),
                  child: Text(
                    l10n.storeUninstallButton,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          );
        }

        // No instalado, o hay actualización publicada.
        return SizedBox(
          width: 118,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                key: ValueKey('store-install-${resource.id}'),
                onPressed: entry == null
                    ? null
                    : () async {
                        await store.install(entry!);
                      },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(
                  updatePending ? l10n.storeUpdateBadge : l10n.storeInstallButton,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sizeLabel,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: kTextSecondary),
              ),
              if (installed) openAction,
            ],
          ),
        );
      },
    );
  }

  Future<void> _uninstall(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.storeRemovedTitle),
        content: Text(l10n.storeConfirmUninstall),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.storeUninstallButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await store.uninstall(moduleId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.storeUninstalledSnackbar(resource.title))),
      );
    }
  }
}

/// Tarjeta propia del índice de búsqueda local (`catalog.search`), porque no
/// es un "recurso" abrible: se usa al buscar en frío.
class _SearchModuleCard extends ConsumerWidget {
  const _SearchModuleCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final store = ref.watch(modulesStoreProvider);
    if (store == null) return const SizedBox.shrink();
    final manifest = ref.watch(catalogModulesManifestProvider).value;
    ModuleEntry? entry;
    if (manifest != null) {
      for (final candidate in manifest.entries) {
        if (candidate.id == ModuleEntry.searchModuleId) {
          entry = candidate;
          break;
        }
      }
    }
    final installed = store.isInstalled(ModuleEntry.searchModuleId);
    final updatePending = store.hasUpdateFor(ModuleEntry.searchModuleId, manifest);
    final sizeLabel = entry == null
        ? ''
        : '${(entry.size / 1000000).toStringAsFixed(0)} MB';

    return Container(
      key: const ValueKey('store-search-module'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: kAccent.withValues(alpha: 0.05),
        border: Border.all(color: kCardBorder),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 68,
            decoration: BoxDecoration(
              color: kAccent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(5),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.manage_search,
              size: 24,
              color: kAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry?.title ?? 'Búsqueda local',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.storeSearchModuleHint,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: kTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 118,
            child: ValueListenableBuilder<Map<String, ModuleInstallProgress>>(
              valueListenable: store.transfers,
              builder: (context, transfers, _) {
                final progress = transfers[ModuleEntry.searchModuleId];
                final running = progress?.phase == ModuleInstallPhase.running;
                if (running) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LinearProgressIndicator(
                        value: progress?.fraction,
                        minHeight: 3.5,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${((progress?.received ?? 0) / 1000000).toStringAsFixed(0)} / ${sizeLabel.isEmpty ? '?' : sizeLabel}',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, color: kTextSecondary),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          minimumSize: const Size(0, 28),
                        ),
                        onPressed: () =>
                            store.cancel(ModuleEntry.searchModuleId),
                        child: Text(
                          l10n.storeCancelInstall,
                          style: const TextStyle(fontSize: 11.5),
                        ),
                      ),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (installed && !updatePending)
                      Text(
                        l10n.storeInstalledBadge,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: kAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    FilledButton.tonal(
                      key: const ValueKey('store-install-search'),
                      onPressed: entry == null ? null : () => store.install(entry!),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(
                        updatePending
                            ? l10n.storeUpdateBadge
                            : installed
                            ? l10n.storeInstallButton
                            : l10n.storeInstallButton,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (sizeLabel.isNotEmpty && !installed)
                      Text(
                        sizeLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: kTextSecondary,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
