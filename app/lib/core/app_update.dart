/// Verificación de actualizaciones para escritorio (sin telemetría): consulta
/// la última Release pública de GitHub y la compara con la versión local.
///
/// Sólo se consulta cuando el usuario lo pide (Ajustes ▸ Acerca de) o una
/// vez por arranque, sin rastrear nada; si falla la red se ignora en
/// silencio.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_version.dart';

class AppUpdateChecker {
  AppUpdateChecker({
    http.Client? client,
    this.repository = 'yojananyosef/aletheia',
    this.currentVersion = kAppVersion,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String repository;
  final String currentVersion;

  /// Consulta la última release. Devuelve null si no hay nada más nuevo o si
  /// la consulta falla (el resultado se ignora en silencio).
  Future<AppUpdateInfo?> checkLatestRelease() async {
    final Uri uri;
    try {
      uri = Uri.parse('https://api.github.com/repos/$repository/releases/latest');
    } on Object {
      return null;
    }
    try {
      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'aletheia-app/$currentVersion',
        },
      );
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final tag = json['tag_name'] as String? ?? '';
      if (tag.isEmpty) return null;
      final latest = _parseVersion(tag);
      if (latest == null) return null;
      final current = _parseVersion(currentVersion);
      if (current == null || !_isNewer(latest, current)) return null;
      return AppUpdateInfo(
        tag: tag,
        version: latest,
        url:
            json['html_url'] as String? ??
            'https://github.com/$repository/releases/latest',
      );
    } on Object {
      return null;
    }
  }
}

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.tag,
    required this.version,
    required this.url,
  });

  final String tag;

  /// Versión como lista numérica comparable (para mostrar y ordenar).
  final List<int> version;
  final String url;

  String get versionLabel => version.join('.');
}

/// Compara etiquetas tipo `v1.2.3` (acepta prefijos y sufijos numéricos).
List<int>? _parseVersion(String raw) {
  final match = RegExp(r'(\d+(?:\.\d+)*)').firstMatch(raw);
  if (match == null) return null;
  return match
      .group(1)!
      .split('.')
      .map((part) => int.tryParse(part) ?? 0)
      .toList();
}

/// Comparación lexicográfica numérica: true si [a] es estrictamente mayor.
bool _isNewer(List<int> a, List<int> b) {
  final length = a.length > b.length ? a.length : b.length;
  for (var i = 0; i < length; i++) {
    final av = i < a.length ? a[i] : 0;
    final bv = i < b.length ? b[i] : 0;
    if (av != bv) return av > bv;
  }
  return false;
}
