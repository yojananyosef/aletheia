import 'dart:io';

import 'package:aletheia/catalog/catalog_client.dart';
import 'package:aletheia/catalog/catalog_gateway.dart';
import 'package:aletheia/catalog/document_models.dart';
import 'package:aletheia/catalog/local_catalog_index.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/catalog_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory directory;
  late CatalogGateway gateway;

  setUpAll(() async {
    // El catálogo íntegro vive en el repositorio (el bundle ya es ligero):
    // el gateway y el índice FTS5 leen de ahí con la fuente de disco.
    directory = await Directory.systemTemp.createTemp('aletheia-index-');
    gateway = CatalogGateway(
      mode: 'local',
      client: CatalogClient(baseUrl: 'http://127.0.0.1:1'),
      source: repoCatalogSource(),
      localIndex: LocalCatalogIndex(
        source: repoCatalogSource(),
        cacheDirectoryProvider: () async => directory.path,
      ),
    );
  });

  tearDownAll(() async {
    gateway.dispose();
    await directory.delete(recursive: true);
  });

  test(
    'gateway en modo local lista, filtra y busca en los recursos incluidos',
    () async {
      final all = await gateway.listResources();
      expect(
        all.total,
        17,
        reason: '11 Biblias + léxico, comentario, diccionario, gazetteer y M5',
      );
      expect(
        all.items.map((item) => item.id),
        containsAll([
          'bible.rv1909',
          'bible.kjv',
          'bible.asv',
          'bible.bll',
          'bible.tahot',
          'bible.tagnt',
          'bible.sblm',
          'bible.bes',
          'bible.vbl',
          'lexicon.strongs',
          'commentary.matthew-henry-concise',
          'dictionary.easton',
          'devotional.daily',
          'factbook.core',
        ]),
      );
      expect(
        all.items.firstWhere((item) => item.id == 'bible.rv1909').licenseKind,
        'public-domain',
      );
      expect(all.facets['type']?['bible'], 11);
      expect(all.facets['type']?['commentary'], 1);
      expect(all.facets['type']?['dictionary'], 2);
      expect(all.facets['type']?['devotional'], 1);
      expect(all.facets['type']?['factbook'], 1);
      expect(all.facets['type']?['dataset'], 1);
      expect(all.facets['language']?['es'], 8);
      expect(all.facets['language']?['en'], 6);
      expect(all.facets['language']?['he'], 1);
      expect(all.facets['language']?['grc'], 1);
      expect(all.facets['language']?['mul'], 1);

      final byQuery = await gateway.listResources(query: 'Casiodoro');
      expect(byQuery.total, 1);

      // «Valera» aparece en la RV1909 y en la descripción del devocional.
      final accented = await gateway.listResources(query: 'Valera');
      expect(accented.total, 2);

      final devotionals = await gateway.listResources(type: 'devotional');
      expect(devotionals.total, 1);
      final factbooks = await gateway.listResources(type: 'factbook');
      expect(factbooks.total, 1);

      final noMatch = await gateway.listResources(query: 'xyz');
      expect(noMatch.total, 0);

      final byType = await gateway.listResources(type: 'commentary');
      expect(byType.total, 1);
      final dictionaries = await gateway.listResources(type: 'dictionary');
      expect(dictionaries.total, 2);
      expect(
        dictionaries.items.map((item) => item.id),
        contains('lexicon.strongs'),
      );
    },
  );

  test(
    'el índice local busca Biblias sin servicio y respeta el recurso',
    () async {
      final rv = await gateway.search(
        query: '"el principio era el Verbo"',
        scope: 'bible',
        resource: 'bible.rv1909',
      );
      expect(rv.total, greaterThan(0));
      expect(rv.scope, 'bible');
      final first = rv.hits.first;
      expect(first.resourceId, 'bible.rv1909');
      expect(first.ref, 'JHN.1.1');
      expect(first.citation, 'Juan 1:1');
      expect(first.snippet, contains('<em>'));

      final allSpanish = await gateway.search(
        query: '"el principio era el Verbo"',
        scope: 'bible',
      );
      expect(
        allSpanish.hits.map((hit) => hit.resourceId),
        contains('bible.rv1909'),
        reason: 'la frase también aparece en otras Biblias españolas',
      );

      final kjv = await gateway.search(
        query: '"In the beginning"',
        scope: 'bible',
        resource: 'bible.kjv',
      );
      expect(kjv.total, greaterThan(0));
      expect(kjv.hits.every((hit) => hit.resourceId == 'bible.kjv'), isTrue);
      expect(
        kjv.hits.any((hit) => hit.ref == 'GEN.1.1'),
        isTrue,
        reason: 'la KJV también está empaquetada',
      );

      final books = await gateway.search(query: 'Dios', scope: 'books');
      expect(books.total, greaterThan(0));
      expect(
        books.hits.map((hit) => hit.resourceType).toSet(),
        containsAll(['factbook', 'devotional']),
      );
      final factbookHit = books.hits.firstWhere(
        (hit) => hit.resourceType == 'factbook',
      );
      expect(factbookHit.ref, factbookHit.sectionId);
      expect(factbookHit.book, isEmpty);
      expect(factbookHit.citation, isNot(contains(':')));
      expect(factbookHit.snippet, isNotEmpty);
    },
  );

  test(
    'el índice local busca Factbook y devocional por tipo y ámbito',
    () async {
      final topics = await gateway.search(query: 'gracia', scope: 'factbook');
      expect(topics.total, greaterThan(0));
      expect(
        topics.hits.every((hit) => hit.resourceType == 'factbook'),
        isTrue,
      );
      expect(topics.hits.first.resourceId, 'factbook.core');

      final devotional = await gateway.search(
        query: 'Dios',
        scope: 'books',
        type: 'devotional',
      );
      expect(devotional.total, greaterThan(0));
      expect(
        devotional.hits.every((hit) => hit.resourceType == 'devotional'),
        isTrue,
      );
      expect(devotional.hits.first.ref, startsWith('dayofyear.'));

      // Las referencias bíblicas de una sección también se indexan.
      final referenced = await gateway.search(
        query: 'type:devotional Lamentaciones 3:22',
      );
      expect(referenced.total, greaterThan(0));
      expect(referenced.hits.first.ref, 'dayofyear.01.01');

      // Igual que el servicio, un ámbito solo ya es una consulta válida.
      final onlyScope = await gateway.search(query: '', scope: 'factbook');
      expect(onlyScope.total, greaterThan(0));
      expect(
        onlyScope.hits.every((hit) => hit.resourceType == 'factbook'),
        isTrue,
      );
    },
  );

  test('NEAR y los campos de estudio funcionan en el índice local', () async {
    final near = await gateway.search(
      query: 'principio NEAR Verbo',
      scope: 'bible',
    );
    expect(near.total, greaterThan(0));
    expect(near.hits.map((hit) => hit.ref), contains('JHN.1.1'));

    final near5 = await gateway.search(
      query: 'principio NEAR/5 Verbo',
      scope: 'bible',
    );
    expect(near5.total, greaterThan(0));
    expect(near5.hits.map((hit) => hit.ref), contains('JHN.1.1'));

    final before = await gateway.search(
      query: 'principio BEFORE Verbo',
      scope: 'bible',
    );
    expect(before.total, greaterThan(0));
    expect(before.hits.map((hit) => hit.ref), contains('JHN.1.1'));

    final reversed = await gateway.search(
      query: 'Verbo BEFORE principio',
      scope: 'bible',
    );
    expect(reversed.hits.map((hit) => hit.ref), isNot(contains('JHN.1.1')));

    final passage = await gateway.search(query: 'bible:"Jn 3"');
    expect(passage.total, greaterThan(0));
    expect(
      passage.hits.every((hit) => hit.book == 'JHN' && hit.chapter == 3),
      isTrue,
    );

    final typed = await gateway.search(query: 'type:factbook gracia');
    expect(typed.total, greaterThan(0));
    expect(typed.hits.every((hit) => hit.resourceType == 'factbook'), isTrue);

    final english = await gateway.search(query: 'language:en beginning');
    final englishIds = english.hits.map((hit) => hit.resourceId).toSet();
    expect(
      englishIds,
      containsAll(['bible.kjv', 'bible.asv']),
      reason: 'las dos traducciones inglesas comparten «beginning»',
    );
    expect(
      englishIds.difference({
        'bible.kjv',
        'bible.asv',
        'bible.bsb',
        'bible.web',
        'commentary.matthew-henry-concise',
        'dictionary.easton',
      }),
      isEmpty,
    );

    final john = await gateway.search(query: 'principio', book: 'JHN');
    expect(john.total, greaterThan(0));
    expect(john.hits.every((hit) => hit.book == 'JHN'), isTrue);
  });

  test('los ámbitos Morfología, Mapas y Multimedia usan datos locales', () async {
    final morphology = await gateway.search(
      query: 'Vqp3ms',
      scope: 'morph',
    );
    expect(morphology.total, greaterThan(0));
    expect(
      morphology.hits.every((hit) => hit.resourceType == 'morphology'),
      isTrue,
    );
    expect(morphology.hits.first.citation, contains('Vqp3ms'));
    expect(morphology.hits.first.detail, isNotEmpty);

    final allMorphology = await gateway.search(query: '', scope: 'morph');
    expect(allMorphology.total, greaterThan(4000));

    final maps = await gateway.search(query: '', scope: 'maps');
    expect(maps.total, 23);
    expect(
      maps.hits.map((hit) => hit.resourceType).toSet(),
      containsAll(['factbook', 'commentary']),
    );

    final jerusalem = await gateway.search(query: 'Jerusalén', scope: 'maps');
    expect(jerusalem.total, greaterThan(0));
    expect(
      jerusalem.hits.any((hit) => hit.citation.contains('Jerusalén')),
      isTrue,
    );

    final media = await gateway.search(query: '', scope: 'media');
    expect(media.total, 23);
    expect(media.hits.every((hit) => hit.abbrev == 'MEDIA'), isTrue);
  });

  test('las facetas de búsqueda cuentan tipos, idiomas y libros', () async {
    final result = await gateway.search(query: 'God OR Dios', pageSize: 5);
    expect(result.facets['type']?['bible'], greaterThan(0));
    expect(result.facets['type']?['factbook'], greaterThan(0));
    expect(result.facets['type']?['devotional'], greaterThan(0));
    expect(result.facets['language']?['es'], greaterThan(0));
    expect(result.facets['language']?['en'], greaterThan(0));
    expect(result.facets['book']?['JHN'], greaterThan(0));

    final filtered = await gateway.search(query: 'Dios', type: 'devotional');
    expect(
      filtered.hits.every((hit) => hit.resourceType == 'devotional'),
      isTrue,
    );
    // La faceta de tipo excluye su propio filtro para poder cambiarlo.
    expect(filtered.facets['type']?.keys, containsAll(['bible', 'devotional']));
    expect(filtered.facets['book'], isEmpty);
  });

  test('los campos inválidos explican el error', () async {
    await expectLater(
      gateway.search(query: 'bible:"Libro inventado 3"'),
      throwsA(
        isA<CatalogException>().having(
          (error) => error.message,
          'mensaje',
          contains('referencia bíblica no válida'),
        ),
      ),
    );
    await expectLater(
      gateway.search(query: 'book:NoExiste'),
      throwsA(
        isA<CatalogException>().having(
          (error) => error.message,
          'mensaje',
          contains('libro no encontrado'),
        ),
      ),
    );
    await expectLater(
      gateway.search(query: 'Dios', book: 'NoExiste'),
      throwsA(
        isA<CatalogException>().having(
          (error) => error.message,
          'mensaje',
          contains('libro no encontrado'),
        ),
      ),
    );
  });

  test('la paginación local devuelve páginas disjuntas', () async {
    final first = await gateway.search(query: 'Dios', pageSize: 2);
    final second = await gateway.search(query: 'Dios', page: 2, pageSize: 2);
    expect(first.total, greaterThan(10));
    expect(second.total, first.total);
    expect(first.hits, hasLength(2));
    expect(second.hits, hasLength(2));
    expect(
      first.hits.map((hit) => hit.ref).toSet(),
      isNot(contains(second.hits.first.ref)),
    );
  });

  test(
    'las consultas inválidas y los recursos desconocidos explican el error',
    () async {
      await expectLater(
        gateway.search(query: 'AND Dios'),
        throwsA(
          isA<CatalogException>().having(
            (error) => error.message,
            'mensaje',
            contains('no puede ir al principio'),
          ),
        ),
      );
      await expectLater(
        gateway.search(query: '"sin cerrar'),
        throwsA(
          isA<CatalogException>().having(
            (error) => error.message,
            'mensaje',
            contains('comilla sin cerrar'),
          ),
        ),
      );
      await expectLater(
        gateway.search(query: 'Dios', scope: 'desconocido'),
        throwsA(
          isA<CatalogException>().having(
            (error) => error.message,
            'mensaje',
            contains('scope'),
          ),
        ),
      );
      await expectLater(
        gateway.search(query: 'Dios', resource: 'bible.nope'),
        throwsA(
          isA<CatalogException>()
              .having((error) => error.status, 'status', 404)
              .having(
                (error) => error.message,
                'mensaje',
                contains('no encontrado'),
              ),
        ),
      );
    },
  );

  test('health informa del catálogo local y del índice', () async {
    final health = await gateway.health();
    expect(health, isNotNull);
    expect(health!.local, isTrue);
    expect(health.resources, 17);
    expect(health.verses, 311054);
    expect(health.sections, 24942);
    expect(health.crossReferences, 376083);
  });

  test(
    'las referencias cruzadas del TSK se consultan en el índice local',
    () async {
      final refs = await gateway.crossReferences('JHN.3.16', limit: 20);
      expect(refs, isNotEmpty);
      expect(refs.map((ref) => ref.reference), contains('ROM.5.8'));

      final chapter = await gateway.crossReferences('JHN.3', limit: 20);
      expect(chapter, isNotEmpty);
      expect(chapter.length, lessThanOrEqualTo(20));
    },
  );

  test(
    'en automático cae al índice local si el servicio no responde',
    () async {
      final automatic = CatalogGateway(
        mode: 'auto',
        client: CatalogClient(baseUrl: 'http://127.0.0.1:1'),
        source: repoCatalogSource(),
        localIndex: LocalCatalogIndex(
          source: repoCatalogSource(),
          cacheDirectoryProvider: () async => directory.path,
        ),
      );
      addTearDown(automatic.dispose);

      final result = await automatic.search(
        query: '"el principio era el Verbo"',
        scope: 'bible',
      );
      expect(result.hits.first.ref, 'JHN.1.1');

      final health = await automatic.health();
      expect(health, isNotNull);
      expect(health!.local, isTrue);
    },
  );

  test('las secciones embebidas de M5 se leen de los assets', () async {
    final sections = repoSectionsRepository();

    final devotional = await sections.loadIndex('devotional.daily');
    expect(devotional.length, 366, reason: 'incluye el 29 de febrero');
    expect(devotional.first.id, startsWith('dayofyear.'));
    expect(devotional.map((s) => s.id), contains('dayofyear.10.19'));

    final day = await sections.loadSection(
      'devotional.daily',
      'dayofyear.10.19',
    );
    expect(day, isNotNull);
    expect(day!.summary.reference, isNotNull);
    expect(day.blocks, isNotEmpty);

    final factbook = await sections.loadIndex('factbook.core');
    expect(factbook.length, 32);
    final grace = await sections.loadSection('factbook.core', 'gracia');
    expect(grace, isNotNull);
    expect(grace!.summary.references, isNotEmpty);
    expect(grace.blocks, isNotEmpty);

    final jerusalen = await sections.loadSection('factbook.core', 'jerusalen');
    expect(jerusalen, isNotNull);
    final factbookMap = jerusalen!.blocks.whereType<MapBlock>().single;
    expect(factbookMap.title, contains('Jerusalén'));
    expect(factbookMap.markers, isNotEmpty);

    expect(await sections.loadSection('factbook.core', 'no-existe'), isNull);
  });

  test(
    'comentario y diccionario se cargan por sección desde los assets',
    () async {
      final sections = repoSectionsRepository();

      final commentary = await sections.loadIndex(
        'commentary.matthew-henry-concise',
      );
      final john3 = await sections.loadSection(
        'commentary.matthew-henry-concise',
        'JHN.3',
      );
      expect(john3, isNotNull);
      expect(john3!.blocks.whereType<MapBlock>(), hasLength(1));
      expect(commentary.length, 1189);
      final john = await sections.loadSection(
        'commentary.matthew-henry-concise',
        'JHN.3',
      );
      expect(john, isNotNull);
      expect(john!.summary.title, 'John 3');
      expect(john.blocks, isNotEmpty);

      final dictionary = await sections.loadIndex('dictionary.easton');
      expect(dictionary.length, 3961);
      final grace = await sections.loadSection('dictionary.easton', 'grace');
      expect(grace, isNotNull);
      expect(grace!.summary.title, 'Grace');
      expect(grace.blocks, isNotEmpty);
      expect(
        await sections.loadSection('dictionary.easton', 'no-existe'),
        isNull,
      );
    },
  );
}
