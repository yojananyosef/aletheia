/// Cursos propios (M6.4).
///
/// Tres rutas breves de estudio construidas con referencias de la RV1909.
/// Cada lección abre el pasaje en el lector; el progreso se mantiene mientras
/// el panel está abierto y no requiere contenido licenciado de terceros.
library;

import 'package:flutter/material.dart';

import '../core/localization.dart';

class CourseLesson {
  const CourseLesson({
    required this.id,
    required this.title,
    required this.detail,
    required this.reference,
  });

  final String id;
  final String title;
  final String detail;
  final String reference;
}

class CourseDef {
  const CourseDef({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.lessons,
  });

  final String id;
  final IconData icon;
  final String title;
  final String description;
  final List<CourseLesson> lessons;
}

List<CourseDef> courseDefinitions(AppLocalizations l10n) => [
  CourseDef(
    id: 'panorama',
    icon: Icons.auto_stories_outlined,
    title: l10n.coursePanoramaTitle,
    description: l10n.coursePanoramaDesc,
    lessons: [
      CourseLesson(
        id: 'creation',
        title: l10n.coursePanoramaLesson1Title,
        detail: l10n.coursePanoramaLesson1Detail,
        reference: 'GEN.1.1',
      ),
      CourseLesson(
        id: 'exodus',
        title: l10n.coursePanoramaLesson2Title,
        detail: l10n.coursePanoramaLesson2Detail,
        reference: 'EXO.3.1',
      ),
      CourseLesson(
        id: 'kingdom',
        title: l10n.coursePanoramaLesson3Title,
        detail: l10n.coursePanoramaLesson3Detail,
        reference: '1SA.16.1',
      ),
    ],
  ),
  CourseDef(
    id: 'gospels',
    icon: Icons.menu_book_outlined,
    title: l10n.courseGospelsTitle,
    description: l10n.courseGospelsDesc,
    lessons: [
      CourseLesson(
        id: 'kingdom',
        title: l10n.courseGospelsLesson1Title,
        detail: l10n.courseGospelsLesson1Detail,
        reference: 'MAT.4.17',
      ),
      CourseLesson(
        id: 'mercy',
        title: l10n.courseGospelsLesson2Title,
        detail: l10n.courseGospelsLesson2Detail,
        reference: 'LUK.15.1',
      ),
      CourseLesson(
        id: 'resurrection',
        title: l10n.courseGospelsLesson3Title,
        detail: l10n.courseGospelsLesson3Detail,
        reference: 'JHN.20.1',
      ),
    ],
  ),
  CourseDef(
    id: 'prayer',
    icon: Icons.self_improvement_outlined,
    title: l10n.coursePrayerTitle,
    description: l10n.coursePrayerDesc,
    lessons: [
      CourseLesson(
        id: 'trust',
        title: l10n.coursePrayerLesson1Title,
        detail: l10n.coursePrayerLesson1Detail,
        reference: 'PSA.23.1',
      ),
      CourseLesson(
        id: 'lament',
        title: l10n.coursePrayerLesson2Title,
        detail: l10n.coursePrayerLesson2Detail,
        reference: 'PSA.42.1',
      ),
      CourseLesson(
        id: 'praise',
        title: l10n.coursePrayerLesson3Title,
        detail: l10n.coursePrayerLesson3Detail,
        reference: 'PSA.100.1',
      ),
    ],
  ),
];
