import 'package:sqlite3/common.dart';

CommonDatabase openDatabaseFile(String path) {
  throw UnsupportedError(
    'AletheiaDatabase.open solo está disponible en plataformas nativas; '
    'en web usa openAppDatabase().',
  );
}

CommonDatabase openMemoryDatabase() {
  throw UnsupportedError(
    'AletheiaDatabase.memory solo está disponible en plataformas nativas.',
  );
}
