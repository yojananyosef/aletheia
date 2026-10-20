import 'database.dart';

/// En web no existe el directorio de datos nativo ni los JSON de M0–M4.
Future<LegacyImport> importLegacyJson(AletheiaDatabase db, Object dir) async =>
    const LegacyImport(workspace: false, notes: false);
