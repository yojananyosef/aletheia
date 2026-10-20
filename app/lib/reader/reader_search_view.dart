/// Búsqueda dentro del panel del lector (modo «Buscar»).
///
/// Usa el mismo motor FTS5 del catálogo limitado al recurso abierto
/// (`/v1/search?resource=`). Tocar un resultado navega el panel a su
/// referencia; el estado vive en el panel para que el pasaje se pueda
/// retomar sin perder los resultados.
library;

import 'package:flutter/material.dart';

import '../catalog/catalog_gateway.dart';
import '../catalog/catalog_models.dart';
import '../core/localization.dart';
import '../core/theme.dart';
import '../search/search_hit_tile.dart';

class ReaderSearchView extends StatelessWidget {
  const ReaderSearchView({
    super.key,
    required this.resourceTitle,
    required this.controller,
    required this.onSubmit,
    required this.onOpenHit,
    this.focusNode,
    this.loading = false,
    this.error,
    this.result,
  });

  /// Nombre corto del recurso abierto (sigla de la pestaña o su título).
  final String resourceTitle;

  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String> onSubmit;
  final ValueChanged<SearchHit> onOpenHit;

  final bool loading;
  final Object? error;
  final SearchResult? result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: TextField(
            key: const ValueKey('reader-search-field'),
            controller: controller,
            focusNode: focusNode,
            onSubmitted: onSubmit,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: context.l10n.panelSearchTitle(resourceTitle),
              isDense: true,
              prefixIcon: const Icon(Icons.search, size: 17),
              suffixIcon: IconButton(
                key: const ValueKey('reader-search-submit'),
                iconSize: 15,
                tooltip: context.l10n.readerSearchInResource,
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => onSubmit(controller.text),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: Text(
            context.l10n.panelSearchSyntax,
            style: TextStyle(
              fontSize: 11,
              color: kTextSecondary.withValues(alpha: 0.9),
            ),
          ),
        ),
        const Divider(height: 12),
        Expanded(child: _buildBody(context)),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = context.l10n;
    if (loading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
      );
    }
    if (error != null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined, size: 30, color: kTextSecondary),
              const SizedBox(height: 8),
              Text(
                l10n.searchFailed,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                searchErrorMessage(l10n, error),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: kTextSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                key: const ValueKey('reader-search-retry'),
                onPressed: () => onSubmit(controller.text),
                child: Text(l10n.retry, style: const TextStyle(fontSize: 12.5)),
              ),
            ],
          ),
        ),
      );
    }

    final result = this.result;
    if (result == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            l10n.panelSearchPrompt,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: kTextSecondary,
              height: 1.45,
            ),
          ),
        ),
      );
    }

    if (result.hits.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 30, color: kTextSecondary),
            const SizedBox(height: 8),
            Text(
              l10n.searchNoResults(result.query),
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.searchTryFewerWords,
              style: TextStyle(fontSize: 12, color: kTextSecondary),
            ),
          ],
        ),
      );
    }

    return ListView(
      key: ValueKey('reader-search-results-${result.query}'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
          child: Text(
            l10n.searchResultsCountFor(result.total, result.query),
            style: TextStyle(fontSize: 12.5, color: kTextSecondary),
          ),
        ),
        for (final hit in result.hits)
          SearchHitTile(
            key: ValueKey('reader-search-hit-${hit.ref}'),
            hit: hit,
            onTap: () => onOpenHit(hit),
          ),
        const SizedBox(height: 10),
      ],
    );
  }
}
