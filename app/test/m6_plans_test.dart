// M6.3: Planes de lectura (plantillas propias, panel, progreso y botón de la
// ficha del recurso).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aletheia/catalog/catalog_gateway.dart';
import 'package:aletheia/catalog/document_models.dart';
import 'package:aletheia/catalog/document_repository.dart';
import 'package:aletheia/catalog/sections_repository.dart';
import 'package:aletheia/core/database.dart';
import 'package:aletheia/l10n/app_localizations.dart';
import 'package:aletheia/main.dart';
import 'package:aletheia/notes/notes_persistence.dart';
import 'package:aletheia/reading_plans/plan_models.dart';
import 'package:aletheia/reading_plans/reading_plans_controller.dart';
import 'package:aletheia/reading_plans/reading_plans_persistence.dart';
import 'package:aletheia/workspace/models.dart';
import 'package:aletheia/workspace/persistence.dart';
import 'package:aletheia/workspace/workspace_controller.dart';

import 'support/test_fakes.dart';

/// Manifiesto de prueba: 50 capítulos repartidos en cinco libros.
class _PlanRepository implements DocumentRepository {
  static DocumentManifest manifest = DocumentManifest.fromJson({
    'resourceId': 'bible.rv1909',
    'title': 'Biblia de prueba',
    'abbrev': 'RV1909',
    'language': 'es',
    'books': [
      for (final (code, name, chapters) in [
        ('GEN', 'Génesis', 30),
        ('PSA', 'Salmos', 6),
        ('MAT', 'Mateo', 10),
        ('JHN', 'Juan', 2),
        ('REV', 'Apocalipsis', 2),
      ])
        {
          'code': code,
          'name': name,
          'chapters': [
            for (var n = 1; n <= chapters; n++) {'n': n, 'verses': 1},
          ],
        },
    ],
  });

  @override
  Future<DocumentManifest> loadManifest(String resourceId) async => manifest;

  @override
  Future<BookDocument> loadBook(String resourceId, String code) async {
    final book = manifest.bookByCode(code);
    return BookDocument.fromJson({
      'code': code,
      'name': book?.name ?? code,
      'chapters': [
        for (var i = 0; i < (book?.chapters.length ?? 0); i++)
          {
            'n': i + 1,
            'blocks': [
              {'type': 'chapterNumber', 'value': i + 1},
              {
                'type': 'verseGroup',
                'verses': [
                  {
                    'n': 1,
                    'inlines': [
                      {'t': 'text', 'v': 'Texto de $code ${i + 1}.'}
                    ],
                  },
                ],
              },
            ],
          },
      ],
    });
  }
}

/// Sin secciones propias: los drawers resuelven con su estado vacío.
class _EmptySections implements SectionsRepository {
  const _EmptySections();

  @override
  Future<List<SectionSummary>> loadIndex(String resourceId) async => const [];

  @override
  Future<CatalogSection?> loadSection(String resourceId, String sectionId) async =>
      null;
}

void _setWindow(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1400, 950);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<ProviderContainer> _pump(WidgetTester tester) async {
  _setWindow(tester);
  final container = ProviderContainer(
    overrides: [
      workspaceStoreProvider.overrideWithValue(WorkspaceStore.inMemory()),
      notesStoreProvider.overrideWithValue(NotesStore.inMemory()),
      readingPlansStoreProvider
          .overrideWithValue(ReadingPlansStore.inMemory()),
      catalogGatewayProvider.overrideWithValue(FakeCatalogGateway()),
      documentRepositoryProvider.overrideWithValue(_PlanRepository()),
      sectionsRepositoryProvider.overrideWithValue(const _EmptySections()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const AletheiaApp(),
  ));
  await tester.pumpAndSettle();
  return container;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Reactiva la pestaña de planes (abrir la lectura activa otra pestaña).
void _activate(ProviderContainer container, PanelKind kind) {
  final state = container.read(workspaceProvider);
  for (final tile in state.tiles) {
    for (var i = 0; i < tile.tabs.length; i++) {
      if (tile.tabs[i].kind == kind) {
        container.read(workspaceProvider.notifier).activateTab(tile.id, i);
        return;
      }
    }
  }
}

WorkspaceTab? _tab(ProviderContainer container, PanelKind kind) {
  for (final tile in container.read(workspaceProvider).tiles) {
    for (final tab in tile.tabs) {
      if (tab.kind == kind) return tab;
    }
  }
  return null;
}

void main() {
  // ------------------------------------------------------------ calendario

  test('PlanSchedule reparte capítulos, etiquetas y filtros', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('es'));
    final manifest = _PlanRepository.manifest;
    final templates = planTemplates(l10n);

    PlanTemplateDef def(String id) => templates.firstWhere((t) => t.id == id);

    // Biblia en un año: con 50 capítulos el plan se acorta a 50 días.
    final year = PlanSchedule.build(manifest, def('bible-year'));
    expect(year.length, 50);
    expect(year.dayReference(0), 'GEN.1');
    expect(year.dayLabel(0), 'Génesis 1');
    expect(year.dayLabel(49), 'Apocalipsis 2');

    // Evangelios: sólo Mateo y Juan (12 capítulos).
    final gospels = PlanSchedule.build(manifest, def('gospels-30'));
    expect(gospels.length, 12);
    expect(gospels.dayReference(0), 'MAT.1');
    expect(gospels.dayReference(11), 'JHN.2');

    // Salmos y Proverbios: sólo los Salmos del manifiesto.
    final psalms = PlanSchedule.build(manifest, def('psalms-proverbs-31'));
    expect(psalms.length, 6);
    expect(psalms.dayReference(0), 'PSA.1');

    // Nuevo Testamento: Mateo, Juan y Apocalipsis.
    final nt = PlanSchedule.build(manifest, def('nt-90'));
    expect(nt.length, 14);
    expect(nt.dayReference(12), 'REV.1');

    // Varios capítulos por día y salto de libro en la etiqueta.
    const threeDays = PlanTemplateDef(
      id: 'test',
      icon: Icons.menu_book_outlined,
      days: 3,
      bookCodes: ['MAT', 'JHN'],
      title: 'x',
      description: 'y',
    );
    final short = PlanSchedule.build(manifest, threeDays);
    expect(short.length, 3);
    expect(short.dayChapters(0).length, 4);
    expect(short.dayLabel(0), 'Mateo 1—4');
    expect(short.dayLabel(2), 'Mateo 9—Juan 2');
  });

  // ---------------------------------------------------------------- panel

  testWidgets('Planes de lectura: comenzar, avanzar, abrir y detener',
      (tester) async {
    final container = await _pump(tester);
    container
        .read(workspaceProvider.notifier)
        .openTab(const TabSpec(kind: PanelKind.readingPlans));
    await tester.pumpAndSettle();

    expect(find.textContaining('No tienes un plan activo'), findsOneWidget);
    expect(find.text('Planes disponibles'), findsOneWidget);
    expect(find.text('Biblia en un año'), findsOneWidget);
    expect(find.text('Evangelios en 30 días'), findsOneWidget);

    // Comenzar el plan de los evangelios (12 días reales con este manifiesto).
    await _tap(tester, find.byKey(const ValueKey('plan-start-gospels-30')));
    expect(find.byKey(const ValueKey('plan-active-title')), findsOneWidget);
    expect(find.text('Evangelios en 30 días'), findsWidgets);
    expect(find.text('Día 1 de 12'), findsOneWidget);
    expect(find.textContaining('Mateo 1'), findsOneWidget);

    // Marcar el día como leído avanza el progreso.
    await _tap(tester, find.byKey(const ValueKey('plan-advance')));
    expect(find.text('Día 2 de 12'), findsOneWidget);
    expect(find.textContaining('Mateo 2'), findsOneWidget);

    // Abrir la lectura de hoy navega el lector.
    await _tap(tester, find.byKey(const ValueKey('plan-open-today')));
    expect(_tab(container, PanelKind.bible)?.reference, 'MAT.2');

    // Detener el plan vuelve al estado vacío.
    _activate(container, PanelKind.readingPlans);
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const ValueKey('plan-stop')));
    expect(find.textContaining('No tienes un plan activo'), findsOneWidget);
    expect(container.read(readingPlansStoreProvider).initial, isNull);
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('empezar otro plan pide confirmación para reemplazarlo',
      (tester) async {
    final container = await _pump(tester);
    container
        .read(workspaceProvider.notifier)
        .openTab(const TabSpec(kind: PanelKind.readingPlans));
    await tester.pumpAndSettle();

    await _tap(tester, find.byKey(const ValueKey('plan-start-gospels-30')));
    await _tap(tester, find.byKey(const ValueKey('plan-start-nt-90')));
    expect(find.text('¿Reemplazar el plan activo?'), findsOneWidget);

    // Cancelar conserva el plan original.
    await _tap(tester, find.text('Cancelar'));
    expect(find.byKey(const ValueKey('plan-active-title')), findsOneWidget);
    expect(find.text('Evangelios en 30 días'), findsWidgets);

    // Confirmar lo reemplaza.
    await _tap(tester, find.byKey(const ValueKey('plan-start-nt-90')));
    await _tap(tester, find.text('Reemplazar'));
    expect(find.text('Nuevo Testamento en 90 días'), findsWidgets);
    expect(find.text('Día 1 de 14'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
  });

  // -------------------------------------------------- botón de la ficha

  testWidgets('la ficha del recurso abre el plan y cambia de etiqueta',
      (tester) async {
    final container = await _pump(tester);
    container.read(workspaceProvider.notifier).openTab(const TabSpec(
          kind: PanelKind.bible,
          reference: 'JHN.1.1',
          resourceId: 'bible.rv1909',
        ));
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const ValueKey('reader-insights')));
    await _tap(tester, find.byKey(const ValueKey('insights-tab-book')));
    expect(find.text('Comenzar plan de lectura'), findsOneWidget);

    await _tap(tester, find.byKey(const ValueKey('insights-reading-plan')));
    final plans = _tab(container, PanelKind.readingPlans);
    expect(plans, isNotNull);

    // Con un plan activo el botón ofrece verlo.
    container.read(readingPlansProvider.notifier).start('gospels-30');
    _activate(container, PanelKind.bible);
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const ValueKey('reader-insights')));
    await _tap(tester, find.byKey(const ValueKey('insights-tab-book')));
    expect(find.text('Ver plan de lectura'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
  });

  // ------------------------------------------------------------ SQLite

  test('el plan activo sobrevive a la base (ida y vuelta)', () {
    final db = AletheiaDatabase.memory();
    addTearDown(db.close);
    final plan = ReadingPlan(
      id: 'plan-1',
      templateId: 'bible-year',
      resourceId: 'bible.rv1909',
      startedAt: DateTime(2026, 10, 19),
      dayIndex: 42,
      lastReadAt: DateTime(2026, 11, 30),
    );
    db.saveActivePlan(plan);
    final back = db.loadActivePlan();
    expect(back, isNotNull);
    expect(back!.templateId, 'bible-year');
    expect(back.dayIndex, 42);
    expect(back.lastReadAt, DateTime(2026, 11, 30));

    db.saveActivePlan(null);
    expect(db.loadActivePlan(), isNull);
  });
}
