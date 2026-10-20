/// Diferencias por palabra para la Comparación de textos (M5).
///
/// El original tiñe de azul las palabras que difieren de la versión base,
/// marca el inicio de cada tramo con un circulito rojo y deja el porcentaje
/// en línea al final de la fila. Aquí se calcula con una subsecuencia común
/// más larga (LCS) sobre palabras normalizadas: es suficiente para versículos
/// y no necesita dependencias.
library;

import 'dart:math' as math;

/// Resultado de comparar dos textos.
class WordDiff {
  const WordDiff({required this.percent, required this.changed});

  /// Porcentaje entero (0–100) de palabras de [other] que no están en la base.
  final int percent;

  /// Por cada fragmento de [other] (palabra + espacios), si difiere.
  final List<bool> changed;
}

/// Palabras con sus espacios finales, para reconstruir el texto sin perder
/// el formato original.
List<String> splitWords(String text) =>
    RegExp(r'\S+\s*').allMatches(text).map((m) => m.group(0)!).toList();

String _normalize(String token) => token
    .toLowerCase()
    .replaceAll(RegExp(r'[.,;:!?«»"“”()\[\]{}—–\-]'), '')
    .trim();

/// Compara [base] con [other] y devuelve el porcentaje y los fragmentos
/// cambiados de [other].
WordDiff compareWords(String base, String other) {
  final left = splitWords(base);
  final right = splitWords(other);
  final leftNorm = left.map(_normalize).toList();
  final rightNorm = right.map(_normalize).toList();

  // LCS sobre palabras con contenido (la puntuación no cuenta).
  final rows = left.length;
  final cols = right.length;
  final dp = List.generate(rows + 1, (_) => List<int>.filled(cols + 1, 0));
  for (var i = rows - 1; i >= 0; i--) {
    for (var j = cols - 1; j >= 0; j--) {
      final same = leftNorm[i].isNotEmpty && leftNorm[i] == rightNorm[j];
      dp[i][j] = same
          ? dp[i + 1][j + 1] + 1
          : math.max(dp[i + 1][j], dp[i][j + 1]);
    }
  }

  final matched = List<bool>.filled(cols, false);
  var i = 0;
  var j = 0;
  while (i < rows && j < cols) {
    if (leftNorm[i].isNotEmpty && leftNorm[i] == rightNorm[j]) {
      matched[j] = true;
      i++;
      j++;
    } else if (dp[i + 1][j] >= dp[i][j + 1]) {
      i++;
    } else {
      j++;
    }
  }

  final changed = List<bool>.generate(
    right.length,
    (index) => !matched[index] && rightNorm[index].isNotEmpty,
    growable: false,
  );
  final contentWords = rightNorm.where((word) => word.isNotEmpty).length;
  final changedWords = changed.where((value) => value).length;
  final percent =
      contentWords == 0 ? 0 : ((changedWords / contentWords) * 100).round();
  return WordDiff(percent: percent, changed: changed);
}
