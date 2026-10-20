/// Contenido propio relacionado con una referencia (drawer «Ideas», M6.1).
///
/// El original muestra en «Pasajes relacionados» las referencias cruzadas del
/// pasaje y en «Libros relacionados» los recursos de la biblioteca que hablan
/// de él. Desde la mejora de profundidad, los pasajes combinan el Treasury of
/// Scripture Knowledge (TSK) con las referencias citadas por Factbook,
/// devocional y comentario; los libros incluyen esos recursos.
library;

import 'dart:math' show min;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/catalog_gateway.dart';
import '../catalog/document_models.dart';
import '../catalog/sections_repository.dart';

/// Recursos propios que aportan contenido relacionado.
const kRelatedResourceIds = [
  'factbook.core',
  'devotional.daily',
  'commentary.matthew-henry-concise',
];

/// Sección propia que cita la referencia actual.
class RelatedSection {
  const RelatedSection({required this.resourceId, required this.section});

  final String resourceId;
  final SectionSummary section;
}

/// Fuente de una referencia citada (sección propia).
class RelatedSource {
  const RelatedSource({required this.resourceId, required this.title});

  final String resourceId;
  final String title;
}

/// Pasaje citado junto a la referencia actual por el catálogo propio.
class RelatedPassage {
  const RelatedPassage({required this.reference, required this.sources});

  final String reference;
  final List<RelatedSource> sources;
}

class RelatedContent {
  const RelatedContent({this.books = const [], this.passages = const []});

  final List<RelatedSection> books;
  final List<RelatedPassage> passages;

  bool get isEmpty => books.isEmpty && passages.isEmpty;
}

/// Normaliza `JHN.3.16-18` → `JHN.3.16` y compara los segmentos comunes.
///
/// `JHN.3` (capítulo entero) y `JHN.3.16` se consideran la misma ubicación;
/// `JHN.3.15` y `JHN.3.16` no.
bool referencesOverlap(String a, String b) {
  String norm(String value) {
    final dash = value.indexOf('-');
    return (dash == -1 ? value : value.substring(0, dash)).trim().toUpperCase();
  }

  final ca = norm(a).split('.');
  final cb = norm(b).split('.');
  final n = min(ca.length, cb.length);
  if (n < 2) return false;
  for (var i = 0; i < n; i++) {
    if (ca[i] != cb[i]) return false;
  }
  return true;
}

final relatedContentProvider =
    FutureProvider.family<RelatedContent, String>((ref, reference) async {
  final repository = ref.watch(sectionsRepositoryProvider);
  final gateway = ref.watch(catalogGatewayProvider);
  final books = <RelatedSection>[];
  final passages = <String, List<RelatedSource>>{};
  final seenSources = <String>{};

  for (final resourceId in kRelatedResourceIds) {
    List<SectionSummary> index;
    try {
      index = await repository.loadIndex(resourceId);
    } on Object {
      // Recurso no disponible (servicio caído sin assets locales): se omite.
      continue;
    }
    for (final section in index) {
      final cited = <String>[
        if (section.reference != null) section.reference!,
        ...section.references,
      ];
      if (!cited.any((r) => referencesOverlap(r, reference))) continue;
      books.add(RelatedSection(resourceId: resourceId, section: section));
      final sourceKey = '$resourceId/${section.id}';
      if (!seenSources.add(sourceKey)) continue;
      for (final other in cited) {
        if (referencesOverlap(other, reference)) continue;
        final sources = passages.putIfAbsent(other, () => []);
        if (sources.length < 3) {
          sources.add(
            RelatedSource(resourceId: resourceId, title: section.title),
          );
        }
      }
    }
  }

  // Referencias cruzadas reales del TSK. Si el índice no las trae (una
  // instalación antigua), el drawer sigue funcionando con el contenido propio.
  try {
    final crossReferences = await gateway.crossReferences(
      reference,
      limit: 40,
    );
    for (final crossReference in crossReferences) {
      if (crossReference.reference.isEmpty ||
          referencesOverlap(crossReference.reference, reference)) {
        continue;
      }
      final sources = passages.putIfAbsent(
        crossReference.reference,
        () => [],
      );
      if (sources.every((source) => source.resourceId != 'tsk')) {
        sources.add(
          const RelatedSource(
            resourceId: 'tsk',
            title: 'Treasury of Scripture Knowledge',
          ),
        );
      }
    }
  } on Object {
    // Sin índice de referencias cruzadas: se conserva el contenido propio.
  }

  final sortedPassages = passages.entries
      .map((e) => RelatedPassage(reference: e.key, sources: e.value))
      .toList()
    ..sort((a, b) {
      final byCount = b.sources.length.compareTo(a.sources.length);
      return byCount != 0 ? byCount : a.reference.compareTo(b.reference);
    });
  books.sort((a, b) => a.section.title.compareTo(b.section.title));

  return RelatedContent(books: books, passages: sortedPassages);
});
