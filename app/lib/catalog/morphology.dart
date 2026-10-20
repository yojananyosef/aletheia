/// Descripciones de morfología en español.
///
/// `assets/catalog/morphology.json` lo genera `import_stepbible.py` a partir
/// de TEHMC/TEGMC (CC BY 4.0) y de una traducción propia de sus categorías.
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final morphologyProvider = FutureProvider<Map<String, String>>((ref) async {
  try {
    final text = await rootBundle.loadString('assets/catalog/morphology.json');
    final raw = jsonDecode(text) as Map<String, dynamic>;
    return {
      for (final entry in raw.entries)
        if (entry.value is String) entry.key: entry.value as String,
    };
  } on Object {
    return const {};
  }
});

/// Descripción legible; si no hay traducción, conserva el código.
String morphologyLabel(Map<String, String>? map, String? code) {
  final value = code?.trim();
  if (value == null || value.isEmpty) return '';
  return map?[value] ?? value;
}
