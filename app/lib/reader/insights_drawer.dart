/// Drawers derechos del lector: «Ideas» (Insights) e «Información» (M6.1).
///
/// Fieles al original (ver la evidencia de reconocimiento):
/// - `Ideas` (💡): pestañas `Información del libro` y la referencia actual, con
///   `Libros relacionados` (secciones propias que citan la referencia) y
///   `Pasajes relacionados` (co-referencias del catálogo).
/// - `Información` (ⓘ): ficha del recurso con `Información auxiliar` y
///   `Copyright`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/catalog_models.dart';
import '../catalog/document_models.dart';
import '../catalog/document_repository.dart';
import '../catalog/resource_metadata.dart';
import '../core/localization.dart';
import '../core/resource_colors.dart';
import '../core/theme.dart';
import '../reading_plans/reading_plans_controller.dart';
import '../references/reference_parser.dart';
import '../workspace/models.dart';
import '../workspace/workspace_controller.dart';
import 'related_content.dart';

/// Drawer «Ideas» del lector.
class InsightsDrawer extends ConsumerStatefulWidget {
  const InsightsDrawer({
    super.key,
    required this.resourceId,
    required this.reference,
    required this.onClose,
    this.onNavigate,
    this.onOpenSection,
  });

  final String resourceId;

  /// Referencia actual del panel (canónica: `JHN.3.16`), si la hay.
  final String? reference;

  final VoidCallback onClose;

  /// Salta a una referencia citada dentro del mismo panel.
  final ValueChanged<String>? onNavigate;

  /// Abre una sección del catálogo (artículo del Factbook, día del devocional).
  final ValueChanged<RelatedSection>? onOpenSection;

  @override
  ConsumerState<InsightsDrawer> createState() => _InsightsDrawerState();
}

class _InsightsDrawerState extends ConsumerState<InsightsDrawer> {
  int _tab = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reference = widget.reference;
    if (reference == null) _tab = 0;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: kBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DrawerHeader(
            icon: Icons.lightbulb_outline,
            title: l10n.insightsTitle,
            closeTooltip: l10n.insightsClose,
            onClose: widget.onClose,
          ),
          if (reference != null)
            Row(
              children: [
                _DrawerTab(
                  key: const ValueKey('insights-tab-book'),
                  label: l10n.insightsBookInfoTab,
                  selected: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                ),
                _DrawerTab(
                  key: const ValueKey('insights-tab-reference'),
                  label: displayFromCanonical(
                    reference,
                    lang: context.l10nLang,
                  ),
                  selected: _tab == 1,
                  onTap: () => setState(() => _tab = 1),
                ),
              ],
            ),
          Divider(height: 1, color: kBorder),
          Expanded(
            child: SingleChildScrollView(
              child: _tab == 0 || reference == null
                  ? _BookInfoBody(
                      resourceId: widget.resourceId,
                      onOpenReadingPlan: widget.onClose,
                    )
                  : _ReferenceInsights(
                      resourceId: widget.resourceId,
                      reference: reference,
                      onNavigate: widget.onNavigate,
                      onOpenSection: widget.onOpenSection,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Drawer «Información» del lector (ficha del recurso).
class InfoDrawer extends StatelessWidget {
  const InfoDrawer({
    super.key,
    required this.resourceId,
    required this.onClose,
  });

  final String resourceId;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: kBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DrawerHeader(
            icon: Icons.info_outline,
            title: l10n.readerInfo,
            closeTooltip: l10n.insightsClose,
            onClose: onClose,
          ),
          Divider(height: 1, color: kBorder),
          Expanded(
            child: SingleChildScrollView(
              child: _BookInfoBody(
                resourceId: resourceId,
                showAuxiliary: true,
                onOpenReadingPlan: onClose,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ estructura

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.icon,
    required this.title,
    required this.closeTooltip,
    required this.onClose,
  });

  final IconData icon;
  final String title;
  final String closeTooltip;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: kTextSecondary),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
          ),
          IconButton(
            key: const ValueKey('drawer-close'),
            tooltip: closeTooltip,
            visualDensity: VisualDensity.compact,
            iconSize: 16,
            onPressed: onClose,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _DrawerTab extends StatelessWidget {
  const _DrawerTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 34,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? kAccent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? kTextPrimary : kTextSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------- ficha

class _BookInfoBody extends ConsumerWidget {
  const _BookInfoBody({
    required this.resourceId,
    this.showAuxiliary = false,
    this.onOpenReadingPlan,
  });

  final String resourceId;
  final bool showAuxiliary;

  /// Cierra el drawer al abrir el panel de planes (el plan se ve en el otro
  /// panel del workspace).
  final VoidCallback? onOpenReadingPlan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(resourceSummaryProvider(resourceId));
    final summary = async.value;
    if (summary == null) {
      if (async.isLoading) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }
      final manifest = ref.watch(manifestProvider(resourceId)).value;
      if (manifest == null) {
        return Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            l10n.insightsBookInfoUnavailable,
            style: TextStyle(fontSize: 12.5, color: kTextSecondary),
          ),
        );
      }
      return _BookInfoContent(
        title: manifest.title,
        abbrev: manifest.abbrev,
        resourceId: resourceId,
        subtitle: null,
        description: null,
        license: manifest.license,
        rows: const [],
        showAuxiliary: showAuxiliary,
        auxiliary: [
          (l10n.insightsAuxId, resourceId),
          (l10n.insightsAuxSource, manifest.source),
        ],
      );
    }

    final rows = <(String, String)>[
      if (summary.authorsLabel.isNotEmpty)
        (l10n.insightsAuthor, summary.authorsLabel),
      if ((summary.publisher ?? '').isNotEmpty)
        (l10n.insightsPublisher, summary.publisher!),
      if ((summary.edition ?? '').isNotEmpty)
        (l10n.insightsEdition, summary.edition!),
      if (summary.language.isNotEmpty)
        (
          l10n.insightsLanguage,
          languageLabel(summary.language, lang: context.l10nLang),
        ),
      (l10n.insightsType, summary.typeLabelIn(context.l10nLang)),
      if (summary.verses > 0)
        (l10n.insightsStats, l10n.insightsVerseCount(summary.verses)),
      if (summary.verses == 0 && summary.sections > 0)
        (l10n.insightsStats, l10n.insightsSectionCount(summary.sections)),
    ];

    return _BookInfoContent(
      title: summary.title,
      abbrev: summary.abbrev ?? summary.title,
      resourceId: resourceId,
      subtitle: summary.subtitle,
      description: summary.description,
      license: summary.licenseText.isNotEmpty
          ? summary.licenseText
          : licenseLabel(summary.licenseKind, lang: context.l10nLang),
      rows: rows,
      showAuxiliary: showAuxiliary,
      onOpenReadingPlan: onOpenReadingPlan,
      auxiliary: [
        (l10n.insightsAuxId, summary.id),
        (l10n.insightsAuxType, summary.typeLabelIn(context.l10nLang)),
      ],
    );
  }
}

class _BookInfoContent extends ConsumerWidget {
  const _BookInfoContent({
    required this.title,
    required this.abbrev,
    required this.resourceId,
    required this.subtitle,
    required this.description,
    required this.license,
    required this.rows,
    required this.showAuxiliary,
    required this.auxiliary,
    this.onOpenReadingPlan,
  });

  final String title;
  final String abbrev;
  final String resourceId;
  final String? subtitle;
  final String? description;
  final String license;
  final List<(String, String)> rows;
  final bool showAuxiliary;
  final List<(String, String)> auxiliary;
  final VoidCallback? onOpenReadingPlan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final hasPlan = ref.watch(readingPlansProvider) != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CoverChip(label: abbrev, resourceId: resourceId),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.insightsAbout(title),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kTextPrimary,
                      ),
                    ),
                    if ((subtitle ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: kTextSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if ((description ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                description!,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: kTextPrimary,
                ),
              ),
            ),
          const SizedBox(height: 10),
          ...rows.map((row) => _MetaRow(label: row.$1, value: row.$2)),
          const SizedBox(height: 12),
          OutlinedButton(
            key: const ValueKey('insights-reading-plan'),
            onPressed: () {
              ref
                  .read(workspaceProvider.notifier)
                  .openTab(const TabSpec(kind: PanelKind.readingPlans));
              onOpenReadingPlan?.call();
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_month_outlined, size: 15),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    hasPlan ? l10n.readingPlanView : l10n.readingPlanStart,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          _Collapsible(
            title: l10n.insightsCopyright,
            child: Text(
              license.isEmpty ? l10n.insightsLicenseUnknown : license,
              style: TextStyle(fontSize: 12, color: kTextSecondary),
            ),
          ),
          if (showAuxiliary)
            _Collapsible(
              title: l10n.insightsAuxiliary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final row in auxiliary)
                    if (row.$2.isNotEmpty)
                      _MetaRow(label: row.$1, value: row.$2),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 74,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: kTextSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, color: kTextPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverChip extends StatelessWidget {
  const _CoverChip({required this.label, required this.resourceId});

  final String label;

  /// El chip usa el color del recurso, como la pestaña y el lector (D-12).
  final String resourceId;

  @override
  Widget build(BuildContext context) {
    final color = resourceColorFor(resourceId);
    return Container(
      width: 46,
      height: 32,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        maxLines: 2,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _Collapsible extends StatefulWidget {
  const _Collapsible({
    required this.title,
    required this.child,
    this.initiallyOpen = false,
  });

  final String title;
  final Widget child;
  final bool initiallyOpen;

  @override
  State<_Collapsible> createState() => _CollapsibleState();
}

class _CollapsibleState extends State<_Collapsible> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                Icon(
                  _open ? Icons.expand_more : Icons.chevron_right,
                  size: 16,
                  color: kTextSecondary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 6),
            child: widget.child,
          ),
      ],
    );
  }
}

// --------------------------------------------------------- referencia actual

class _ReferenceInsights extends ConsumerWidget {
  const _ReferenceInsights({
    required this.resourceId,
    required this.reference,
    this.onNavigate,
    this.onOpenSection,
  });

  final String resourceId;
  final String reference;
  final ValueChanged<String>? onNavigate;
  final ValueChanged<RelatedSection>? onOpenSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final content = ref.watch(relatedContentProvider(reference));
    return content.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          l10n.insightsRelatedError,
          style: TextStyle(fontSize: 12.5, color: kTextSecondary),
        ),
      ),
      data: (related) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Collapsible(
            title: l10n.insightsRelatedBooks,
            initiallyOpen: true,
            child: related.books.isEmpty
                ? Text(
                    l10n.insightsNoBooks,
                    style: TextStyle(fontSize: 12, color: kTextSecondary),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final book in related.books)
                        _RelatedBookCard(
                          book: book,
                          onOpen: onOpenSection == null
                              ? null
                              : () => onOpenSection!(book),
                        ),
                    ],
                  ),
          ),
          Divider(height: 1, color: kBorder),
          _Collapsible(
            title: l10n.insightsRelatedPassages,
            initiallyOpen: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    l10n.insightsCrossReferences,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: kTextSecondary,
                    ),
                  ),
                ),
                if (related.passages.isEmpty)
                  Text(
                    l10n.insightsNoPassages,
                    style: TextStyle(fontSize: 12, color: kTextSecondary),
                  )
                else
                  for (final passage in related.passages)
                    _RelatedPassageRow(
                      passage: passage,
                      onTap: onNavigate == null
                          ? null
                          : () => onNavigate!(passage.reference),
                      readerResourceId: resourceId,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RelatedBookCard extends StatelessWidget {
  const _RelatedBookCard({required this.book, this.onOpen});

  final RelatedSection book;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final section = book.section;
    final subtitle = <String>[
      resourceLabelFor(l10n, book.resourceId),
      if ((section.theme ?? '').isNotEmpty) section.theme!,
      if ((section.referenceLabel ?? '').isNotEmpty) section.referenceLabel!,
    ].join(' · ');
    final snippet = section.summary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        key: ValueKey('insights-book-${section.id}'),
        onTap: onOpen,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CoverChip(
              label: resourceLabelFor(l10n, book.resourceId),
              resourceId: book.resourceId,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: kTextPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: kTextSecondary),
                  ),
                  if ((snippet ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        snippet!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: kTextPrimary),
                      ),
                    ),
                  if (onOpen != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        l10n.insightsMore,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: kAccent,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RelatedPassageRow extends StatelessWidget {
  const _RelatedPassageRow({
    required this.passage,
    this.onTap,
    required this.readerResourceId,
  });

  final RelatedPassage passage;
  final VoidCallback? onTap;
  final String readerResourceId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = displayFromCanonical(
      passage.reference,
      lang: context.l10nLang,
    );
    final sources = passage.sources.map(
      (s) => resourceLabelFor(l10n, s.resourceId),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: InkWell(
                  key: ValueKey('insights-passage-${passage.reference}'),
                  onTap: onTap,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sources.join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 10.5, color: kTextSecondary),
                ),
              ),
            ],
          ),
          _PassageText(
            resourceId: readerResourceId,
            reference: passage.reference,
          ),
        ],
      ),
    );
  }
}

/// Texto del versículo citado desde el recurso abierto (RV1909), si existe.
class _PassageText extends ConsumerWidget {
  const _PassageText({required this.resourceId, required this.reference});

  final String resourceId;
  final String reference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parsed = parseReference(reference);
    if (parsed == null) return const SizedBox.shrink();
    final document = ref
        .watch(bookDocumentProvider((resourceId, parsed.bookCode)))
        .value;
    final chapter = document?.chapter(parsed.chapter);
    if (chapter == null) return const SizedBox.shrink();
    final text = _verseText(chapter, parsed.verseStart ?? 1);
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        text,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11.5, color: kTextSecondary),
      ),
    );
  }
}

String _verseText(ChapterDocument chapter, int verse) {
  for (final block in chapter.blocks) {
    if (block is! VerseGroupBlock) continue;
    for (final entry in block.verses) {
      if (entry.n != verse) continue;
      final buffer = StringBuffer();
      for (final inline in entry.inlines) {
        if (inline is TextInline) buffer.write(inline.text);
      }
      return buffer.toString().trim();
    }
  }
  return '';
}

/// Nombre del recurso propio para las tarjetas del drawer.
String resourceLabelFor(AppLocalizations l10n, String resourceId) {
  switch (resourceId) {
    case 'factbook.core':
      return l10n.panelTitleFactbook;
    case 'devotional.daily':
      return l10n.panelTitleDevotional;
    case 'commentary.matthew-henry-concise':
      return l10n.resourceLabelMatthewHenry;
    case 'tsk':
      return l10n.resourceLabelTsk;
    default:
      return resourceId;
  }
}
