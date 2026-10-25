/// Providers de cuidado de datos: registro de fallos y respaldo/restauración.
///
/// En escritorio `main()` crea ambos sobre el directorio de datos real; en
/// web quedan en null (la persistencia es IndexedDB y estas herramientas no
/// aplican).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_backup.dart';
import 'crash_log.dart';

final crashLogProvider = Provider<CrashLog?>((ref) => null);

final appBackupProvider = Provider<AppBackup?>((ref) => null);
