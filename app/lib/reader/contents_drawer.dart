/// Drawer "Índice de contenidos" del lector (M1): árbol libro → capítulos
/// con buscador y resaltado de la posición actual.
library;

import 'package:flutter/material.dart';

import '../catalog/document_models.dart';
import '../core/localization.dart';
import '../core/theme.dart';

class ContentsDrawer extends StatefulWidget {
  const ContentsDrawer({
    super.key,
    required this.manifest,
    required this.currentBook,
    required this.currentChapter,
    required this.onSelectChapter,
    required this.onClose,
  });

  final DocumentManifest manifest;
  final String currentBook;
  final int currentChapter;
  final void Function(String bookCode, int chapter) onSelectChapter;
  final VoidCallback onClose;

  @override
  State<ContentsDrawer> createState() => _ContentsDrawerState();
}

class _ContentsDrawerState extends State<ContentsDrawer> {
  final _filterController = TextEditingController();
  final _currentBookKey = GlobalKey();
  late final Set<String> _expanded = {widget.currentBook};
  bool _searchOpen = false;
  bool _scrolledOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealCurrentBook());
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  void _revealCurrentBook() {
    if (!mounted || _scrolledOnce) return;
    final ctx = _currentBookKey.currentContext;
    if (ctx == null) return;
    _scrolledOnce = true;
    Scrollable.ensureVisible(ctx, alignment: 0.25, duration: Duration.zero);
  }

  static String _normalize(String input) {
    const repl = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };
    final sb = StringBuffer();
    for (final rune in input.toLowerCase().runes) {
      final ch = String.fromCharCode(rune);
      sb.write(repl[ch] ?? ch);
    }
    return sb.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filter = _normalize(_filterController.text.trim());
    final filtering = filter.isNotEmpty;
    final books = filtering
        ? widget.manifest.books
              .where((b) => _normalize(b.name).contains(filter))
              .toList()
        : widget.manifest.books;

    return Container(
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: kBorder)),
        color: kPanelBg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.contentsTitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.contentsSearch,
                  iconSize: 16,
                  onPressed: () => setState(() => _searchOpen = !_searchOpen),
                  icon: const Icon(Icons.search),
                ),
                IconButton(
                  tooltip: l10n.contentsClose,
                  iconSize: 16,
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          if (_searchOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: TextField(
                controller: _filterController,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: l10n.contentsFilter,
                  isDense: true,
                  prefixIcon: const Icon(Icons.search, size: 15),
                  border: const UnderlineInputBorder(),
                ),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final book in books) ..._bookRows(book, filtering),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _bookRows(ManifestBook book, bool filtering) {
    final isCurrent = book.code == widget.currentBook;
    final expanded = filtering || _expanded.contains(book.code);
    return [
      InkWell(
        key: isCurrent ? _currentBookKey : null,
        onTap: () => setState(() {
          if (!_expanded.remove(book.code)) _expanded.add(book.code);
        }),
        child: SizedBox(
          height: 30,
          child: Row(
            children: [
              const SizedBox(width: 6),
              Icon(
                expanded ? Icons.expand_more : Icons.chevron_right,
                size: 16,
                color: kTextSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  book.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                    color: kTextPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
      if (expanded)
        for (final chapter in book.chapters)
          InkWell(
            onTap: () => widget.onSelectChapter(book.code, chapter.n),
            child: SizedBox(
              height: 27,
              child: Padding(
                padding: const EdgeInsets.only(left: 30, right: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    context.l10n.contentsChapter(chapter.n),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: (isCurrent && chapter.n == widget.currentChapter)
                          ? kAccent
                          : kTextSecondary,
                      fontWeight:
                          (isCurrent && chapter.n == widget.currentChapter)
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ),
    ];
  }
}
