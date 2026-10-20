/// Acceso a las traducciones (M3, ARB + gen-l10n).
///
/// El idioma de diseño del clon es el español: si un widget se monta sin los
/// delegados de localización (pruebas de widget, capturas) se usa el paquete
/// español como respaldo en lugar de fallar.
library;

import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

export '../l10n/app_localizations.dart';

AppLocalizations _resolve(BuildContext context) =>
    AppLocalizations.of(context) ?? lookupAppLocalizations(const Locale('es'));

extension L10nContext on BuildContext {
  /// Traducciones del idioma activo (con respaldo en español).
  AppLocalizations get l10n => _resolve(this);

  /// Código de idioma activo sin región (`es`, `en`): nombres de libros, etc.
  String get l10nLang => _resolve(this).localeName.split('_').first;
}

/// Idiomas que puede fijar el usuario en Ajustes (`null` = sistema).
const Map<String, String?> kLanguageOptions = {
  'system': null,
  'es': 'es',
  'en': 'en',
};
