/// Documentos de estudio propios (M6.4).
///
/// Son textos breves de Aletheia, no copias de obras licenciadas. Se guardan
/// como cadenas localizadas con encabezados `##` y párrafos separados por
/// líneas en blanco; el panel los presenta en una columna de lectura.
library;

import 'package:flutter/material.dart';

import '../core/localization.dart';

class ToolDocument {
  const ToolDocument({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
  });

  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final String body;
}

List<ToolDocument> documentDefinitions(AppLocalizations l10n) => [
  ToolDocument(
    id: 'reading',
    icon: Icons.menu_book_outlined,
    title: l10n.documentReadingTitle,
    subtitle: l10n.documentReadingSubtitle,
    body: l10n.documentReadingBody,
  ),
  ToolDocument(
    id: 'timeline',
    icon: Icons.timeline_outlined,
    title: l10n.documentTimelineTitle,
    subtitle: l10n.documentTimelineSubtitle,
    body: l10n.documentTimelineBody,
  ),
  ToolDocument(
    id: 'glossary',
    icon: Icons.translate_outlined,
    title: l10n.documentGlossaryTitle,
    subtitle: l10n.documentGlossarySubtitle,
    body: l10n.documentGlossaryBody,
  ),
];
