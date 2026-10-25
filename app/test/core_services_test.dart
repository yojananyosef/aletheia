/// Pruebas de los servicios de cuidado de datos: resp/restauración sin
/// cuenta (`AppBackup`), registro de fallos rotativo (`CrashLog`) y los
/// documentos exportables (`ExportDocument`, `NoteExportDocument`).
library;

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart' as archive;
import 'package:flutter_test/flutter_test.dart';

import 'package:aletheia/core/app_backup.dart';
import 'package:aletheia/core/content_export.dart';
import 'package:aletheia/core/crash_log.dart';
import 'package:aletheia/catalog/document_models.dart';

Future<Directory> _tempDir(String tag) => Directory.systemTemp.createTemp(tag);

// ------------------------------------------------------------------ backup

void main() {
  group('AppBackup', () {
    late Directory dir;
    late AppBackup backup;

    setUp(() async {
      dir = await _tempDir('aletheia-backup-');
      backup = AppBackup(dataDirectory: dir);
      File('${dir.path}/aletheia.db').writeAsStringSync('base-de-prueba');
      Directory('${dir.path}/modules').createSync();
      File(
        '${dir.path}/modules/modules.json',
      ).writeAsStringSync('{"resources":[]}');
    });

    tearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    test('export zip with database, metadata and modules', () async {
      final dest = await backup.exportTo('${dir.path}/respaldo.zip');
      expect(dest.existsSync(), isTrue);
      final zip = archive.ZipDecoder().decodeBytes(dest.readAsBytesSync());
      final names = zip.files.map((f) => f.name).toSet();
      expect(names, containsAll(['aletheia.db', 'meta.json', 'modules.json']));
      final meta =
          jsonDecode(utf8.decode(zip.find('meta.json')!.content as List<int>))
              as Map<String, dynamic>;
      expect(meta['app'], 'aletheia');
      expect(meta['version'], isNotEmpty);
      final db = utf8.decode(zip.find('aletheia.db')!.content as List<int>);
      expect(db, 'base-de-prueba');
    });

    test('export without database fails', () async {
      File('${dir.path}/aletheia.db').deleteSync();
      await expectLater(
        backup.exportTo('${dir.path}/respaldo.zip'),
        throwsA(isA<BackupException>()),
      );
    });

    test('suggested file name has the standard prefix', () {
      expect(backup.suggestedFileName(), startsWith('aletheia-respaldo-'));
      expect(backup.suggestedFileName(), endsWith('.aletheiabackup'));
    });

    test('stageRestore validates and stages into restore-pending', () async {
      final zipFile = await backup.exportTo('${dir.path}/respaldo.zip');
      final summary = await backup.stageRestore(zipFile.path);
      expect(summary.includesModules, isTrue);
      final pending = Directory('${dir.path}/restore-pending');
      expect(pending.existsSync(), isTrue);
      expect(
        File('${pending.path}/aletheia.db').readAsStringSync(),
        'base-de-prueba',
      );
      expect(File('${pending.path}/modules.json').existsSync(), isTrue);
    });

    test('stageRestore rejects foreign or malformed files', () async {
      final bad = File('${dir.path}/no-es-zip.zip')
        ..writeAsStringSync('no es un zip');
      await expectLater(
        backup.stageRestore(bad.path),
        throwsA(isA<BackupException>()),
      );
      // Zip válido pero sin la base.
      final zip = archive.Archive()
        ..addFile(
          archive.ArchiveFile.bytes('meta.json', utf8.encode('{"app":"otra"}')),
        );
      final foreign = File('${dir.path}/otra-app.zip')
        ..writeAsBytesSync(archive.ZipEncoder().encode(zip));
      await expectLater(
        backup.stageRestore(foreign.path),
        throwsA(
          isA<BackupException>().having(
            (e) => e.message,
            'message',
            contains('aletheia.db'),
          ),
        ),
      );
    });

    test('applyPendingIfAny replaces the database and keeps a copy',
        () async {
      final zipFile = await backup.exportTo('${dir.path}/respaldo.zip');
      await backup.stageRestore(zipFile.path);
      // La base "en uso" cambia antes de reiniciar.
      File('${dir.path}/aletheia.db').writeAsStringSync('estado-actual');
      final applied = await AppBackup.applyPendingIfAny(dir);
      expect(applied, isTrue);
      expect(File('${dir.path}/aletheia.db').readAsStringSync(),
          'base-de-prueba');
      expect(
        File('${dir.path}/pre-restaurar/aletheia.db').readAsStringSync(),
        'estado-actual',
      );
      // El staging queda consumido.
      expect(Directory('${dir.path}/restore-pending').existsSync(), isFalse);
      // modules.json restaurado.
      expect(
        File('${dir.path}/modules/modules.json').readAsStringSync(),
        '{"resources":[]}',
      );
      // Un segundo pase no hace nada.
      expect(await AppBackup.applyPendingIfAny(dir), isFalse);
    });
  });

  group('CrashLog', () {
    late Directory dir;
    late CrashLog log;

    setUp(() async {
      dir = await _tempDir('aletheia-crash-');
      log = CrashLog(
        resolveFile: () async => File('${dir.path}/crash.log'),
        maxBytes: 100,
      );
    });

    tearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    test('records, reads and clears', () async {
      await log.record(
        'FlutterError',
        StateError('falla de prueba'),
        null,
        context: 'durante el arranque',
      );
      final content = await log.read();
      expect(content, isNotNull);
      expect(content, contains('FlutterError'));
      expect(content, contains('falla de prueba'));
      expect(content, contains('contexto: durante el arranque'));

      await log.clear();
      expect(await log.read(), isNull);
    });

    test('rotates to .1 when the file exceeds maxBytes', () async {
      final longError = 'x' * 150;
      await log.record('Zone', longError, null);
      await log.record('Zone', longError, null);
      expect(File('${dir.path}/crash.log.1').existsSync(), isTrue);
      expect(File('${dir.path}/crash.log').existsSync(), isTrue);
      // La rotación conserva entradas legibles en ambas partes.
      expect(
        await File('${dir.path}/crash.log.1').readAsString(),
        contains('=== '),
      );
    });
  });

  group('ExportDocument', () {
    const passage = ExportDocument(
      title: 'Juan 3',
      footer: 'Reina-Valera 1909 · dominio público',
      blocks: [
        ChapterNumberBlock(3),
        VerseGroupBlock(
          verses: [
            Verse(
              n: 16,
              inlines: [
                TextInline('Porque ', style: 'red'),
                TextInline('de tal manera amó *Dios* al mundo'),
              ],
            ),
            Verse(
              n: 17,
              inlines: [
                TextInline('y una nota'),
                FootnoteRef('fn-1', label: 'a'),
                LineInline(),
                TextInline('y una línea nueva'),
              ],
            ),
          ],
        ),
        RuleBlock(),
      ],
    );

    test('markdown keeps verse numbers, styles and footer', () {
      final md = passage.build(ExportFormat.markdown);
      expect(md, startsWith('# Juan 3'));
      expect(md, contains('**16** Porque de tal manera amó \\*Dios\\* al mundo'));
      expect(md, contains('[a]'));
      expect(md, contains('---'));
      expect(md, endsWith('*Reina-Valera 1909 · dominio público*\n'));
    });

    test('html is a printable standalone document', () {
      final html = passage.build(ExportFormat.html);
      expect(html, startsWith('<!DOCTYPE html>'));
      expect(html, contains('<title>Juan 3</title>'));
      expect(html, contains('lang="es"'));
      expect(html, contains('<sup>16</sup>'));
      expect(html, contains('y una nota<sup>[a]</sup>'));
      expect(html, contains('<footer>Reina-Valera 1909 · dominio público</footer>'));
    });

    test('plain text drops markup', () {
      final txt = passage.build(ExportFormat.plainText);
      expect(txt.contains('#'), isFalse);
      expect(txt.contains('**'), isFalse);
      expect(txt, contains('16 Porque'));
      expect(txt, contains('y una línea nueva'));
    });
  });

  group('NoteExportDocument', () {
    const note = NoteExportDocument(
      title: 'Sobre Juan 3,16',
      body: '**Idea central:** el amor de _Dios_.',
      citation: '— Juan 3:16',
      tags: ['nuevo testamento', 'amor'],
    );

    test('markdown embeds citation and tags', () {
      final md = note.build(ExportFormat.markdown);
      expect(md, startsWith('# Sobre Juan 3,16'));
      expect(md, contains('*— Juan 3:16*'));
      expect(md, contains('**Idea central:**'));
      expect(md, contains('Etiquetas: `nuevo testamento` · `amor`'));
    });

    test('html and plain text convert the markdown-lite body', () {
      final html = note.build(ExportFormat.html);
      expect(html, contains('<strong>Idea central:</strong>'));
      final txt = note.build(ExportFormat.plainText);
      expect(txt, contains('Idea central: el amor de Dios.'));
      expect(txt.contains('`'), isFalse);
    });
  });
}
