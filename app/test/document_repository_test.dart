import 'package:flutter_test/flutter_test.dart';
import 'package:aletheia/catalog/document_models.dart';
import 'package:aletheia/catalog/document_repository.dart';
import 'package:aletheia/catalog/sections_repository.dart';

String _plainText(Verse verse) =>
    verse.inlines.whereType<TextInline>().map((i) => i.text).join();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('el manifest de la RV1909 trae 66 libros e índice de capítulos', () async {
    final manifest = await AssetDocumentRepository().loadManifest('bible.rv1909');
    expect(manifest.title, 'Reina-Valera 1909');
    expect(manifest.license, contains('Dominio'));
    expect(manifest.books, hasLength(66));
    expect(manifest.books.first.code, 'GEN');
    expect(manifest.books.last.code, 'REV');

    final juan = manifest.bookByCode('JHN')!;
    expect(juan.name, 'Juan');
    expect(juan.chapters, hasLength(21));
    expect(juan.chapters.first.verses, 51);
  });

  test('Juan 1:1 llega como versículos numerados', () async {
    final book = await AssetDocumentRepository().loadBook('bible.rv1909', 'JHN');
    final chapter = book.chapter(1)!;
    expect(chapter.blocks.first, isA<ChapterNumberBlock>());
    final verses = chapter.blocks
        .whereType<VerseGroupBlock>()
        .expand((g) => g.verses)
        .toList();
    expect(verses, hasLength(51));
    expect(_plainText(verses.first),
        'EN el principio era el Verbo, y el Verbo era con Dios, y el Verbo era Dios.');
  });

  test('las adiciones USFM (\\add) se convierten en spans itálicos', () async {
    final book = await AssetDocumentRepository().loadBook('bible.rv1909', 'OBA');
    final verse = book
        .chapter(1)!
        .blocks
        .whereType<VerseGroupBlock>()
        .expand((g) => g.verses)
        .firstWhere((v) => v.n == 6);
    final italics = verse.inlines
        .whereType<TextInline>()
        .where((i) => i.style == 'italic')
        .map((i) => i.text)
        .toList();
    expect(italics, contains('las cosas de'));
  });

  test('la KJV también se lee de los assets (autonomía local)', () async {
    final repository = AssetDocumentRepository();
    final manifest = await repository.loadManifest('bible.kjv');
    expect(manifest.title, 'King James Version');
    expect(manifest.abbrev, 'KJV');
    expect(manifest.books, hasLength(66));

    final genesis = await repository.loadBook('bible.kjv', 'GEN');
    final verse = genesis
        .chapter(1)!
        .blocks
        .whereType<VerseGroupBlock>()
        .expand((group) => group.verses)
        .first;
    expect(_plainText(verse),
        'In the beginning God created the heaven and the earth.');
  });

  test('nextLocation/previousLocation recorren libros y capítulos', () async {
    final manifest = await AssetDocumentRepository().loadManifest('bible.rv1909');
    expect(manifest.nextLocation('JHN', 1), (book: 'JHN', chapter: 2));
    expect(manifest.nextLocation('GEN', 50), (book: 'EXO', chapter: 1));
    expect(manifest.previousLocation('EXO', 1), (book: 'GEN', chapter: 50));
    expect(manifest.previousLocation('GEN', 1), isNull);
    expect(manifest.nextLocation('REV', 22), isNull);
  });

  _studyTests();
}

// ------------------------------------------------- textos originales y léxico

void _studyTests() {
  test('TAHOT conserva el hebreo, la morfología y los títulos de los salmos',
      () async {
    final repository = AssetDocumentRepository();
    final manifest = await repository.loadManifest('bible.tahot');
    expect(manifest.rtl, isTrue);
    expect(manifest.books, hasLength(39));
    expect(manifest.bookByCode('PSA')!.chapters, hasLength(150));

    final psalms = await repository.loadBook('bible.tahot', 'PSA');
    final chapter = psalms.chapter(3)!;
    final verses = chapter.blocks
        .whereType<VerseGroupBlock>()
        .expand((group) => group.verses)
        .toList();
    expect(verses.first.n, 0, reason: 'título del salmo como versículo 0');
    final titleWord = verses.first.inlines.whereType<TextInline>().first;
    expect(titleWord.text, contains('מִזְמ'));
    expect(titleWord.strong, 'H4210');
    expect(titleWord.morph, isNotEmpty);
    expect(titleWord.translit, isNotEmpty);
    expect(
      verses.any(
        (verse) => verse.inlines.whereType<TextInline>().any(
              (word) => word.strong == 'H3068',
            ),
      ),
      isTrue,
    );
  });

  test('TAGNT trae griego, Strong desambiguado, lema y glosa', () async {
    final repository = AssetDocumentRepository();
    final manifest = await repository.loadManifest('bible.tagnt');
    expect(manifest.rtl, isFalse);
    expect(manifest.books, hasLength(27));

    final john = await repository.loadBook('bible.tagnt', 'JHN');
    final verse = john
        .chapter(1)!
        .blocks
        .whereType<VerseGroupBlock>()
        .expand((group) => group.verses)
        .firstWhere((verse) => verse.n == 1);
    final words = verse.inlines.whereType<TextInline>().toList();
    expect(words.first.text, contains('Ἐν'));
    expect(words.first.strong, 'G1722');
    expect(words.first.morph, 'PREP');
    expect(words.first.lemma, 'ἐν');
    expect(words.first.gloss, contains('in'));
    expect(words[1].strong, 'G0746');
    expect(words[1].lemma, 'ἀρχή');
  });

  test('el léxico Strong embebido sirve hebreo y griego', () async {
    final sections = AssetSectionsRepository();
    final hebrew = await sections.loadSection('lexicon.strongs', 'H0430');
    expect(hebrew, isNotNull);
    expect(hebrew!.summary.title, contains('H0430'));
    expect(hebrew.summary.title, contains('אֱלֹהִים'));
    expect(hebrew.summary.summary, 'Dios');
    final hebrewText = hebrew.blocks
        .whereType<VerseGroupBlock>()
        .expand((group) => group.verses)
        .expand((verse) => verse.inlines)
        .whereType<TextInline>()
        .map((inline) => inline.text)
        .join();
    expect(hebrewText, contains("Strong's Hebrew Dictionary"));
    expect(hebrewText, contains('dominio público'));

    final greek = await sections.loadSection('lexicon.strongs', 'G2316');
    expect(greek, isNotNull);
    expect(greek!.summary.title, contains('θε'));
    final greekText = greek.blocks
        .whereType<VerseGroupBlock>()
        .expand((group) => group.verses)
        .expand((verse) => verse.inlines)
        .whereType<TextInline>()
        .map((inline) => inline.text)
        .join();
    expect(greekText, contains('TBESG'));
  });
}
