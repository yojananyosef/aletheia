/// Búsqueda (M2): panel real sobre el motor FTS5 del catálogo.
///
/// Referencia del original: la evidencia de reconocimiento.
/// La consulta vive en `WorkspaceTab.query` y el historial de la pestaña
/// (`WorkspaceTab.history`) guarda consultas; atrás/adelante y el menú de
/// historial navegan por él.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/catalog_gateway.dart';
import '../catalog/catalog_models.dart';
import '../catalog/catalog_source_providers.dart';
import '../catalog/mods_catalog_source.dart';
import '../core/localization.dart';
import '../core/theme.dart';
import '../references/reference_parser.dart';
import '../workspace/models.dart';
import '../workspace/workspace_controller.dart';
import 'search_hit_tile.dart';

class SearchPanel extends ConsumerStatefulWidget {
  const SearchPanel({super.key, required this.tile, required this.tab});

  final WorkspaceTile tile;
  final WorkspaceTab tab;

  @override
  ConsumerState<SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends ConsumerState<SearchPanel> {
  static const _pageSize = 20;

  late final TextEditingController _controller;

  String _scope = SearchScope.all.id;
  String? _typeFilter;
  String? _languageFilter;
  String? _bookFilter;
  SearchResult? _result;
  Object? _error;
  bool _loading = false;
  int _page = 1;
  int _runSeq = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.tab.query ?? '');
    final query = widget.tab.query?.trim();
    if (query != null && query.isNotEmpty) _run(query, page: 1);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SearchPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final query = widget.tab.query;
    if (query == oldWidget.tab.query) return;
    _controller.text = query ?? '';
    final trimmed = query?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      _run(trimmed, page: 1);
    } else {
      setState(() {
        _result = null;
        _error = null;
        _loading = false;
      });
    }
  }

  // ----------------------------------------------------------------- datos

  Future<void> _run(
    String query, {
    required int page,
    bool append = false,
  }) async {
    final seq = ++_runSeq;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      var result = await ref
          .read(catalogGatewayProvider)
          .search(
            query: query,
            scope: _scope,
            type: _typeFilter,
            language: _languageFilter,
            book: _bookFilter,
            page: page,
            pageSize: _pageSize,
          );
      if (!mounted || seq != _runSeq) return;
      final previous = _result;
      if (append && previous != null && previous.query == result.query) {
        result = SearchResult(
          query: result.query,
          scope: result.scope,
          total: result.total,
          page: result.page,
          pageSize: result.pageSize,
          hits: [...previous.hits, ...result.hits],
          facets: result.facets,
        );
      }
      setState(() {
        _result = result;
        _page = page;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || seq != _runSeq) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  // -------------------------------------------------------------- acciones

  void _submit() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    if (query == widget.tab.query) {
      _run(query, page: 1);
      return;
    }
    // Registrar en el historial: el cambio de `query` dispara la búsqueda.
    ref
        .read(workspaceProvider.notifier)
        .recordSearch(
          tileId: widget.tile.id,
          tabId: widget.tab.id,
          query: query,
        );
  }

  void _selectScope(String scope) {
    if (scope == _scope) return;
    setState(() => _scope = scope);
    _rerun();
  }

  void _setFilter(String kind, String? value) {
    setState(() {
      switch (kind) {
        case 'type':
          _typeFilter = value;
        case 'language':
          _languageFilter = value;
        case 'book':
          _bookFilter = value;
      }
    });
    _rerun();
  }

  void _clearFilters() {
    if (_typeFilter == null && _languageFilter == null && _bookFilter == null) {
      return;
    }
    setState(() {
      _typeFilter = null;
      _languageFilter = null;
      _bookFilter = null;
    });
    _rerun();
  }

  void _rerun() {
    final query = widget.tab.query?.trim();
    if (query != null && query.isNotEmpty) _run(query, page: 1);
  }

  void _historyGo(int index) {
    ref
        .read(workspaceProvider.notifier)
        .searchHistoryGo(
          tileId: widget.tile.id,
          tabId: widget.tab.id,
          index: index,
        );
  }

  void _openHit(SearchHit hit) {
    final ctrl = ref.read(workspaceProvider.notifier);
    final kind = switch (hit.resourceType) {
      'factbook' => PanelKind.factbook,
      'devotional' => PanelKind.devotional,
      'commentary' || 'dictionary' => PanelKind.resource,
      _ => PanelKind.bible,
    };
    // Si ya hay una pestaña del recurso, navega en ella.
    if (ctrl.openInResource(
      resourceId: hit.resourceId,
      reference: hit.ref,
      kind: kind,
    )) {
      return;
    }
    ctrl.openTab(
      TabSpec(
        kind: kind,
        title: kind == PanelKind.bible
            ? (hit.abbrev ?? hit.resourceTitle)
            : hit.resourceTitle,
        reference: hit.ref,
        resourceId: hit.resourceId,
        resourceType: hit.resourceType,
      ),
    );
  }

  void _showSyntaxHelp() {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.searchSyntaxTitle,
          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: 470,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SyntaxRow(example: 'Verbo', meaning: l10n.searchSyntaxWord),
              _SyntaxRow(
                example: '"en el principio"',
                meaning: l10n.searchSyntaxPhraseNote,
              ),
              _SyntaxRow(
                example: 'Verbo AND principio',
                meaning: l10n.searchSyntaxAndNote,
              ),
              _SyntaxRow(
                example: 'principio WITHIN 5 WORDS Verbo',
                meaning: l10n.searchSyntaxWithinNote,
              ),
              _SyntaxRow(
                example: 'Verbo NEAR principio',
                meaning: l10n.searchSyntaxNearNote,
              ),
              _SyntaxRow(
                example: 'bible:"Jn 3" type:factbook',
                meaning: l10n.searchSyntaxFieldNote,
              ),
              const SizedBox(height: 10),
              Text(
                l10n.searchSyntaxNote,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: kTextSecondary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ construir

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildToolbar(),
        _buildScopes(),
        _buildFilters(),
        const Divider(height: 1),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildToolbar() {
    final l10n = context.l10n;
    final historyIndex = widget.tab.historyIndex;
    final history = widget.tab.history;
    final canBack = historyIndex > 0;
    final canForward = historyIndex >= 0 && historyIndex < history.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('search-back'),
            iconSize: 18,
            tooltip: l10n.searchBack,
            onPressed: canBack ? () => _historyGo(historyIndex - 1) : null,
            icon: const Icon(Icons.arrow_back),
          ),
          IconButton(
            key: const ValueKey('search-forward'),
            iconSize: 18,
            tooltip: l10n.readerForward,
            onPressed: canForward ? () => _historyGo(historyIndex + 1) : null,
            icon: const Icon(Icons.arrow_forward),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              key: const ValueKey('search-field'),
              controller: _controller,
              onSubmitted: (_) => _submit(),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: l10n.searchTitle,
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 17),
                suffixIcon: IconButton(
                  key: const ValueKey('search-submit'),
                  iconSize: 15,
                  tooltip: l10n.libraryFind,
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _submit,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: kBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: kAccent),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          PopupMenuButton<int>(
            key: const ValueKey('search-history'),
            tooltip: l10n.searchHistory,
            iconSize: 19,
            icon: const Icon(Icons.history),
            onSelected: _historyGo,
            itemBuilder: (context) => [
              PopupMenuItem<int>(
                enabled: false,
                height: 30,
                child: Text(
                  l10n.searchHistory,
                  style: TextStyle(fontSize: 11.5, color: kTextSecondary),
                ),
              ),
              if (history.isEmpty)
                PopupMenuItem<int>(
                  enabled: false,
                  child: Text(
                    l10n.searchHistoryEmpty,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              for (var i = history.length - 1; i >= 0; i--)
                PopupMenuItem<int>(
                  value: i,
                  child: Row(
                    children: [
                      Icon(
                        i == historyIndex ? Icons.check : Icons.history,
                        size: 14,
                        color: i == historyIndex ? kAccent : kTextSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        history[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: i == historyIndex
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          IconButton(
            key: const ValueKey('search-help'),
            iconSize: 19,
            tooltip: l10n.searchSyntaxTitle,
            onPressed: _showSyntaxHelp,
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
    );
  }

  Widget _buildScopes() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final scope in SearchScope.values)
            _ScopeChip(
              key: ValueKey('scope-${scope.id}'),
              scope: scope,
              selected: scope.id == _scope,
              lang: context.l10nLang,
              onTap: scope.enabled ? () => _selectScope(scope.id) : null,
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final l10n = context.l10n;
    final lang = context.l10nLang;
    final facets = _result?.facets ?? const <String, Map<String, int>>{};
    final types =
        <String>{
          'bible',
          'factbook',
          'devotional',
          ...?facets['type']?.keys,
          ?_typeFilter,
        }.toList()..sort(
          (a, b) => resourceTypeLabel(
            a,
            lang: lang,
          ).compareTo(resourceTypeLabel(b, lang: lang)),
        );
    final languages =
        <String>{
          'es',
          'en',
          ...?facets['language']?.keys,
          ?_languageFilter,
        }.toList()..sort(
          (a, b) => languageLabel(
            a,
            lang: lang,
          ).compareTo(languageLabel(b, lang: lang)),
        );
    final books = <String>{...?facets['book']?.keys, ?_bookFilter}.toList()
      ..sort(
        (a, b) => bookDisplayName(
          a,
          lang: lang,
        ).compareTo(bookDisplayName(b, lang: lang)),
      );
    final hasFilter =
        _typeFilter != null || _languageFilter != null || _bookFilter != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _FilterMenu(
            key: const ValueKey('search-filter-type'),
            title: l10n.searchFilterType,
            allLabel: l10n.searchFilterAll,
            selected: _typeFilter,
            options: [
              for (final type in types)
                (type, resourceTypeLabel(type, lang: lang)),
            ],
            onSelected: (value) => _setFilter('type', value),
          ),
          _FilterMenu(
            key: const ValueKey('search-filter-language'),
            title: l10n.searchFilterLanguage,
            allLabel: l10n.searchFilterAll,
            selected: _languageFilter,
            options: [
              for (final language in languages)
                (language, languageLabel(language, lang: lang)),
            ],
            onSelected: (value) => _setFilter('language', value),
          ),
          _FilterMenu(
            key: const ValueKey('search-filter-book'),
            title: l10n.searchFilterBook,
            allLabel: l10n.searchFilterAllBooks,
            selected: _bookFilter,
            options: [
              for (final code in books)
                (code, bookDisplayName(code, lang: lang)),
            ],
            onSelected: (value) => _setFilter('book', value),
          ),
          if (hasFilter)
            TextButton(
              key: const ValueKey('search-filters-clear'),
              onPressed: _clearFilters,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n.searchFilterClear,
                style: const TextStyle(fontSize: 11.5),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final transfer = ref.watch(catalogTransferProvider);
    if (transfer == null) return _buildBodyContent();
    return ValueListenableBuilder<CatalogTransfer?>(
      valueListenable: transfer,
      builder: (context, value, child) {
        final body = child ?? _buildBodyContent();
        if (value == null) return body;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DownloadBanner(
              transfer: value,
              onCancel: () =>
                  ref.read(modsCatalogSourceProvider)?.cancelTransfer(),
            ),
            Expanded(child: body),
          ],
        );
      },
      child: _buildBodyContent(),
    );
  }

  Widget _buildBodyContent() {
    final l10n = context.l10n;
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined, size: 34, color: kTextSecondary),
              const SizedBox(height: 10),
              Text(
                l10n.searchFailed,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                searchErrorMessage(l10n, _error),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: kTextSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.tonal(
                onPressed: () {
                  final query = widget.tab.query?.trim();
                  if (query != null && query.isNotEmpty) _run(query, page: 1);
                },
                child: Text(l10n.retry, style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
      );
    }

    final result = _result;
    if (result == null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.manage_search, size: 38, color: kTextSecondary),
              const SizedBox(height: 12),
              Text(
                l10n.searchPromptTitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.searchPromptBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: kTextSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (result.hits.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 34, color: kTextSecondary),
            const SizedBox(height: 10),
            Text(
              l10n.searchNoResults(result.query),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.searchTryFewerOrScope,
              style: TextStyle(fontSize: 12.5, color: kTextSecondary),
            ),
          ],
        ),
      );
    }

    final scopeLabel = SearchScope.values
        .firstWhere(
          (s) => s.id == result.scope,
          orElse: () => SearchScope.values.first,
        )
        .labelIn(context.l10nLang);

    final groups = <String, List<SearchHit>>{};
    for (final hit in result.hits) {
      groups.putIfAbsent(hit.resourceId, () => []).add(hit);
    }

    return ListView(
      key: ValueKey(
        'search-results-${result.query}-${result.scope}-'
        '${_typeFilter ?? ''}-${_languageFilter ?? ''}-${_bookFilter ?? ''}',
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.searchResultsCountFor(result.total, result.query),
                  style: TextStyle(fontSize: 12.5, color: kTextSecondary),
                ),
              ),
              Text(
                l10n.searchScope(scopeLabel),
                style: TextStyle(fontSize: 12, color: kTextSecondary),
              ),
            ],
          ),
        ),
        for (final entry in groups.entries) ...[
          _ResourceGroupHeader(
            key: ValueKey('search-group-${entry.key}'),
            hit: entry.value.first,
            count: entry.value.length,
          ),
          for (final hit in entry.value)
            SearchHitTile(
              key: ValueKey('search-hit-${hit.resourceId}-${hit.ref}'),
              hit: hit,
              onTap: () => _openHit(hit),
            ),
        ],
        if (result.hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: TextButton(
                key: const ValueKey('search-more'),
                onPressed: () =>
                    _run(result.query, page: _page + 1, append: true),
                child: Text(
                  l10n.searchLoadMoreRemaining(
                    result.total - result.hits.length,
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _FilterMenu extends StatelessWidget {
  const _FilterMenu({
    super.key,
    required this.title,
    required this.allLabel,
    required this.selected,
    required this.options,
    required this.onSelected,
  });

  final String title;
  final String allLabel;
  final String? selected;
  final List<(String, String)> options;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    var selectedLabel = allLabel;
    if (selected != null) {
      selectedLabel = selected!;
      for (final option in options) {
        if (option.$1 == selected) {
          selectedLabel = option.$2;
          break;
        }
      }
    }
    final active = selected != null;

    return PopupMenuButton<String>(
      tooltip: title,
      onSelected: (value) => onSelected(value.isEmpty ? null : value),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: '',
          height: 34,
          child: Row(
            children: [
              if (selected == null)
                const Icon(Icons.check, size: 14, color: kAccent)
              else
                const SizedBox(width: 14, height: 14),
              const SizedBox(width: 8),
              Text(allLabel, style: const TextStyle(fontSize: 12.5)),
            ],
          ),
        ),
        for (final (value, label) in options)
          PopupMenuItem<String>(
            value: value,
            height: 34,
            child: Row(
              children: [
                if (value == selected)
                  const Icon(Icons.check, size: 14, color: kAccent)
                else
                  const SizedBox(width: 14, height: 14),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontSize: 12.5)),
              ],
            ),
          ),
      ],
      child: Container(
        constraints: const BoxConstraints(maxWidth: 190),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
        decoration: BoxDecoration(
          color: active ? kAccent.withValues(alpha: 0.08) : null,
          border: Border.all(color: active ? kAccent : kBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          '$title: $selectedLabel',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.5,
            color: active ? kAccent : kTextSecondary,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _ResourceGroupHeader extends StatelessWidget {
  const _ResourceGroupHeader({
    super.key,
    required this.hit,
    required this.count,
  });

  final SearchHit hit;
  final int count;

  @override
  Widget build(BuildContext context) {
    final icon = switch (hit.resourceType) {
      'factbook' => Icons.menu_book_outlined,
      'devotional' => Icons.wb_twilight,
      _ => Icons.auto_stories_outlined,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: kTextSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              hit.resourceTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
          ),
          Text(
            formatCount(count),
            style: TextStyle(fontSize: 11.5, color: kTextSecondary),
          ),
        ],
      ),
    );
  }
}

class _DownloadBanner extends StatelessWidget {
  const _DownloadBanner({required this.transfer, required this.onCancel});

  final CatalogTransfer transfer;
  final VoidCallback onCancel;

  String _size(int bytes, String lang) {
    final value = (bytes / 1000000).toStringAsFixed(1);
    return '${lang == 'es' ? value.replaceAll('.', ',') : value} MB';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = context.l10nLang;
    final total = transfer.total;
    final received = _size(transfer.received, lang);
    final progress = total == null
        ? l10n.searchDownloadUnknown(received)
        : l10n.searchDownloadProgress(received, _size(total, lang));
    return Container(
      key: const ValueKey('search-download-banner'),
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: kAccent.withValues(alpha: 0.07),
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.downloading, size: 18, color: kAccent),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.searchDownloadTitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.searchDownloadBody(
                    total == null ? '≈ 49 MB' : _size(total, lang),
                  ),
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: kTextSecondary,
                  ),
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    value: transfer.fraction,
                    backgroundColor: kBorder,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  progress,
                  style: TextStyle(fontSize: 10.5, color: kTextSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          TextButton(
            key: const ValueKey('search-download-cancel'),
            onPressed: onCancel,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.searchDownloadCancel,
              style: const TextStyle(fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    super.key,
    required this.scope,
    required this.selected,
    this.lang = 'es',
    this.onTap,
  });

  final SearchScope scope;
  final bool selected;

  /// Idioma de la interfaz (nombre del ámbito).
  final String lang;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final body = InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4.5),
        decoration: BoxDecoration(
          color: selected ? kAccent.withValues(alpha: 0.10) : null,
          border: Border.all(color: selected ? kAccent : kBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          scope.labelIn(lang),
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: !enabled
                ? kTextSecondary.withValues(alpha: 0.55)
                : (selected ? kAccent : kTextPrimary),
          ),
        ),
      ),
    );
    if (enabled) return body;
    return Tooltip(
      message:
          '${scope.labelIn(lang)} — ${scope.note ?? context.l10n.placeholderFallback}',
      child: body,
    );
  }
}

class _SyntaxRow extends StatelessWidget {
  const _SyntaxRow({required this.example, required this.meaning});

  final String example;
  final String meaning;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 240,
            child: Text(
              example,
              style: TextStyle(
                fontSize: 12.5,
                fontFamily: 'monospace',
                color: kTextPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              meaning,
              style: TextStyle(fontSize: 12.5, color: kTextSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
