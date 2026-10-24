/// Devocional del día (M5).
///
/// Es un recurso con calendario: la sección se identifica con
/// `dayofyear.MM.DD` (como el `references/dayofyear.10.19` del original) y se
/// resuelve contra el catálogo o los assets. El panel permite avanzar y
/// retroceder un día, volver a hoy y elegir una fecha.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../catalog/sections_repository.dart';
import '../core/localization.dart';
import '../core/theme.dart';
import '../references/reference_parser.dart';
import '../workspace/models.dart';
import '../workspace/workspace_controller.dart';
import 'section_view.dart';

const kDevotionalResourceId = 'devotional.daily';

class DevotionalPanel extends ConsumerStatefulWidget {
  const DevotionalPanel({super.key, required this.tile, required this.tab});

  final WorkspaceTile tile;
  final WorkspaceTab tab;

  @override
  ConsumerState<DevotionalPanel> createState() => _DevotionalPanelState();
}

class _DevotionalPanelState extends ConsumerState<DevotionalPanel> {
  late DateTime _date;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _date = _dateFromReference(widget.tab.reference) ?? _today();
    _syncTabReference();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DevotionalPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tab.reference == oldWidget.tab.reference) return;
    final parsed = _dateFromReference(widget.tab.reference);
    if (parsed != null && !_sameDay(parsed, _date)) {
      setState(() => _date = parsed);
    }
  }

  /// Recurso del tab (p. ej. `devotional.sme`); el diario por defecto si el
  /// tab no define uno.
  String get _resourceId => widget.tab.resourceId ?? kDevotionalResourceId;

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime? _dateFromReference(String? reference) {
    if (reference == null) return null;
    final match = RegExp(r'^dayofyear\.(\d{2})\.(\d{2})$')
        .firstMatch(reference);
    if (match == null) return null;
    final month = int.parse(match.group(1)!);
    final day = int.parse(match.group(2)!);
    final now = DateTime.now();
    final candidate = DateTime(now.year, month, day);
    // 29 de febrero solo existe en años bisiestos: usa 2024 como año de
    // referencia para poder consultar esa entrada.
    if (candidate.month != month || candidate.day != day) {
      return DateTime(2024, month, day);
    }
    return candidate;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String get _sectionId => 'dayofyear.${_two(_date.month)}.${_two(_date.day)}';

  static String _two(int value) => value.toString().padLeft(2, '0');

  void _syncTabReference() {
    final canonical = _sectionId;
    if (widget.tab.reference == canonical) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(workspaceProvider.notifier)
          .navigateTabReference(
            tileId: widget.tile.id,
            tabId: widget.tab.id,
            reference: canonical,
          );
    });
  }

  void _goTo(DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    if (_sameDay(target, _date)) return;
    setState(() => _date = target);
    _syncTabReference();
  }

  void _shift(int days) => _goTo(_date.add(Duration(days: days)));

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: context.l10n.devotionalPickDate,
    );
    if (picked != null && mounted) _goTo(picked);
  }

  void _openReference(String canonical) {
    final ctrl = ref.read(workspaceProvider.notifier);
    if (ctrl.openInResource(
      resourceId: kDefaultBibleResourceId,
      reference: canonical,
    )) {
      return;
    }
    ctrl.openTab(
      TabSpec(
        kind: PanelKind.bible,
        reference: canonical,
        resourceId: kDefaultBibleResourceId,
      ),
    );
  }

  String _dateLabel(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final month = DateFormat.MMMM(lang).format(_date);
    final capitalized = toBeginningOfSentenceCase(month);
    return lang == 'es'
        ? '${_date.day} de $capitalized'
        : '$capitalized ${_date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final async = ref.watch(
      sectionProvider((_resourceId, _sectionId)),
    );
    final isToday = _sameDay(_date, _today());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Row(
            children: [
              IconButton(
                key: const ValueKey('devotional-prev'),
                iconSize: 18,
                tooltip: l10n.devotionalPrevious,
                onPressed: () => _shift(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                key: const ValueKey('devotional-next'),
                iconSize: 18,
                tooltip: l10n.devotionalNext,
                onPressed: () => _shift(1),
                icon: const Icon(Icons.chevron_right),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _dateLabel(context),
                  key: const ValueKey('devotional-date'),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                key: const ValueKey('devotional-today'),
                onPressed: isToday ? null : () => _goTo(_today()),
                child: Text(
                  l10n.devotionalToday,
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
              IconButton(
                key: const ValueKey('devotional-pick-date'),
                iconSize: 18,
                tooltip: l10n.devotionalPickDate,
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month_outlined),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: async.when(
            loading: () => const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.devotionalEmptyTitle,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(
                      sectionProvider((_resourceId, _sectionId)),
                    ),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
            data: (section) {
              if (section == null || section.blocks.isEmpty) {
                return SectionEmptyState(
                  icon: Icons.wb_twilight,
                  title: l10n.devotionalEmptyTitle,
                  detail: l10n.devotionalEmptyDetail,
                );
              }
              return Scrollbar(
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  key: const ValueKey('devotional-body'),
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 20,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 660),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.panelTitleDevotional.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10.5,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w700,
                              color: kAccent,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SectionBlocksView(
                            blocks: section.blocks,
                            onNavigate: _openReference,
                          ),
                          if (section.summary.reference != null) ...[
                            const SizedBox(height: 18),
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                key: const ValueKey('devotional-open-passage'),
                                onPressed: () =>
                                    _openReference(section.summary.reference!),
                                icon: const Icon(
                                  Icons.menu_book_outlined,
                                  size: 16,
                                ),
                                label: Text(
                                  '${l10n.libraryOpen} '
                                  '${section.summary.referenceLabel ?? displayFromCanonical(section.summary.reference!)}',
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
