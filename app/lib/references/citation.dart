/// Citas bibliográficas del clon (Ajustes 8.6 → más ▾ del panel).
library;

/// Formatos de cita disponibles (`kCitationStyles`).
///
/// Para un pasaje bíblico los manuales difieren poco: la nota completa de
/// Turabian usa el título del recurso, Chicago y SBL la abreviatura, y el
/// estilo propio del clon separa con una raya. Con
/// «Enlazar las citas copiadas» la cita se envuelve en un enlace interno
/// estilo Markdown (`ref:JHN.1.1`) que las Notas (M4) podrán resolver.
String formatCitation({
  required String reference,
  required String title,
  required String abbrev,
  required String style,
  bool hyperlink = false,
  String? canonical,
}) {
  final source = abbrev.isNotEmpty ? abbrev : title;
  final label = switch (style) {
    'sbl' => '$reference ($source)',
    'chicago' => '$reference ($source).',
    'plain' => '$reference — $source',
    // Turabian (9.ª ed., nota completa): título del recurso.
    _ => '$reference (${title.isNotEmpty ? title : source}).',
  };
  if (hyperlink && canonical != null && canonical.isNotEmpty) {
    return '[$label](ref:$canonical)';
  }
  return label;
}
