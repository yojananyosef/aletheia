/// Tienda local: catálogo navegable de los recursos incluidos.
///
/// No hay compras ni descargas: todos los recursos son de dominio público o
/// propios y ya están empaquetados. La pantalla sirve para descubrirlos,
/// revisar su licencia y abrirlos en el workspace.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/catalog_gateway.dart';
import '../catalog/catalog_models.dart';
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 700;
                return Row(
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: kFieldFill,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _type == null
                                  ? l10n.storeAllTypes
                                  : resourceTypeLabel(_type!, lang: lang),
                              style: TextStyle(
                                fontSize: 12.5,
                                color: kTextPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, size: 17),
                          ],
                        ),
                      ),
                    ),
                    if (wide)
                      TextButton.icon(
                        key: const ValueKey('store-open-library'),
                        onPressed: () => ref
                            .read(libraryOverlayVisibleProvider.notifier)
                            .open(),
                        icon: const Icon(
                          Icons.local_library_outlined,
                          size: 16,
                        ),
                        label: Text(
                          l10n.storeOpenLibrary,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      )
                    else
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
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildBody(l10n, lang)),
        ],
      ),
    );
  }

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
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final resource = items[index];
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: kAccent.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        l10n.storeIncluded,
                        style: const TextStyle(fontSize: 10.5, color: kAccent),
                      ),
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
          FilledButton.tonal(
            key: ValueKey('store-open-${resource.id}'),
            onPressed: () => openCatalogResource(ref, resource),
            child: Text(l10n.storeOpen, style: const TextStyle(fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}
