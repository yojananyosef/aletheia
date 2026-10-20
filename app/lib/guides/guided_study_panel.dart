/// Panel del Estudio guiado (M6.3).
///
/// Réplica del diálogo del original (`settle_guided_study.png`): caja `Find`,
/// sección `Guided study` con las cuatro guías y los flujos de trabajo. En el
/// clon el diálogo es un panel y las guías son **plantillas propias** cuyos
/// pasos abren las herramientas reales (lector, comparación, Temas, búsqueda
/// y Notas); abrir una guía no crea pestañas nuevas.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization.dart';
import '../core/theme.dart';
import '../references/reference_parser.dart';
import '../workspace/models.dart';
import '../workspace/workspace_controller.dart';
import 'guides_data.dart';

class GuidedStudyPanel extends ConsumerStatefulWidget {
  const GuidedStudyPanel({super.key, required this.tile, required this.tab});

  final WorkspaceTile tile;
  final WorkspaceTab tab;

  @override
  ConsumerState<GuidedStudyPanel> createState() => _GuidedStudyPanelState();
}

class _GuidedStudyPanelState extends ConsumerState<GuidedStudyPanel> {
  final TextEditingController _find = TextEditingController();
  final TextEditingController _param = TextEditingController();

  String _filter = '';
  final Set<int> _done = {};

  /// Guía en ejecución: se guarda en la pestaña (`tab.reference`) para que no
  /// se pierda al cambiar de panel; el parámetro vive en `tab.query`.
  String? get _guideId {
    final ref = widget.tab.reference;
    return ref == null || ref.isEmpty ? null : ref;
  }

  @override
  void initState() {
    super.initState();
    _param.text = widget.tab.query ?? '';
  }

  @override
  void didUpdateWidget(GuidedStudyPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab.reference != widget.tab.reference) {
      _done.clear();
      _param.text = widget.tab.query ?? '';
    }
  }

  @override
  void dispose() {
    _find.dispose();
    _param.dispose();
    super.dispose();
  }

  void _setTab({String? reference, String? query}) {
    ref
        .read(workspaceProvider.notifier)
        .updateTab(
          tileId: widget.tile.id,
          tabId: widget.tab.id,
          reference: reference,
          query: query,
        );
  }

  /// Referencia del primer panel bíblico abierto (contexto de la guía).
  String _activeReference() {
    for (final tile in ref.read(workspaceProvider).tiles) {
      for (final tab in tile.tabs) {
        if (tab.kind == PanelKind.bible && tab.reference != null) {
          return tab.reference!;
        }
      }
    }
    return 'JHN.1.1';
  }

  void _openGuide(GuideDef def) {
    final param = def.param == GuideParam.word ? '' : _activeReference();
    _done.clear();
    _param.text = param;
    _setTab(reference: def.id, query: param);
  }

  void _runAction(GuideAction action, String param) {
    final ctrl = ref.read(workspaceProvider.notifier);
    final text = param.trim();
    final jump = parseReference(text)?.canonical ?? _activeReference();
    switch (action) {
      case GuideAction.reader:
        ctrl.openTab(TabSpec(kind: PanelKind.bible, reference: jump));
      case GuideAction.compare:
        ctrl.openTab(TabSpec(kind: PanelKind.textComparison, reference: jump));
      case GuideAction.factbook:
        ctrl.openTab(TabSpec(kind: PanelKind.factbook, query: text));
      case GuideAction.search:
        ctrl.openTab(TabSpec(kind: PanelKind.search, query: text));
      case GuideAction.notes:
        ctrl.openTab(const TabSpec(kind: PanelKind.notes));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final guide = _guideId == null ? null : guideById(l10n, _guideId!);
    return Container(
      color: kPanelBg,
      child: guide == null ? _buildHub(context) : _buildRunner(context, guide),
    );
  }

  // --------------------------------------------------------------- hub

  Widget _buildHub(BuildContext context) {
    final l10n = context.l10n;
    final defs = guidedDefinitions(l10n);
    final query = _filter.trim().toLowerCase();
    List<GuideDef> matching(GuideKind kind) => [
      for (final def in defs)
        if (def.kind == kind &&
            (query.isEmpty || def.title.toLowerCase().contains(query)))
          def,
    ];
    final guides = matching(GuideKind.guide);
    final workflows = matching(GuideKind.workflow);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: TextField(
            key: const ValueKey('guided-find'),
            controller: _find,
            onChanged: (value) => setState(() => _filter = value),
            decoration: InputDecoration(
              hintText: l10n.guidedFindHint,
              prefixIcon: const Icon(Icons.search, size: 17),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: kBorder),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
            children: [
              if (guides.isNotEmpty) ...[
                _SectionLabel(l10n.guidedGuides),
                for (final def in guides) _guideRow(def),
              ],
              if (workflows.isNotEmpty) ...[
                _SectionLabel(l10n.guidedWorkflows),
                for (final def in workflows) _guideRow(def),
              ],
              if (guides.isEmpty && workflows.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.guidedNoMatch,
                    style: TextStyle(fontSize: 12.5, color: kTextSecondary),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _guideRow(GuideDef def) => InkWell(
    key: ValueKey('guide-${def.id}'),
    onTap: () => _openGuide(def),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
      child: Row(
        children: [
          Icon(def.icon, size: 17, color: kAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  def.title,
                  style: TextStyle(fontSize: 13.5, color: kTextPrimary),
                ),
                const SizedBox(height: 1),
                Text(
                  def.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: kTextSecondary),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 17, color: kTextSecondary),
        ],
      ),
    ),
  );

  // ------------------------------------------------------------ ejecución

  Widget _buildRunner(BuildContext context, GuideDef def) {
    final l10n = context.l10n;
    final param = _param.text;
    final steps = def.buildSteps(param);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 14, 2),
          child: Row(
            children: [
              IconButton(
                key: const ValueKey('guide-back'),
                iconSize: 17,
                tooltip: l10n.guidedBack,
                onPressed: () {
                  _done.clear();
                  _param.text = '';
                  _setTab(reference: '');
                },
                icon: const Icon(Icons.arrow_back),
              ),
              Icon(def.icon, size: 17, color: kAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  def.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: Text(
            def.description,
            style: TextStyle(fontSize: 12, color: kTextSecondary),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('guide-param'),
                  controller: _param,
                  onChanged: (value) {
                    _setTab(query: value);
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    labelText: def.param == GuideParam.word
                        ? l10n.guidedParamWord
                        : l10n.guidedParamReference,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: kBorder),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                key: const ValueKey('guide-generate'),
                onPressed: () => setState(() {}),
                child: Text(
                  l10n.guidedGenerate,
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: kBorder),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
            children: [
              for (final (index, step) in steps.indexed)
                _stepCard(index, step, param),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepCard(int index, GuideStep step, String param) {
    final l10n = context.l10n;
    final done = _done.contains(index);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        decoration: BoxDecoration(
          color: done ? kSidebarBg : kPanelBg,
          border: Border.all(color: kCardBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: done ? kAccent : kAccent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: done
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: kAccent,
                          ),
                        ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    step.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  key: ValueKey('guide-step-done-$index'),
                  iconSize: 16,
                  visualDensity: VisualDensity.compact,
                  tooltip: l10n.guidedStepDone,
                  onPressed: () => setState(() {
                    done ? _done.remove(index) : _done.add(index);
                  }),
                  icon: Icon(
                    done ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: done ? kAccent : kTextSecondary,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 29, right: 4),
              child: Text(
                step.detail,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: kTextSecondary,
                ),
              ),
            ),
            if (step.action != null)
              Padding(
                padding: const EdgeInsets.only(left: 25, top: 4),
                child: TextButton(
                  key: ValueKey('guide-step-action-$index'),
                  onPressed: () => _runAction(step.action!, param),
                  child: Text(
                    step.actionLabel,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: kTextSecondary,
      ),
    ),
  );
}
