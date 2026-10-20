/// Popover de estudio para una palabra del texto original.
///
/// Muestra la forma, Strong, morfología traducida, transliteración y glosa, y
/// permite abrir la entrada completa en el léxico Strong. La entrada del
/// léxico se carga en modo diferido para no bloquear el lector.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/document_models.dart';
import '../catalog/morphology.dart';
import '../catalog/sections_repository.dart';
import '../core/localization.dart';
import '../core/theme.dart';
import '../workspace/models.dart';
import '../workspace/workspace_controller.dart';
import 'reader_style.dart';

const kStrongLexiconResourceId = 'lexicon.strongs';

class WordStudyDialog extends ConsumerWidget {
  const WordStudyDialog({
    super.key,
    required this.word,
    required this.sourceResourceId,
  });

  final TextInline word;
  final String sourceResourceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final strong = word.strong;
    final isHebrew = strong?.startsWith('H') ?? false;
    final morphology = ref.watch(morphologyProvider).value;
    final section = strong == null
        ? AsyncValue<CatalogSection?>.data(null)
        : ref.watch(sectionProvider((kStrongLexiconResourceId, strong)));

    final gloss = word.displayGloss;
    final englishGloss = word.gloss?.trim();
    final showEnglish =
        englishGloss != null &&
        englishGloss.isNotEmpty &&
        englishGloss != gloss;

    return AlertDialog(
      key: const ValueKey('word-study-dialog'),
      titlePadding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
      contentPadding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
      actionsPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      title: Row(
        children: [
          Icon(
            isHebrew ? Icons.translate : Icons.menu_book_outlined,
            size: 19,
            color: kAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.wordStudyTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Directionality(
                textDirection:
                    isHebrew ? TextDirection.rtl : TextDirection.ltr,
                child: SelectableText(
                  word.cleanText,
                  textAlign: isHebrew ? TextAlign.right : TextAlign.left,
                  style: readerBodyStyle(size: 25).copyWith(
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _Row(
                label: l10n.wordStudyStrong,
                value: word.strongFull ?? strong ?? '',
              ),
              if ((word.translit ?? '').isNotEmpty)
                _Row(label: l10n.wordStudyTranslit, value: word.translit!),
              if ((word.lemma ?? '').isNotEmpty)
                _Row(label: l10n.wordStudyLemma, value: word.lemma!),
              if ((word.morph ?? '').isNotEmpty)
                _Row(
                  label: l10n.wordStudyMorphology,
                  value: morphologyLabel(morphology, word.morph),
                ),
              if (gloss != null && gloss.isNotEmpty)
                _Row(
                  label: l10n.wordStudyGloss,
                  value: gloss,
                ),
              if (showEnglish)
                _Row(
                  label: l10n.wordStudyGlossSource,
                  value: englishGloss,
                ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              section.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
                error: (_, _) => Text(
                  l10n.wordStudyLexiconError,
                  style: TextStyle(fontSize: 12, color: kTextSecondary),
                ),
                data: (entry) {
                  if (entry == null) {
                    return Text(
                      l10n.wordStudyNoLexicon,
                      style: TextStyle(fontSize: 12.5, color: kTextSecondary),
                    );
                  }
                  final preview = _plainText(entry);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        entry.summary.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if ((entry.summary.summary ?? '').isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          entry.summary.summary!,
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ],
                      if (preview.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          preview,
                          maxLines: 8,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.45,
                            color: kTextSecondary,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
        if (strong != null)
          FilledButton.icon(
            key: const ValueKey('word-study-open-lexicon'),
            onPressed: () => _openLexicon(context, ref, strong),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text(l10n.wordStudyOpenLexicon),
          ),
      ],
    );
  }

  void _openLexicon(BuildContext context, WidgetRef ref, String strong) {
    final ctrl = ref.read(workspaceProvider.notifier);
    final opened = ctrl.openInResource(
      resourceId: kStrongLexiconResourceId,
      reference: strong,
      kind: PanelKind.resource,
    );
    if (!opened) {
      ctrl.openTab(
        TabSpec(
          kind: PanelKind.resource,
          title: context.l10n.wordStudyLexiconTitle,
          reference: strong,
          resourceType: 'dictionary',
          resourceId: kStrongLexiconResourceId,
        ),
      );
    }
    Navigator.of(context).pop();
  }

  static String _plainText(CatalogSection section) {
    final buffer = StringBuffer();
    for (final block in section.blocks) {
      switch (block) {
        case HeadingBlock h:
          if (buffer.isNotEmpty) buffer.write(' · ');
          buffer.write(h.text);
        case VerseGroupBlock g:
          for (final verse in g.verses) {
            for (final inline in verse.inlines) {
              if (inline case TextInline text) buffer.write(text.text);
            }
            buffer.write(' ');
          }
        case RuleBlock _:
          break;
        case MapBlock m:
          if (buffer.isNotEmpty) buffer.write(' · ');
          buffer.write(m.title);
        case ChapterNumberBlock c:
          buffer.write('${c.value} ');
      }
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                color: kTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
