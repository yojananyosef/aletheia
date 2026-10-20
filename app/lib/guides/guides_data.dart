/// Guías y flujos del Estudio guiado (M6.3).
///
/// El original sirve guías licenciadas (`/guides/word`, `/guides/exegetical`,
/// `/guides/passage`, `/guides/sermon-starter`) y flujos de trabajo. El clon
/// no puede reutilizar esas guías, así que trae **plantillas propias** de los
/// mismos cuatro temas más tres flujos, con pasos que abren las herramientas
/// reales de la app (lector, comparación, Temas, búsqueda y Notas).
library;

import 'package:flutter/material.dart';

import '../core/localization.dart';

enum GuideKind { guide, workflow }

/// Parámetro que pide la guía antes de generar los pasos.
enum GuideParam { word, reference }

/// Herramienta que abre un paso.
enum GuideAction { reader, compare, factbook, search, notes }

class GuideStep {
  const GuideStep({
    required this.title,
    required this.detail,
    this.action,
    this.actionLabel = '',
  });

  final String title;
  final String detail;

  /// Acción del paso (si la tiene).
  final GuideAction? action;
  final String actionLabel;
}

class GuideDef {
  const GuideDef({
    required this.id,
    required this.icon,
    required this.kind,
    required this.param,
    required this.title,
    required this.description,
    required this.buildSteps,
  });

  final String id;
  final IconData icon;
  final GuideKind kind;
  final GuideParam param;
  final String title;
  final String description;

  /// Pasos localizados, ya con el parámetro insertado.
  final List<GuideStep> Function(String param) buildSteps;
}

/// Definiciones localizadas de las guías y flujos propios.
List<GuideDef> guidedDefinitions(AppLocalizations l10n) => [
      GuideDef(
        id: 'word',
        icon: Icons.translate_outlined,
        kind: GuideKind.guide,
        param: GuideParam.word,
        title: l10n.guideWordTitle,
        description: l10n.guideWordDesc,
        buildSteps: (param) => [
          _step(l10n, l10n.stepReadTitle, l10n.stepReadDetail(param),
              GuideAction.reader),
          _step(l10n, l10n.stepWordTitle, l10n.stepWordDetail(param),
              GuideAction.search),
          _step(l10n, l10n.stepThemeTitle, l10n.stepThemeDetail,
              GuideAction.factbook),
          _step(l10n, l10n.stepCompareTitle, l10n.stepCompareDetail,
              GuideAction.compare),
          _step(l10n, l10n.stepNoteTitle, l10n.stepNoteDetail,
              GuideAction.notes),
        ],
      ),
      GuideDef(
        id: 'exegetical',
        icon: Icons.menu_book_outlined,
        kind: GuideKind.guide,
        param: GuideParam.reference,
        title: l10n.guideExegeticalTitle,
        description: l10n.guideExegeticalDesc,
        buildSteps: (param) => [
          _step(l10n, l10n.stepReadTitle, l10n.stepReadDetail(param),
              GuideAction.reader),
          _step(l10n, l10n.stepContextTitle, l10n.stepContextDetail,
              GuideAction.factbook),
          _step(l10n, l10n.stepObserveTitle, l10n.stepObserveDetail,
              GuideAction.reader),
          _step(l10n, l10n.stepCompareTitle, l10n.stepCompareDetail,
              GuideAction.compare),
          _step(l10n, l10n.stepCrossTitle, l10n.stepCrossDetail),
          _step(l10n, l10n.stepNoteTitle, l10n.stepNoteDetail,
              GuideAction.notes),
        ],
      ),
      GuideDef(
        id: 'passage',
        icon: Icons.auto_stories_outlined,
        kind: GuideKind.guide,
        param: GuideParam.reference,
        title: l10n.guidePassageTitle,
        description: l10n.guidePassageDesc,
        buildSteps: (param) => [
          _step(l10n, l10n.stepPrayTitle, l10n.stepPrayDetail),
          _step(l10n, l10n.stepReadTitle, l10n.stepReadDetail(param),
              GuideAction.reader),
          _step(l10n, l10n.stepThemeTitle, l10n.stepThemeDetail,
              GuideAction.factbook),
          _step(l10n, l10n.stepCompareTitle, l10n.stepCompareDetail,
              GuideAction.compare),
          _step(l10n, l10n.stepApplyTitle, l10n.stepApplyDetail,
              GuideAction.notes),
        ],
      ),
      GuideDef(
        id: 'sermon-starter',
        icon: Icons.record_voice_over_outlined,
        kind: GuideKind.guide,
        param: GuideParam.reference,
        title: l10n.guideSermonTitle,
        description: l10n.guideSermonDesc,
        buildSteps: (param) => [
          _step(l10n, l10n.stepReadTitle, l10n.stepReadDetail(param),
              GuideAction.reader),
          _step(l10n, l10n.stepThemeTitle, l10n.stepThemeDetail,
              GuideAction.factbook),
          _step(l10n, l10n.stepCrossTitle, l10n.stepCrossDetail),
          _step(l10n, l10n.stepOutlineTitle, l10n.stepOutlineDetail,
              GuideAction.notes),
          _step(l10n, l10n.stepPrayTitle, l10n.stepPrayDetail),
        ],
      ),
      GuideDef(
        id: 'basic',
        icon: Icons.checklist_outlined,
        kind: GuideKind.workflow,
        param: GuideParam.reference,
        title: l10n.workflowBasicTitle,
        description: l10n.workflowBasicDesc,
        buildSteps: (param) => [
          _step(l10n, l10n.stepPrayTitle, l10n.stepPrayDetail),
          _step(l10n, l10n.stepReadTitle, l10n.stepReadDetail(param),
              GuideAction.reader),
          _step(l10n, l10n.stepObserveTitle, l10n.stepObserveDetail,
              GuideAction.reader),
          _step(l10n, l10n.stepInterpretTitle, l10n.stepInterpretDetail,
              GuideAction.factbook),
          _step(l10n, l10n.stepApplyTitle, l10n.stepApplyDetail,
              GuideAction.notes),
        ],
      ),
      GuideDef(
        id: 'inductive',
        icon: Icons.search_outlined,
        kind: GuideKind.workflow,
        param: GuideParam.reference,
        title: l10n.workflowInductiveTitle,
        description: l10n.workflowInductiveDesc,
        buildSteps: (param) => [
          _step(l10n, l10n.stepReadTitle, l10n.stepReadDetail(param),
              GuideAction.reader),
          _step(l10n, l10n.stepObserveTitle, l10n.stepObserveDetail,
              GuideAction.reader),
          _step(l10n, l10n.stepInterpretTitle, l10n.stepInterpretDetail,
              GuideAction.factbook),
          _step(l10n, l10n.stepCompareTitle, l10n.stepCompareDetail,
              GuideAction.compare),
          _step(l10n, l10n.stepApplyTitle, l10n.stepApplyDetail,
              GuideAction.notes),
        ],
      ),
      GuideDef(
        id: 'lectio',
        icon: Icons.self_improvement_outlined,
        kind: GuideKind.workflow,
        param: GuideParam.reference,
        title: l10n.workflowLectioTitle,
        description: l10n.workflowLectioDesc,
        buildSteps: (param) => [
          _step(l10n, l10n.stepLectioTitle, l10n.stepLectioDetail(param),
              GuideAction.reader),
          _step(l10n, l10n.stepMeditatioTitle, l10n.stepMeditatioDetail),
          _step(l10n, l10n.stepOratioTitle, l10n.stepOratioDetail),
          _step(l10n, l10n.stepContemplatioTitle,
              l10n.stepContemplatioDetail),
        ],
      ),
    ];

/// Guía por identificador (los pasos se construyen con `param`).
GuideDef? guideById(AppLocalizations l10n, String id) {
  for (final def in guidedDefinitions(l10n)) {
    if (def.id == id) return def;
  }
  return null;
}

GuideStep _step(
  AppLocalizations l10n,
  String title,
  String detail, [
  GuideAction? action,
]) =>
    GuideStep(
      title: title,
      detail: detail,
      action: action,
      actionLabel: switch (action) {
        GuideAction.reader => l10n.guidedActionReader,
        GuideAction.compare => l10n.guidedActionCompare,
        GuideAction.factbook => l10n.guidedActionFactbook,
        GuideAction.search => l10n.guidedActionSearch,
        GuideAction.notes => l10n.guidedActionNotes,
        null => '',
      },
    );
