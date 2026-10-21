/// Panel Explorador de Salmos (M6.4).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/document_models.dart';
import '../catalog/document_repository.dart';
import '../core/localization.dart';
import '../core/theme.dart';
import '../favorites/favorites_controller.dart';
import '../favorites/favorites_models.dart';
import '../workspace/models.dart';
import '../workspace/workspace_controller.dart';
import 'psalms_data.dart';

class PsalmsExplorerPanel extends ConsumerStatefulWidget {
  const PsalmsExplorerPanel({super.key});

  @override
  ConsumerState<PsalmsExplorerPanel> createState() =>
      _PsalmsExplorerPanelState();
}

class _PsalmsExplorerPanelState extends ConsumerState<PsalmsExplorerPanel> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  String _category = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _fold(String value) {
    const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const to = 'aaaaaeeeeiiiiooooouuuunc';
    final buffer = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      final index = from.indexOf(char);
      buffer.write(index == -1 ? char : to[index]);
    }
    return buffer.toString();
  }

  int get _psalmOfDay {
    final now = DateTime.now();
    final day = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    return (day - 1) % 150 + 1;
  }

  String? _firstVerse(BookDocument? book, int psalm) {
    final chapter = book?.chapter(psalm);
    if (chapter == null) return null;
    for (final block in chapter.blocks) {
      if (block is! VerseGroupBlock) continue;
      for (final verse in block.verses) {
        final text = verse.inlines
            .whereType<TextInline>()
            .map((inline) => inline.text)
            .join()
            .trim();
        if (text.isNotEmpty) return text;
      }
    }
    return null;
  }

  void _open(int psalm) {
    ref
        .read(workspaceProvider.notifier)
        .openTab(
          TabSpec(
            kind: PanelKind.bible,
            reference: 'PSA.$psalm',
            resourceId: kDefaultBibleResourceId,
          ),
        );
  }

  void _toggleFavorite(int psalm) {
    final l10n = context.l10n;
    final saved = ref
        .read(favoritesProvider.notifier)
        .togglePassage(
          reference: 'PSA.$psalm',
          title: l10n.psalmNumber(psalm),
          subtitle: l10n.psalmsSubtitle,
        );
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(saved ? l10n.favoritesAdded : l10n.favoritesRemoved),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final categories = psalmCategories(l10n);
    final bookAsync = ref.watch(
      bookDocumentProvider((kDefaultBibleResourceId, 'PSA')),
    );
    final book = bookAsync.value;
    final snippets = {for (var n = 1; n <= 150; n++) n: _firstVerse(book, n)};
    final selectedCategory = _category == 'all'
        ? null
        : categories.where((c) => c.id == _category).firstOrNull;
    final query = _fold(_query.trim());
    final visible = [
      for (var n = 1; n <= 150; n++)
        if ((selectedCategory == null || selectedCategory.psalms.contains(n)) &&
            (query.isEmpty ||
                _fold(l10n.psalmNumber(n)).contains(query) ||
                _fold(snippets[n] ?? '').contains(query) ||
                _fold(
                  categories
                      .where((c) => c.psalms.contains(n))
                      .map((c) => c.label)
                      .join(' '),
                ).contains(query)))
          n,
    ];
    final todaySaved = ref
        .watch(favoritesProvider)
        .any(
          (favorite) =>
              favorite.kind == FavoriteKind.passage &&
              favorite.reference == 'PSA.$_psalmOfDay',
        );

    return Container(
      color: kPanelBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.music_note_outlined, size: 18, color: kAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.panelTitlePsalms,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  l10n.psalmsCount(visible.length),
                  style: TextStyle(fontSize: 11.5, color: kTextSecondary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              l10n.psalmsIntro,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: kTextSecondary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: TextField(
              key: const ValueKey('psalms-search'),
              controller: _search,
              onChanged: (value) => setState(() => _query = value),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: l10n.psalmsSearchHint,
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                _categoryChip(
                  id: 'all',
                  label: l10n.psalmsAll,
                  icon: Icons.apps,
                  selected: _category == 'all',
                ),
                for (final category in categories)
                  _categoryChip(
                    id: category.id,
                    label: category.label,
                    icon: category.icon,
                    selected: _category == category.id,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              decoration: BoxDecoration(
                color: kFieldFill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kCardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wb_sunny_outlined, size: 17, color: kAccent),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.psalmOfDay,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: kTextSecondary,
                          ),
                        ),
                        Text(
                          l10n.psalmNumber(_psalmOfDay),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('psalms-favorite-today'),
                    iconSize: 17,
                    tooltip: todaySaved
                        ? l10n.favoritesRemove
                        : l10n.favoritesAdd,
                    onPressed: () => _toggleFavorite(_psalmOfDay),
                    icon: Icon(todaySaved ? Icons.star : Icons.star_border),
                  ),
                  TextButton(
                    key: const ValueKey('psalms-open-today'),
                    onPressed: () => _open(_psalmOfDay),
                    child: Text(
                      l10n.psalmsOpen,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Text(
                      l10n.psalmsNoResults,
                      style: TextStyle(fontSize: 13, color: kTextSecondary),
                    ),
                  )
                : GridView.builder(
                    key: const ValueKey('psalms-grid'),
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 300,
                          mainAxisExtent: 98,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final psalm = visible[index];
                      final psalmCategoriesFor = categories
                          .where((c) => c.psalms.contains(psalm))
                          .toList();
                      return InkWell(
                        key: ValueKey('psalm-$psalm'),
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _open(psalm),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
                          decoration: BoxDecoration(
                            color: kPanelBg,
                            border: Border.all(color: kCardBorder),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      l10n.psalmNumber(psalm),
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    psalmCategoriesFor.isEmpty
                                        ? Icons.music_note_outlined
                                        : psalmCategoriesFor.first.icon,
                                    size: 15,
                                    color: kAccent,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                psalmCategoriesFor
                                    .map((c) => c.label)
                                    .take(2)
                                    .join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: kTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Expanded(
                                child: Text(
                                  snippets[psalm] ?? l10n.psalmsSubtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    height: 1.35,
                                    color: kTextSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              l10n.psalmsAttribution,
              style: TextStyle(fontSize: 10.5, color: kTextSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip({
    required String id,
    required String label,
    required IconData icon,
    required bool selected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        key: ValueKey('psalms-category-$id'),
        avatar: Icon(icon, size: 13),
        label: Text(label, style: const TextStyle(fontSize: 11.5)),
        selected: selected,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
        onSelected: (_) => setState(() => _category = id),
      ),
    );
  }
}
