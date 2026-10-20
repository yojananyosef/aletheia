/// Planes de lectura propios (M6.3).
///
/// El original abre un gestor de planes de la cuenta y el botón «Comenzar plan
/// de lectura» de la ficha del recurso. El clon trae **plantillas propias**
/// generadas a partir del manifiesto de la RV1909: el plan guarda sólo su
/// plantilla, la fecha de inicio y el día actual; los capítulos de cada día se
/// calculan de forma determinista desde el manifiesto.
library;

import 'package:flutter/material.dart';

import '../catalog/document_models.dart';
import '../core/localization.dart';
import '../references/reference_parser.dart';

/// Plantilla de un plan de lectura.
class PlanTemplateDef {
  const PlanTemplateDef({
    required this.id,
    required this.icon,
    required this.days,
    required this.bookCodes,
    required this.title,
    required this.description,
  });

  final String id;
  final IconData icon;
  final int days;

  /// Códigos de libro incluidos (`null` = toda la Biblia).
  final List<String>? bookCodes;
  final String title;
  final String description;
}

const _ntCodes = [
  'MAT', 'MRK', 'LUK', 'JHN', 'ACT', 'ROM', '1CO', '2CO', 'GAL', 'EPH',
  'PHP', 'COL', '1TH', '2TH', '1TI', '2TI', 'TIT', 'PHM', 'HEB', 'JAS',
  '1PE', '2PE', '1JN', '2JN', '3JN', 'JUD', 'REV',
];

List<PlanTemplateDef> planTemplates(AppLocalizations l10n) => [
      PlanTemplateDef(
        id: 'bible-year',
        icon: Icons.auto_stories_outlined,
        days: 365,
        bookCodes: null,
        title: l10n.planBibleYearTitle,
        description: l10n.planBibleYearDesc,
      ),
      PlanTemplateDef(
        id: 'gospels-30',
        icon: Icons.menu_book_outlined,
        days: 30,
        bookCodes: const ['MAT', 'MRK', 'LUK', 'JHN'],
        title: l10n.planGospels30Title,
        description: l10n.planGospels30Desc,
      ),
      PlanTemplateDef(
        id: 'psalms-proverbs-31',
        icon: Icons.music_note_outlined,
        days: 31,
        bookCodes: const ['PSA', 'PRO'],
        title: l10n.planPsalms31Title,
        description: l10n.planPsalms31Desc,
      ),
      PlanTemplateDef(
        id: 'nt-90',
        icon: Icons.church_outlined,
        days: 90,
        bookCodes: _ntCodes,
        title: l10n.planNt90Title,
        description: l10n.planNt90Desc,
      ),
    ];

/// Plan activo (uno por instalación).
class ReadingPlan {
  const ReadingPlan({
    required this.id,
    required this.templateId,
    required this.resourceId,
    required this.startedAt,
    required this.dayIndex,
    this.lastReadAt,
  });

  factory ReadingPlan.fromJson(Map<String, dynamic> json) => ReadingPlan(
        id: json['id'] as String,
        templateId: json['templateId'] as String,
        resourceId: json['resourceId'] as String? ?? 'bible.rv1909',
        startedAt:
            DateTime.tryParse(json['startedAt'] as String? ?? '') ??
                DateTime.now(),
        dayIndex: json['dayIndex'] as int? ?? 0,
        lastReadAt: DateTime.tryParse(json['lastReadAt'] as String? ?? ''),
      );

  final String id;
  final String templateId;
  final String resourceId;
  final DateTime startedAt;

  /// Día que toca leer (0-based). Igual o mayor que la duración = completado.
  final int dayIndex;
  final DateTime? lastReadAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'templateId': templateId,
        'resourceId': resourceId,
        'startedAt': startedAt.toIso8601String(),
        'dayIndex': dayIndex,
        if (lastReadAt != null) 'lastReadAt': lastReadAt!.toIso8601String(),
      };

  ReadingPlan copyWith({int? dayIndex, DateTime? lastReadAt}) => ReadingPlan(
        id: id,
        templateId: templateId,
        resourceId: resourceId,
        startedAt: startedAt,
        dayIndex: dayIndex ?? this.dayIndex,
        lastReadAt: lastReadAt ?? this.lastReadAt,
      );
}

/// Un capítulo dentro de un plan.
class PlanChapter {
  const PlanChapter(this.bookCode, this.chapter);

  final String bookCode;
  final int chapter;
}

/// Calendario de un plan: los capítulos de cada día.
class PlanSchedule {
  PlanSchedule(this.days, this.manifest);

  /// Reparte los capítulos de la plantilla entre sus días de forma uniforme.
  factory PlanSchedule.build(DocumentManifest manifest, PlanTemplateDef def) {
    final allowed = def.bookCodes?.toSet();
    final chapters = <PlanChapter>[];
    for (final book in manifest.books) {
      if (allowed != null && !allowed.contains(book.code)) continue;
      for (var c = 1; c <= book.chapters.length; c++) {
        chapters.add(PlanChapter(book.code, c));
      }
    }
    final total = chapters.length;
    // Con menos capítulos que días el plan se acorta: un capítulo por día.
    final dayCount = total == 0 ? 0 : (def.days < total ? def.days : total);
    final days = <List<PlanChapter>>[];
    for (var i = 0; i < dayCount; i++) {
      final start = total == 0 ? 0 : (i * total / dayCount).floor();
      final end = total == 0 ? 0 : ((i + 1) * total / dayCount).floor();
      if (end > start) days.add(chapters.sublist(start, end));
    }
    return PlanSchedule(days, manifest);
  }

  final List<List<PlanChapter>> days;
  final DocumentManifest manifest;

  int get length => days.length;

  List<PlanChapter> dayChapters(int index) =>
      index >= 0 && index < days.length ? days[index] : const [];

  /// Etiqueta legible del día: «Génesis 1—3» o «Génesis 50—Éxodo 2».
  String dayLabel(int index, {String lang = 'es'}) {
    final chapters = dayChapters(index);
    if (chapters.isEmpty) return '';
    final first = chapters.first;
    final last = chapters.last;
    final firstBook = manifest.bookByCode(first.bookCode)?.name ??
        bookDisplayName(first.bookCode, lang: lang);
    if (chapters.length == 1) return '$firstBook ${first.chapter}';
    if (first.bookCode == last.bookCode) {
      return '$firstBook ${first.chapter}—${last.chapter}';
    }
    final lastBook = manifest.bookByCode(last.bookCode)?.name ??
        bookDisplayName(last.bookCode, lang: lang);
    return '$firstBook ${first.chapter}—$lastBook ${last.chapter}';
  }

  /// Referencia canónica del inicio del día (la que abre el lector).
  String? dayReference(int index) {
    final chapters = dayChapters(index);
    if (chapters.isEmpty) return null;
    return '${chapters.first.bookCode}.${chapters.first.chapter}';
  }

}
