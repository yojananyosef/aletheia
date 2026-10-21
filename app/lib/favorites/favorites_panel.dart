/// Panel de Favoritos (M6.4).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization.dart';
import '../core/theme.dart';
import '../favorites/favorites_controller.dart';
import '../favorites/favorites_models.dart';
import '../references/reference_parser.dart';
import '../workspace/models.dart';
import '../workspace/workspace_controller.dart';

class FavoritesPanel extends ConsumerStatefulWidget {
  const FavoritesPanel({super.key});

  @override
  ConsumerState<FavoritesPanel> createState() => _FavoritesPanelState();
}

class _FavoritesPanelState extends ConsumerState<FavoritesPanel> {
  final TextEditingController _reference = TextEditingController();
  final TextEditingController _search = TextEditingController();
  String _query = '';
  String? _error;

  @override
  void dispose() {
    _reference.dispose();
    _search.dispose();
    super.dispose();
  }

  void _add() {
    final parsed = parseReference(_reference.text);
    if (parsed == null) {
      setState(() => _error = context.l10n.favoritesInvalidReference);
      return;
    }
    final controller = ref.read(favoritesProvider.notifier);
    if (controller.find(FavoriteKind.passage, parsed.canonical) != null) {
      setState(() => _error = context.l10n.favoritesAlreadySaved);
      return;
    }
    controller.add(
      kind: FavoriteKind.passage,
      title: displayFromCanonical(parsed.canonical, lang: context.l10nLang),
      subtitle: context.l10n.favoritesPassageSubtitle,
      resourceId: kDefaultBibleResourceId,
      reference: parsed.canonical,
    );
    _reference.clear();
    setState(() => _error = null);
  }

  void _open(Favorite favorite) {
    final ctrl = ref.read(workspaceProvider.notifier);
    switch (favorite.kind) {
      case FavoriteKind.passage:
        ctrl.openTab(
          TabSpec(
            kind: PanelKind.bible,
            reference: favorite.reference,
            resourceId: favorite.resourceId ?? kDefaultBibleResourceId,
          ),
        );
      case FavoriteKind.resource:
        ctrl.openTab(
          TabSpec(
            kind: PanelKind.resource,
            title: favorite.title,
            resourceId: favorite.resourceId,
            reference: favorite.reference,
          ),
        );
      case FavoriteKind.map:
        ctrl.openTab(
          TabSpec(
            kind: PanelKind.atlas,
            title: favorite.title,
            resourceId: favorite.resourceId,
            reference: favorite.reference,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final favorites = ref.watch(favoritesProvider);
    final query = _query.trim().toLowerCase();
    final visible = [
      for (final favorite in favorites)
        if (query.isEmpty ||
            favorite.title.toLowerCase().contains(query) ||
            (favorite.subtitle ?? '').toLowerCase().contains(query) ||
            (favorite.reference ?? '').toLowerCase().contains(query))
          favorite,
    ];
    return Container(
      color: kPanelBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.star_outline, size: 18, color: kAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.panelTitleFavorites,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(
              l10n.favoritesIntro,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: kTextSecondary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('favorites-add-reference'),
                    controller: _reference,
                    onSubmitted: (_) => _add(),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: l10n.favoritesAddHint,
                      isDense: true,
                      prefixIcon: const Icon(
                        Icons.menu_book_outlined,
                        size: 17,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: kBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: _error == null ? kBorder : kError,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const ValueKey('favorites-add-button'),
                  onPressed: _add,
                  child: Text(
                    l10n.favoritesAdd,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Text(
                _error!,
                style: const TextStyle(fontSize: 11.5, color: kError),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              key: const ValueKey('favorites-search'),
              controller: _search,
              onChanged: (value) => setState(() => _query = value),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: l10n.favoritesSearchHint,
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 17),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: kBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: kBorder),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_border,
                            size: 32,
                            color: kTextSecondary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            favorites.isEmpty
                                ? l10n.favoritesEmpty
                                : l10n.favoritesNoResults,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: kTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final favorite = visible[index];
                      return Container(
                        key: ValueKey('favorite-${favorite.id}'),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
                        decoration: BoxDecoration(
                          color: kPanelBg,
                          border: Border.all(color: kCardBorder),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              switch (favorite.kind) {
                                FavoriteKind.passage =>
                                  Icons.menu_book_outlined,
                                FavoriteKind.resource =>
                                  Icons.auto_stories_outlined,
                                FavoriteKind.map => Icons.map_outlined,
                              },
                              size: 18,
                              color: kAccent,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: InkWell(
                                onTap: () => _open(favorite),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      favorite.title,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (favorite.subtitle != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        favorite.subtitle!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: kTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              key: ValueKey('favorite-open-${favorite.id}'),
                              iconSize: 16,
                              tooltip: l10n.favoritesOpen,
                              onPressed: () => _open(favorite),
                              icon: const Icon(Icons.chevron_right),
                            ),
                            IconButton(
                              key: ValueKey('favorite-remove-${favorite.id}'),
                              iconSize: 16,
                              tooltip: l10n.favoritesRemove,
                              onPressed: () => ref
                                  .read(favoritesProvider.notifier)
                                  .remove(favorite.id),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
