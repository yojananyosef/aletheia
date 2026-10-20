import 'package:flutter/material.dart';

/// Color de acento de un recurso.
///
/// El original identifica cada libro con su portada y usa su color en la
/// pestaña activa; el clon no copia portadas, así que usa un color propio por
/// recurso (el mismo en la pestaña, el chip del lector y las fichas). Los
/// recursos conocidos van en el mapa; el resto recibe uno estable derivado de
/// su id.
const _known = <String, Color>{
  'bible.rv1909': Color(0xFFE8710A),
  'bible.kjv': Color(0xFF1F4E8C),
  'factbook.core': Color(0xFF2E7D32),
  'devotional.daily': Color(0xFF5B4B9E),
};

const _palette = <Color>[
  Color(0xFFE8710A),
  Color(0xFF1F4E8C),
  Color(0xFF2E7D32),
  Color(0xFF5B4B9E),
  Color(0xFF8E3B46),
  Color(0xFF00695C),
];

Color resourceColorFor(String? resourceId, {String? resourceType}) {
  if (resourceId != null) {
    final known = _known[resourceId];
    if (known != null) return known;
  }
  final seed = resourceId ?? resourceType ?? 'aletheia';
  var hash = 0;
  for (final unit in seed.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return _palette[hash % _palette.length];
}
