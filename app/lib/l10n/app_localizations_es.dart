// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Aletheia';

  @override
  String get retry => 'Reintentar';

  @override
  String get close => 'Cerrar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get bannerDev => 'Aletheia · catálogo bíblico de dominio público';

  @override
  String get bannerOpenLibrary => 'Abrir Biblioteca';

  @override
  String get bannerClose => 'Cerrar banner';

  @override
  String get navHome => 'Inicio';

  @override
  String get navLibrary => 'Biblioteca';

  @override
  String get navSearch => 'Búsqueda';

  @override
  String get navBible => 'Biblia';

  @override
  String get navAssistant => 'Asistente de estudio';

  @override
  String get navTopics => 'Temas';

  @override
  String get navGuidedStudy => 'Estudio guiado';

  @override
  String get navNotes => 'Notas';

  @override
  String get navTools => 'Herramientas';

  @override
  String get navQuickActions => 'Acciones rápidas';

  @override
  String get navStore => 'Tienda';

  @override
  String get navLayouts => 'Diseños';

  @override
  String get navCloseAllTabs => 'Cerrar todas las pestañas';

  @override
  String get quickOpenCommentary => 'Abrir un comentario';

  @override
  String get quickOpenStudyBible => 'Abrir una Biblia de estudio';

  @override
  String get quickCompareBibles => 'Comparar versiones';

  @override
  String get quickOpenDictionary => 'Abrir un diccionario bíblico';

  @override
  String get quickOpenDevotional => 'Abrir el devocional de hoy';

  @override
  String get moreOptions => 'Más opciones';

  @override
  String get menuSettings => 'Configuración';

  @override
  String get menuResourceCatalog => 'Catálogo de recursos';

  @override
  String get menuOriginalStore => 'Tienda de la app original (no aplica)';

  @override
  String get menuDownloadApp => 'Descargar la app original (no aplica)';

  @override
  String get sidebarExpand => 'Expandir barra lateral';

  @override
  String get sidebarCollapse => 'Colapsar barra lateral';

  @override
  String get layoutOne => 'Una columna';

  @override
  String get layoutTwo => 'Dos columnas';

  @override
  String get layoutTwoRows => 'Dos filas';

  @override
  String get layoutThree => 'Tres columnas';

  @override
  String get layoutFour => 'Cuadrícula 2×2';

  @override
  String get omniboxHint => 'Pasaje o tema';

  @override
  String omniboxGoto(String reference) {
    return 'Ir a $reference';
  }

  @override
  String omniboxSearch(String query) {
    return 'Buscar «$query»';
  }

  @override
  String get workspaceEmptyTile =>
      'Sin pestañas — abre algo desde la barra lateral';

  @override
  String get panelCommands => 'Comandos del panel';

  @override
  String get tabClose => 'Cerrar pestaña';

  @override
  String get tabDuplicate => 'Duplicar esta pestaña';

  @override
  String get tabCloseThis => 'Cerrar esta pestaña';

  @override
  String get tabCloseToRight => 'Cerrar pestañas a la derecha';

  @override
  String get tabCloseOthers => 'Cerrar otras pestañas';

  @override
  String get tabCloseAll => 'Cerrar todas las pestañas';

  @override
  String get panelTitleDashboard => 'Inicio';

  @override
  String get panelTitleLibrary => 'Biblioteca';

  @override
  String get panelTitleStore => 'Tienda';

  @override
  String get panelTitleSearch => 'Búsqueda';

  @override
  String get panelTitleResource => 'Recurso';

  @override
  String get panelTitleBible => 'Biblia';

  @override
  String get panelTitleStudyAssistant => 'Asistente de estudio';

  @override
  String get panelTitleFactbook => 'Temas';

  @override
  String get panelTitleGuidedStudy => 'Estudio guiado';

  @override
  String get panelTitleNotes => 'Notas';

  @override
  String get panelTitleTools => 'Herramientas';

  @override
  String get panelTitleTextComparison => 'Comparación de textos';

  @override
  String get panelTitleDevotional => 'Devocional del día';

  @override
  String get panelTitleSettings => 'Configuración';

  @override
  String get placeholderDashboard =>
      'Estado del espacio de trabajo y banners configurables (M3).';

  @override
  String get placeholderLibrary =>
      'La Biblioteca se abre desde la barra lateral como panel flotante (M2): búsqueda, facetas y detalle de recursos.';

  @override
  String get placeholderStore =>
      'Catálogo navegable de recursos de dominio público (M5). Sin compras: los recursos propios se marcan como disponibles.';

  @override
  String get placeholderResource =>
      'Lector de recursos no bíblicos (M5): comentarios, diccionarios y libros desde el catálogo.';

  @override
  String get placeholderStudyAssistant =>
      'Asistente de estudio (plugin IA opcional, M6): chat con citas a recursos, adjuntos y selección de alcance.';

  @override
  String get placeholderFactbook =>
      'Temas (M5): artículos por tema o referencia con secciones y temas relacionados.';

  @override
  String get placeholderGuidedStudy =>
      'Estudio guiado (M6): guías (estudio de palabras, exégesis, pasaje, bosquejo de sermón) y flujos de trabajo guiados.';

  @override
  String get placeholderTools =>
      'Centro de herramientas (M5): Atlas, Documentos, Favoritos, Información, Multimedia, Explorador de Salmos, Gestor de planes de lectura, Comparación de textos.';

  @override
  String get placeholderTextComparison =>
      'Comparación de textos (M5): referencia + conjunto de versiones en columnas sincronizadas por versículo.';

  @override
  String get placeholderDevotional =>
      'Devocional del día (M5): recursos con calendario (formato MM-DD), navegación mañana/tarde.';

  @override
  String get placeholderFallback => 'Pendiente en próximos milestones.';

  @override
  String get readerBack => 'Atrás';

  @override
  String get readerForward => 'Adelante';

  @override
  String get readerChangeBook => 'Cambiar libro';

  @override
  String get readerModeHome => 'Inicio';

  @override
  String get readerModeSearch => 'Buscar';

  @override
  String get readerModeNotes => 'Notas';

  @override
  String get readerModeFormat => 'Formato';

  @override
  String get readerModeView => 'Vista';

  @override
  String get readerModeMore => 'Más';

  @override
  String get readerSearchInResource => 'Buscar en este recurso';

  @override
  String get readerToolsSoon => 'Herramientas — M6';

  @override
  String get readerCopyReference => 'Copiar referencia';

  @override
  String get readerCopyCitation => 'Copiar cita';

  @override
  String get readerCopyPassageAndCitation => 'Copiar pasaje y cita';

  @override
  String get readerCopied => 'Copiado al portapapeles';

  @override
  String get readerContents => 'Índice';

  @override
  String get readerContentsTooltip => 'Índice de contenidos';

  @override
  String get readerArticle => 'Artículo';

  @override
  String get readerArticleStepTo => 'Ir a artículo';

  @override
  String get readerArticlePrevious => 'Artículo anterior';

  @override
  String get readerArticleNext => 'Artículo siguiente';

  @override
  String get readerPrevChapter => 'Capítulo anterior';

  @override
  String get readerNextChapter => 'Capítulo siguiente';

  @override
  String get readerLinkSet => 'Conjunto de vínculos';

  @override
  String get readerLinkSetSoon => 'Conjunto de vínculos — M6';

  @override
  String get readerInsights => 'Análisis';

  @override
  String get readerInfo => 'Información';

  @override
  String get insightsTitle => 'Ideas';

  @override
  String get insightsClose => 'Cerrar el panel';

  @override
  String get insightsBookInfoTab => 'Información del libro';

  @override
  String insightsAbout(String title) {
    return 'Acerca de $title';
  }

  @override
  String get insightsAuthor => 'Autor';

  @override
  String get insightsPublisher => 'Editorial';

  @override
  String get insightsEdition => 'Edición';

  @override
  String get insightsLanguage => 'Idioma';

  @override
  String get insightsType => 'Tipo';

  @override
  String get insightsStats => 'Estadísticas';

  @override
  String insightsVerseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count versículos',
      one: '1 versículo',
    );
    return '$_temp0';
  }

  @override
  String insightsSectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count secciones',
      one: '1 sección',
    );
    return '$_temp0';
  }

  @override
  String get insightsAuxId => 'Identificador';

  @override
  String get insightsAuxType => 'Tipo';

  @override
  String get insightsAuxSource => 'Fuente';

  @override
  String get insightsAuxiliary => 'Información auxiliar';

  @override
  String get insightsBookInfoUnavailable => 'Sin ficha del recurso.';

  @override
  String get insightsCopyright => 'Copyright';

  @override
  String get insightsLicenseUnknown => 'Licencia no indicada.';

  @override
  String get insightsRelatedBooks => 'Libros relacionados';

  @override
  String get insightsNoBooks =>
      'Ningún recurso del catálogo cita esta referencia.';

  @override
  String get insightsRelatedPassages => 'Pasajes relacionados';

  @override
  String get insightsCrossReferences => 'Referencias cruzadas';

  @override
  String get insightsNoPassages =>
      'Sin pasajes relacionados en el catálogo actual.';

  @override
  String get insightsRelatedError =>
      'No se pudo cargar el contenido relacionado.';

  @override
  String get insightsMore => 'Más »';

  @override
  String get readingPlanStart => 'Comenzar plan de lectura';

  @override
  String get readerHideLocationBar => 'Ocultar la barra de ubicación';

  @override
  String get readerShowLocationBar => 'Mostrar la barra de ubicación';

  @override
  String get readerHideSecondaryToolbar => 'Ocultar la barra secundaria';

  @override
  String get readerShowSecondaryToolbar => 'Mostrar la barra secundaria';

  @override
  String get readerHistory => 'Historial';

  @override
  String get readerHistoryPanel => 'Historial del panel';

  @override
  String get readerHistoryEmpty => 'Sin historial todavía';

  @override
  String get readerLoadMoreChapters => 'Cargar más capítulos';

  @override
  String get readerEnd => '— Fin —';

  @override
  String readerFootnote(String label) {
    return 'Nota $label';
  }

  @override
  String get readerFootnoteUnavailable => 'Nota al pie no disponible.';

  @override
  String readerFootnoteA11y(String label, String text) {
    return 'Nota al pie $label: $text';
  }

  @override
  String get readerFootnoteOpenHint => 'Ver la nota al pie';

  @override
  String get readerXrefOpenHint => 'Ir a la referencia cruzada';

  @override
  String readerInvalidReference(String reference) {
    return 'Referencia no válida: $reference';
  }

  @override
  String readerSectionMissing(String book, int chapter) {
    return 'No se encontró $book $chapter en el documento.';
  }

  @override
  String readerLoadError(String error) {
    return 'No se pudo cargar el documento: $error';
  }

  @override
  String get readerFootnoteList => 'Notas al pie';

  @override
  String get contentsTitle => 'Índice de contenidos';

  @override
  String get contentsFilter => 'Filtrar libros';

  @override
  String get contentsSearch => 'Buscar en el índice';

  @override
  String get contentsClose => 'Cerrar el índice';

  @override
  String contentsChapter(int number) {
    return 'Capítulo $number';
  }

  @override
  String get changeBookTitle => 'Cambiar libro';

  @override
  String changeBookLoadError(String error) {
    return 'No se pudieron cargar las Biblias.\n$error';
  }

  @override
  String get changeBookEmpty => 'Sin resultados';

  @override
  String panelSearchTitle(String resource) {
    return 'Buscar en «$resource»';
  }

  @override
  String get panelSearchSyntax =>
      'Dentro de este recurso · palabras, \"frases\", AND/OR/NOT, WITHIN n WORDS';

  @override
  String get searchFailed => 'No se pudo buscar';

  @override
  String get panelSearchPrompt =>
      'Escribe una consulta para buscar en todo el recurso. Cada resultado te lleva al versículo exacto.';

  @override
  String searchNoResults(String query) {
    return 'Sin resultados para «$query»';
  }

  @override
  String get searchTryFewerWords => 'Prueba con menos palabras';

  @override
  String get searchTryFewerOrScope => 'Prueba con menos palabras o otro ámbito';

  @override
  String searchResultsCountFor(int count, String query) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados',
      one: '1 resultado',
    );
    return '$_temp0 para «$query»';
  }

  @override
  String searchLoadMoreRemaining(int count) {
    return 'Cargar más ($count restantes)';
  }

  @override
  String searchScope(String scope) {
    return 'Ámbito: $scope';
  }

  @override
  String get searchSyntaxTitle => 'Sintaxis de búsqueda';

  @override
  String get searchSyntaxWord => 'una palabra';

  @override
  String get searchSyntaxPhrase => '\"en el principio\"';

  @override
  String get searchSyntaxPhraseNote => 'frase exacta';

  @override
  String get searchSyntaxAnd => 'Verbo AND principio';

  @override
  String get searchSyntaxAndNote => 'ambas palabras (también OR y NOT)';

  @override
  String get searchSyntaxWithin => 'principio WITHIN 5 WORDS Verbo';

  @override
  String get searchSyntaxWithinNote => 'a menos de 5 palabras de distancia';

  @override
  String get searchSyntaxBeforeNote => 'un término aparece antes que el otro';

  @override
  String get searchSyntaxNearNote => 'a menos de 10 palabras (NEAR/5 para 5)';

  @override
  String get searchSyntaxFieldNote =>
      'pasaje y filtros: bible:, type:, language:, book:';

  @override
  String get searchSyntaxNote =>
      'La búsqueda es insensible a mayúsculas y acentos. Combina la sintaxis con los filtros de tipo, idioma y libro; los resultados se agrupan por recurso.';

  @override
  String get searchMorphologyTitle => 'Morfología';

  @override
  String get searchKeyboardTitle => 'Teclado griego y hebreo';

  @override
  String get searchKeyboardGreek => 'Griego';

  @override
  String get searchKeyboardHebrew => 'Hebreo';

  @override
  String get searchKeyboardHint =>
      'Toca una letra para insertarla en la búsqueda.';

  @override
  String get searchKeyboardBackspace => 'Borrar una letra';

  @override
  String get searchFilterType => 'Tipo';

  @override
  String get searchFilterLanguage => 'Idioma';

  @override
  String get searchFilterBook => 'Libro';

  @override
  String get searchFilterAll => 'Todos';

  @override
  String get searchFilterAllBooks => 'Todos los libros';

  @override
  String get searchFilterClear => 'Limpiar filtros';

  @override
  String get searchBack => 'Atrás';

  @override
  String get searchTitle => 'Buscar en la Biblia y los libros';

  @override
  String get searchHistory => 'Historial de búsquedas';

  @override
  String get searchHistoryEmpty => 'Sin búsquedas todavía';

  @override
  String get searchPromptTitle => 'Busca en el catálogo';

  @override
  String get searchPromptBody =>
      'Palabras, frases entre comillas, AND/OR/NOT, NEAR, WITHIN n WORDS y campos como bible:\"Jn 3\". Cada resultado abre el recurso en el pasaje exacto.';

  @override
  String get searchIndexUnavailable =>
      'No se pudo abrir el índice de búsqueda local. Reinstala la app o vuelve a generar el catálogo.';

  @override
  String get searchDownloadTitle => 'Primera búsqueda: descargando el índice';

  @override
  String searchDownloadBody(String size) {
    return 'El índice pesa $size. Se guardará en la caché del navegador para las próximas búsquedas.';
  }

  @override
  String searchDownloadProgress(String received, String total) {
    return '$received de $total';
  }

  @override
  String searchDownloadUnknown(String received) {
    return '$received descargados';
  }

  @override
  String get searchDownloadCancel => 'Cancelar';

  @override
  String get searchDownloadCancelled =>
      'Descarga cancelada. La próxima búsqueda volverá a intentarlo.';

  @override
  String get scopeAll => 'Todo';

  @override
  String get scopeBible => 'Biblia';

  @override
  String get scopeBooks => 'Libros';

  @override
  String get scopeFactbook => 'Temas';

  @override
  String get scopeMorph => 'Morfología';

  @override
  String get scopeMedia => 'Multimedia';

  @override
  String get scopeMaps => 'Mapas';

  @override
  String get scopeTodoNote => 'M5';

  @override
  String get scopeMorphNote => 'M6';

  @override
  String get fmtMarkers => 'Marcadores';

  @override
  String get fmtReformat => 'Reformato';

  @override
  String get fmtTypography => 'Tipografía';

  @override
  String get fontSerif => 'Serif';

  @override
  String get fontSans => 'Sans';

  @override
  String get fontMono => 'Mono';

  @override
  String get fmtReformatTitle => 'Reformato del texto';

  @override
  String get fmtMarkersTitle => 'Mostrar marcadores';

  @override
  String get fmtBibleText => 'Texto bíblico';

  @override
  String get fmtBibleTextFormatting => 'Formato del texto bíblico';

  @override
  String get fmtNumbers => 'Números de capítulo y versículo';

  @override
  String get fmtFootnoteIndicators => 'Indicadores de notas';

  @override
  String get fmtNonBibleText => 'Texto no bíblico';

  @override
  String get fmtOneVersePerLine => 'Un versículo por línea';

  @override
  String get fmtCorrespondingWords => 'Palabras correspondientes';

  @override
  String get fmtSameSurfaceText => 'Mismo texto superficial';

  @override
  String get fmtNote => 'Reformatea el cuerpo principal del libro.';

  @override
  String get fmtMarkersNote =>
      'Añade marcadores para mostrar datos ocultos del libro. Con Marcadores activo, solo se ven los indicadores y resaltados de los cuadernos y etiquetas marcados.';

  @override
  String get fmtSermons => 'Sermones';

  @override
  String get fmtBibleStudies => 'Estudios bíblicos';

  @override
  String get fmtMarkersNotebooks => 'Cuadernos';

  @override
  String get fmtMarkersTags => 'Etiquetas';

  @override
  String get fmtMarkersEmpty =>
      'Aún no hay cuadernos ni etiquetas. Crea una nota con cuaderno o etiqueta para filtrar los marcadores.';

  @override
  String get viewPagedView => 'Vista paginada';

  @override
  String get viewPagedTitle => 'Vista paginada';

  @override
  String get viewColumns => 'Columnas';

  @override
  String get viewColumnsAuto => 'Auto';

  @override
  String get viewFootnotesOnPage => 'Mostrar notas en la página';

  @override
  String get viewLocatorBar => 'Barra de ubicación';

  @override
  String get viewZoom => 'Zoom';

  @override
  String get viewFullScreen => 'Pantalla completa';

  @override
  String get viewExitFullScreen => 'Salir de pantalla completa';

  @override
  String viewPageOf(int page, int total) {
    return 'Página $page de $total';
  }

  @override
  String get viewPrevPage => 'Página anterior';

  @override
  String get viewNextPage => 'Página siguiente';

  @override
  String get viewZoomReset => 'Restablecer el zoom al 100 %';

  @override
  String get settingsReset => 'Restablecer valores';

  @override
  String get settingsResetDone => 'Valores restablecidos';

  @override
  String get settingsCatalog => 'Catálogo';

  @override
  String get settingsServiceUrl => 'Dirección del servicio';

  @override
  String get settingsApply => 'Aplicar';

  @override
  String get settingsCatalogModeAuto => 'Automático';

  @override
  String get settingsCatalogModeLocal => 'Solo incluidos';

  @override
  String get settingsCatalogModeRemote => 'Solo servicio';

  @override
  String get settingsChecking => 'Comprobando el servicio…';

  @override
  String get settingsOffline =>
      'Sin conexión — se usan los recursos incluidos en la app.';

  @override
  String settingsOfflineError(String error) {
    return 'Sin conexión: $error';
  }

  @override
  String settingsOnline(int resources, String verses, String sections) {
    return 'Conectado: $resources recursos, $verses versículos y $sections entradas indexadas.';
  }

  @override
  String settingsLocalReady(int resources, String verses, String sections) {
    return 'Modo local: $resources recursos, $verses versículos y $sections entradas indexadas.';
  }

  @override
  String get settingsRecheck => 'Recomprobar';

  @override
  String get settingsQuickActions => 'Mostrar acciones rápidas';

  @override
  String get settingsBannersDashboard =>
      'Mostrar banners en el panel de inicio';

  @override
  String get settingsBannersLayout => 'Mostrar banners en los diseños';

  @override
  String get settingsToolbarLocation => 'Ubicación de la barra de aplicaciones';

  @override
  String get settingsToolbarLeft => 'Izquierda';

  @override
  String get settingsToolbarTop => 'Arriba';

  @override
  String get settingsLanguage => 'Idioma de la interfaz';

  @override
  String get settingsLanguageSystem => 'Sistema';

  @override
  String get settingsCitationStyle => 'Estilo de citas';

  @override
  String get citationTurabian => 'Turabian (9.ª ed., nota completa)';

  @override
  String get citationSbl => 'SBL (2.ª ed.)';

  @override
  String get citationChicago => 'Chicago (17.ª ed.)';

  @override
  String get citationPlain => 'Aletheia (simple)';

  @override
  String get settingsCopyCitations => 'Copiar la cita con el texto';

  @override
  String get settingsHyperlinkCitations => 'Enlazar las citas copiadas';

  @override
  String get settingsLimitedView => 'Activar el modo de vista limitada';

  @override
  String get settingsLimitedViewHelp =>
      'Vista accesible: sin paginación y con las notas al pie como lista al final de cada capítulo.';

  @override
  String get yes => 'Sí';

  @override
  String get no => 'No';

  @override
  String get help => 'Ayuda';

  @override
  String get libraryFacets => 'Facetas';

  @override
  String get libraryFind => 'Buscar';

  @override
  String get libraryClear => 'Limpiar';

  @override
  String libraryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recursos',
      one: '1 recurso',
    );
    return '$_temp0';
  }

  @override
  String get libraryTabLibrary => 'Biblioteca';

  @override
  String get libraryTabStore => 'Tienda';

  @override
  String get libraryStoreSoon => 'M5: catálogo de la tienda';

  @override
  String get librarySort => 'Ordenar';

  @override
  String get librarySortTitle => 'por Título';

  @override
  String get librarySortAuthor => 'por Autor';

  @override
  String get librarySortDate => 'por Fecha';

  @override
  String get libraryClearFilters => 'Limpiar filtros';

  @override
  String get libraryFacetType => 'Tipo';

  @override
  String get libraryFacetLanguage => 'Idioma';

  @override
  String get libraryFacetAuthor => 'Autor';

  @override
  String get libraryFacetSubject => 'Tema';

  @override
  String get libraryFacetPublisher => 'Editorial';

  @override
  String get libraryLoadMore => 'Cargar más';

  @override
  String get libraryErrorTitle => 'No se pudo consultar el catálogo';

  @override
  String get libraryEmpty => 'Sin recursos que coincidan con el filtro';

  @override
  String get libraryBack => 'Volver a la lista';

  @override
  String get libraryOpen => 'Abrir';

  @override
  String get libraryMore => 'Más »';

  @override
  String get libraryLess => 'Menos «';

  @override
  String libraryStats(String verses, String chapters) {
    return '$verses versículos · $chapters capítulos';
  }

  @override
  String get libraryLoading => 'Cargando…';

  @override
  String get languageEs => 'Español';

  @override
  String get languageEn => 'Inglés';

  @override
  String get languageEl => 'Griego';

  @override
  String get languageHe => 'Hebreo';

  @override
  String get languageLa => 'Latín';

  @override
  String get typeBible => 'Biblia';

  @override
  String get typeCommentary => 'Comentario';

  @override
  String get typeDictionary => 'Diccionario';

  @override
  String get typeEncyclopedia => 'Enciclopedia';

  @override
  String get typeDevotional => 'Devocional';

  @override
  String get typeDataset => 'Datos';

  @override
  String get typeGuide => 'Guía';

  @override
  String get typeWorkflow => 'Flujo de trabajo';

  @override
  String get typeDocument => 'Documento';

  @override
  String get settingsCitationHelp =>
      'Turabian (9.ª ed., nota completa) · SBL (2.ª ed.) · Chicago (17.ª ed.) · Aletheia (simple)';

  @override
  String get resourceTitleCommentary => 'Comentario';

  @override
  String get resourceTitleStudyBible => 'Biblia de estudio';

  @override
  String get resourceTitleDictionary => 'Diccionario bíblico';

  @override
  String get resourceLabelMatthewHenry => 'Matthew Henry (conciso)';

  @override
  String get resourceLabelTsk => 'Tesoro de conocimiento bíblico';

  @override
  String get settingsBannersDashboardHelp =>
      'Banner de novedades dentro del panel de inicio.';

  @override
  String get settingsBannersLayoutHelp =>
      'Los banners de los diseños (barra superior).';

  @override
  String get settingsCopyHelp => 'Al copiar un pasaje se añade su cita.';

  @override
  String get settingsHyperlinkHelp =>
      'Las citas copiadas enlazan al pasaje («ref:CANÓNICO»).';

  @override
  String get notesFind => 'Buscar';

  @override
  String get notesFindHint => 'Buscar en las notas';

  @override
  String get notesShare => 'Compartir';

  @override
  String get notesNewNote => 'Nueva nota';

  @override
  String get notesAll => 'Todos';

  @override
  String notesResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados',
      one: '1 resultado',
    );
    return '$_temp0';
  }

  @override
  String get notesFilters => 'Filtros';

  @override
  String get notesSidebarToggle => 'Filtros y cuadernos';

  @override
  String get notesNotebooks => 'Cuadernos';

  @override
  String get notesTrash => 'Papelera';

  @override
  String get notesByModified => 'Fecha de modificación';

  @override
  String get notesByCreated => 'Fecha de creación';

  @override
  String notesSortBy(String label) {
    return 'por $label';
  }

  @override
  String get notesByNotebook => 'Cuaderno';

  @override
  String get notesSortNotebookHint =>
      'Selecciona un cuaderno para activar el orden por cuaderno';

  @override
  String get notesDensity => 'Densidad';

  @override
  String get notesDensityDefault => 'Predeterminado';

  @override
  String get notesDensityCompact => 'Compacto';

  @override
  String notesNewNoteInRef(String reference) {
    return 'Nueva nota en $reference';
  }

  @override
  String get notesByTitle => 'por título';

  @override
  String get notesEmpty => 'Aún no hay notas';

  @override
  String get notesEmptyHint =>
      'Crea una nota con «Nueva nota» o seleccionando un texto en el lector.';

  @override
  String get notesTrashEmpty => 'La papelera está vacía';

  @override
  String get notesTrashHint =>
      'Puedes restaurar las notas o eliminarlas definitivamente.';

  @override
  String get notesFilterKind => 'Tipo';

  @override
  String get notesFilterKindNote => 'Notas';

  @override
  String get notesFilterKindHighlight => 'Resaltados';

  @override
  String get notesFilterNotebook => 'Cuaderno';

  @override
  String get notesFilterTag => 'Etiqueta';

  @override
  String get notesFilterResource => 'Recurso';

  @override
  String get notesFiltersClear => 'Quitar los filtros';

  @override
  String notesFiltersActive(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filtros',
      one: '1 filtro',
    );
    return '$_temp0';
  }

  @override
  String get notesNewNotebook => 'Nuevo cuaderno';

  @override
  String get notesNotebookName => 'Nombre del cuaderno';

  @override
  String get notesNotebookCreate => 'Crear cuaderno';

  @override
  String notesNotebookDeleteTitle(Object name) {
    return '¿Eliminar el cuaderno «$name»?';
  }

  @override
  String get notesNotebookDeleteBody =>
      'Las notas no se eliminan: solo se quitan del cuaderno.';

  @override
  String get notesNotebookEmpty => 'Sin cuadernos todavía';

  @override
  String notesNotebookNotes(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notas',
      one: '1 nota',
    );
    return '$_temp0';
  }

  @override
  String get notesRename => 'Renombrar';

  @override
  String get notesRestore => 'Restaurar';

  @override
  String get notesPurge => 'Eliminar definitivamente';

  @override
  String get notesEmptyTrashAction => 'Vaciar la papelera';

  @override
  String get notesDuplicate => 'Duplicar';

  @override
  String get notesEdit => 'Editar';

  @override
  String get notesOpen => 'Abrir';

  @override
  String get notesClose => 'Cerrar la nota';

  @override
  String get notesShowInReader => 'Mostrar en el lector';

  @override
  String get notesNoAnchor => 'Sin anclaje';

  @override
  String notesAnchoredAt(Object reference) {
    return 'Anclada en $reference';
  }

  @override
  String notesItemCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notas',
      one: '1 nota',
    );
    return '$_temp0';
  }

  @override
  String notesTrashCount(Object count) {
    return 'en la papelera: $count';
  }

  @override
  String get noteTitleHint => 'Título de la nota';

  @override
  String get noteBodyHint => 'Escribe una nota…';

  @override
  String get noteQuoteLabel => 'Cita';

  @override
  String get noteQuoteRemove => 'Quitar la cita';

  @override
  String get noteFormatBold => 'Negrita';

  @override
  String get noteFormatItalic => 'Cursiva';

  @override
  String get noteFormatUnderline => 'Subrayado';

  @override
  String get noteFormatHighlight => 'Resaltado';

  @override
  String get noteFormatBullets => 'Lista con viñetas';

  @override
  String get noteFormatNumbered => 'Lista numerada';

  @override
  String get noteFormatQuote => 'Cita en bloque';

  @override
  String get noteFormatReference => 'Insertar referencia';

  @override
  String get noteNotebooksLabel => 'Cuadernos';

  @override
  String get noteNotebookAdd => 'Añadir a un cuaderno';

  @override
  String get noteTagsLabel => 'Etiquetas';

  @override
  String get noteTagAdd => 'Añadir etiqueta';

  @override
  String get noteTagHint => 'Nueva etiqueta';

  @override
  String get noteAnchorLabel => 'Anclaje';

  @override
  String get noteAnchorChange => 'Cambiar el anclaje';

  @override
  String get noteSaved => 'Guardado';

  @override
  String noteCreatedOn(Object date) {
    return 'Creada el $date';
  }

  @override
  String noteModifiedOn(Object date) {
    return 'Modificada el $date';
  }

  @override
  String noteDeletedOn(Object date) {
    return 'Eliminada el $date';
  }

  @override
  String get noteShareCopied => 'Nota copiada al portapapeles';

  @override
  String get noteShareMarkdown => 'Copiar como Markdown';

  @override
  String get noteShareText => 'Copiar como texto';

  @override
  String get noteKindNote => 'Nota';

  @override
  String get noteKindHighlight => 'Resaltado';

  @override
  String get noteColorYellow => 'Amarillo';

  @override
  String get noteColorGreen => 'Verde';

  @override
  String get noteColorBlue => 'Azul';

  @override
  String get noteColorRed => 'Rojo';

  @override
  String get noteColorOrange => 'Anaranjado';

  @override
  String get noteColorPink => 'Rosa';

  @override
  String get readerNotesNew => 'Nueva nota';

  @override
  String get readerNotesEmpty => 'No hay notas en este recurso';

  @override
  String get readerNotesEmptyHint =>
      'Selecciona un texto para crear una nota o un resaltado.';

  @override
  String readerNotesOnVerse(Object verse) {
    return 'Notas sobre el versículo $verse';
  }

  @override
  String get readerNoteMarker => 'Notas en este versículo';

  @override
  String get readerHighlightCreated => 'Resaltado añadido';

  @override
  String get readerNoteCreated => 'Nota creada';

  @override
  String get readerNotesView => 'Notas de este recurso';

  @override
  String get selectionCopy => 'Copiar';

  @override
  String get selectionLookUp => 'Consultar';

  @override
  String get selectionHighlight => 'Resaltar';

  @override
  String get selectionNote => 'Nota';

  @override
  String get selectionAddNote => 'Agregar nota';

  @override
  String get selectionSearch => 'Buscar';

  @override
  String get selectionMore => 'Mostrar más opciones';

  @override
  String get selectionVisualCopy => 'Copia visual';

  @override
  String get selectionUnderlineRed => 'Subrayado rojo';

  @override
  String get selectionRemoveHighlight => 'Quitar resaltado';

  @override
  String get readerHighlightUpdated => 'Resaltado actualizado';

  @override
  String get readerHighlightRemoved => 'Resaltado quitado';

  @override
  String highlightSwatch(String color) {
    return 'Resaltado $color';
  }

  @override
  String underlineSwatch(String color) {
    return 'Subrayado $color';
  }

  @override
  String get selectionCitation => 'Copiar cita';

  @override
  String get selectionNoteStub => 'Nota';

  @override
  String get devotionalToday => 'Hoy';

  @override
  String get devotionalPrevious => 'Día anterior';

  @override
  String get devotionalNext => 'Día siguiente';

  @override
  String get devotionalPickDate => 'Elegir fecha';

  @override
  String get devotionalEmptyTitle => 'No hay lectura para esta fecha';

  @override
  String get devotionalEmptyDetail => 'Prueba con otro día o vuelve a hoy.';

  @override
  String get factbookSearchHint => 'Tema o referencia';

  @override
  String get factbookLoadError => 'No se pudo cargar la enciclopedia.';

  @override
  String factbookTopicsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count temas',
      one: '1 tema',
    );
    return '$_temp0';
  }

  @override
  String get factbookNoResults => 'No se encontraron temas';

  @override
  String get factbookOpenPassage => 'Abrir pasaje';

  @override
  String get factbookLensAll => 'Todo';

  @override
  String get factbookLensBiblical => 'Bíblico';

  @override
  String get factbookLensLibrary => 'Biblioteca';

  @override
  String get factbookLensTheology => 'Teológico';

  @override
  String get factbookLensCounseling => 'Consejería';

  @override
  String get factbookLensDiscover => 'Descubra';

  @override
  String get factbookBack => 'Volver a los temas';

  @override
  String get factbookReferences => 'Referencias';

  @override
  String get factbookRelated => 'Temas relacionados';

  @override
  String get catalogFilterHint => 'Filtrar por título o tema';

  @override
  String catalogEntriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entradas',
      one: '1 entrada',
    );
    return '$_temp0';
  }

  @override
  String get catalogBackToIndex => 'Volver al índice';

  @override
  String get compareReferenceHint => 'Referencia';

  @override
  String get compareVersions => 'Versiones';

  @override
  String compareVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count versiones',
      one: '1 versión',
    );
    return '$_temp0';
  }

  @override
  String compareDifference(int percent) {
    return '$percent% de diferencia';
  }

  @override
  String get compareCopy => 'Copiar comparación';

  @override
  String get compareCopied => 'Comparación copiada al portapapeles';

  @override
  String get compareNoVersions => 'No hay versiones disponibles';

  @override
  String get compareSingleVersion =>
      'Solo hay una versión disponible; inicia el servicio de catálogo para comparar más.';

  @override
  String get compareLoadError => 'No se pudo cargar el capítulo.';

  @override
  String get compareNoChapter => 'La referencia no existe en esta versión.';

  @override
  String get compareInvalidReference =>
      'Referencia no válida. Prueba, por ejemplo, «Juan 1».';

  @override
  String get compareVersionUnavailable => 'No disponible en esta versión.';

  @override
  String get compareAddVersions => 'Abrir Biblioteca';

  @override
  String get layoutsSaved => 'Diseños guardados';

  @override
  String get layoutSaveCurrent => 'Guardar el diseño actual…';

  @override
  String get layoutSaveTitle => 'Guardar diseño';

  @override
  String get layoutNameLabel => 'Nombre del diseño';

  @override
  String get layoutNameHint => 'p. ej., Estudio de Juan';

  @override
  String get layoutSave => 'Guardar';

  @override
  String get layoutSavedToast => 'Diseño guardado';

  @override
  String get layoutDelete => 'Eliminar diseño';

  @override
  String layoutDeleteQuestion(String name) {
    return '¿Eliminar el diseño «$name»?';
  }

  @override
  String get layoutDeleteConfirm => 'Eliminar';

  @override
  String get layoutNoSaved => 'Aún no hay diseños guardados';

  @override
  String layoutAppliedToast(String name) {
    return 'Diseño «$name» aplicado';
  }

  @override
  String get guidedFindHint => 'Buscar una guía';

  @override
  String get guidedGuides => 'Guías';

  @override
  String get guidedWorkflows => 'Flujos de trabajo';

  @override
  String get guidedNoMatch => 'Ninguna guía coincide con la búsqueda.';

  @override
  String get guidedParamWord => 'Palabra';

  @override
  String get guidedParamReference => 'Referencia';

  @override
  String get guidedGenerate => 'Generar guía';

  @override
  String get guidedBack => 'Todas las guías';

  @override
  String get guidedStepDone => 'Marcar el paso';

  @override
  String get guidedActionReader => 'Abrir en el lector';

  @override
  String get guidedActionCompare => 'Comparar versiones';

  @override
  String get guidedActionFactbook => 'Ver en Temas';

  @override
  String get guidedActionSearch => 'Buscar en el catálogo';

  @override
  String get guidedActionNotes => 'Abrir Notas';

  @override
  String get guideWordTitle => 'Estudio de palabras bíblicas';

  @override
  String get guideWordDesc =>
      'Analiza una palabra clave y sus apariciones en el catálogo.';

  @override
  String get guideExegeticalTitle => 'Guía exegética';

  @override
  String get guideExegeticalDesc =>
      'Contexto, estructura y género del pasaje, paso a paso.';

  @override
  String get guidePassageTitle => 'Guía de pasajes';

  @override
  String get guidePassageDesc =>
      'Recorre un pasaje con las herramientas y el catálogo.';

  @override
  String get guideSermonTitle => 'Guía para sermones';

  @override
  String get guideSermonDesc => 'Del texto al bosquejo del mensaje.';

  @override
  String get workflowBasicTitle => 'Estudio bíblico básico';

  @override
  String get workflowBasicDesc =>
      'Cinco pasos clásicos para estudiar un pasaje.';

  @override
  String get workflowInductiveTitle => 'Estudio bíblico inductivo';

  @override
  String get workflowInductiveDesc =>
      'Observación, interpretación y aplicación.';

  @override
  String get workflowLectioTitle => 'Lectio divina';

  @override
  String get workflowLectioDesc => 'Lectura orante en cuatro movimientos.';

  @override
  String get stepPrayTitle => 'Ora y prepara el corazón';

  @override
  String get stepPrayDetail =>
      'Pide al Señor que abra tu entendimiento antes de leer.';

  @override
  String get stepReadTitle => 'Lee el pasaje completo';

  @override
  String stepReadDetail(String param) {
    return 'Lee $param dos o tres veces, sin detenerte en los detalles.';
  }

  @override
  String get stepContextTitle => 'Estudia el contexto';

  @override
  String get stepContextDetail =>
      '¿Quién escribe, a quién y por qué? Consulta los temas del pasaje.';

  @override
  String get stepObserveTitle => 'Observa el texto';

  @override
  String get stepObserveDetail =>
      'Repeticiones, contrastes, conectores y tiempos verbales.';

  @override
  String get stepInterpretTitle => 'Interpreta';

  @override
  String get stepInterpretDetail =>
      '¿Qué significaba entonces? ¿Qué dice aquí y ahora?';

  @override
  String get stepApplyTitle => 'Aplica';

  @override
  String get stepApplyDetail =>
      '¿Qué te pide Dios hoy con este texto? Escríbelo en Notas.';

  @override
  String get stepNoteTitle => 'Anota tus conclusiones';

  @override
  String get stepNoteDetail =>
      'Ancla una nota al versículo y resume lo que descubriste.';

  @override
  String get stepWordTitle => 'Analiza las palabras clave';

  @override
  String stepWordDetail(String param) {
    return 'Busca «$param» en el catálogo y compara sus apariciones.';
  }

  @override
  String get stepCrossTitle => 'Sigue las referencias cruzadas';

  @override
  String get stepCrossDetail =>
      'Abre Ideas ▸ Pasajes relacionados en el lector y sigue las citas.';

  @override
  String get stepCompareTitle => 'Compara traducciones';

  @override
  String get stepCompareDetail =>
      'Compara el pasaje con la otra versión del catálogo.';

  @override
  String get stepOutlineTitle => 'Bosqueja el mensaje';

  @override
  String get stepOutlineDetail =>
      'Tres puntos con su aplicación, anotados en Notas.';

  @override
  String get stepThemeTitle => 'Encuentra el tema central';

  @override
  String get stepThemeDetail =>
      'Consulta los temas del pasaje en Temas y elige el eje del mensaje.';

  @override
  String get stepLectioTitle => 'Lectio: lee despacio';

  @override
  String stepLectioDetail(String param) {
    return 'Lee $param en voz alta, saboreando cada frase.';
  }

  @override
  String get stepMeditatioTitle => 'Meditatio: rumia el texto';

  @override
  String get stepMeditatioDetail =>
      '¿Qué palabra o frase te llama la atención? ¿Por qué?';

  @override
  String get stepOratioTitle => 'Oratio: responde en oración';

  @override
  String get stepOratioDetail => 'Convierte el texto en tu propia oración.';

  @override
  String get stepContemplatioTitle => 'Contemplatio: descansa en Dios';

  @override
  String get stepContemplatioDetail =>
      'Quédate en silencio con lo que Dios te mostró.';

  @override
  String get toolsAtlas => 'Atlas';

  @override
  String get toolsCourses => 'Cursos';

  @override
  String get toolsDocuments => 'Documentos';

  @override
  String get toolsInfo => 'Información';

  @override
  String get toolsMedia => 'Medios';

  @override
  String get toolsPlans => 'Planes de lectura';

  @override
  String get toolsSoon => 'Pronto';

  @override
  String get panelTitleReadingPlans => 'Planes de lectura';

  @override
  String get plansIntro =>
      'Elige un plan para leer la Biblia con un ritmo constante. El progreso se guarda en tu equipo.';

  @override
  String get plansEmpty => 'No tienes un plan activo. Elige uno para empezar.';

  @override
  String get plansAvailable => 'Planes disponibles';

  @override
  String get plansOther => 'Otros planes';

  @override
  String get plansInProgress => 'En curso';

  @override
  String get plansOpenToday => 'Abrir la lectura de hoy';

  @override
  String get plansMarkRead => 'Marcar día como leído';

  @override
  String get plansStop => 'Detener plan';

  @override
  String plansDayOf(int day, int days) {
    return 'Día $day de $days';
  }

  @override
  String get plansCompleted =>
      '¡Plan completado! Puedes empezar otro cuando quieras.';

  @override
  String get plansToday => 'Lectura de hoy';

  @override
  String plansDays(int days) {
    return '$days días';
  }

  @override
  String get plansStart => 'Comenzar';

  @override
  String get plansReplaceTitle => '¿Reemplazar el plan activo?';

  @override
  String get plansReplaceBody =>
      'Ya tienes un plan de lectura en curso. Si empiezas otro, se perderá su progreso.';

  @override
  String get plansReplace => 'Reemplazar';

  @override
  String get planBibleYearTitle => 'Biblia en un año';

  @override
  String get planBibleYearDesc => 'Todo el canon, unos tres capítulos al día.';

  @override
  String get planGospels30Title => 'Evangelios en 30 días';

  @override
  String get planGospels30Desc => 'Mateo, Marcos, Lucas y Juan completos.';

  @override
  String get planPsalms31Title => 'Salmos y Proverbios en 31 días';

  @override
  String get planPsalms31Desc => 'Sabiduría diaria durante un mes.';

  @override
  String get planNt90Title => 'Nuevo Testamento en 90 días';

  @override
  String get planNt90Desc => 'Los 27 libros del Nuevo Testamento.';

  @override
  String get readingPlanView => 'Ver plan de lectura';

  @override
  String get dashboardSubtitle =>
      'Continúa donde lo dejaste y retoma tus herramientas.';

  @override
  String get dashboardContinue => 'Continuar la lectura';

  @override
  String get dashboardContinueEmpty =>
      'Abre un pasaje desde la barra lateral o con el buscador para verlo aquí.';

  @override
  String get dashboardPlan => 'Plan de lectura';

  @override
  String get dashboardPlanEmpty => 'No tienes un plan activo.';

  @override
  String get dashboardPlanChoose => 'Elegir un plan';

  @override
  String get dashboardPlanView => 'Ver el plan';

  @override
  String get dashboardNotes => 'Notas';

  @override
  String dashboardNotesCount(int notes, int highlights) {
    String _temp0 = intl.Intl.pluralLogic(
      notes,
      locale: localeName,
      other: '$notes notas',
      one: '1 nota',
    );
    String _temp1 = intl.Intl.pluralLogic(
      highlights,
      locale: localeName,
      other: '$highlights resaltados',
      one: '1 resaltado',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get dashboardNotesOpen => 'Abrir Notas';

  @override
  String get dashboardDevotional => 'Devocional de hoy';

  @override
  String get dashboardDevotionalOpen => 'Abrir el devocional';

  @override
  String get dashboardGuided => 'Estudio guiado';

  @override
  String get dashboardGuidedOpen => 'Abrir el estudio guiado';

  @override
  String get dashboardTools => 'Herramientas';

  @override
  String get assistantLead =>
      'Solo pregunta. Usaré tu biblioteca para responder preguntas como…';

  @override
  String get assistantPrompt1 => '¿Qué enseña Juan 1 sobre el Verbo?';

  @override
  String get assistantPrompt2 => '¿Cómo describe el Salmo 23 al pastor?';

  @override
  String get assistantPrompt3 => '¿Qué dicen los evangelios sobre el perdón?';

  @override
  String get assistantAiNotice =>
      'Esta función usa IA. Verifica siempre los resultados.';

  @override
  String get assistantConnect => 'Conectar un proveedor de IA';

  @override
  String get assistantConnectTail => 'para empezar la conversación.';

  @override
  String get assistantDialogTitle => 'Asistente de estudio';

  @override
  String get assistantDialogBody =>
      'El asistente es un plugin opcional: esta instalación no tiene ningún proveedor de IA conectado. Cuando lo conectes, las respuestas llegarán con citas de tu biblioteca. Mientras tanto, el Estudio guiado y las demás herramientas funcionan en local.';

  @override
  String get assistantDialogOpenGuided => 'Abrir el Estudio guiado';

  @override
  String get assistantChatHint =>
      'Haz una pregunta sobre tu biblioteca: las respuestas llegan con citas que abren el lector.';

  @override
  String get assistantNew => 'Nuevo';

  @override
  String get assistantRecent => 'Recientes';

  @override
  String get assistantRecentEmpty => 'Aún no hay preguntas.';

  @override
  String get assistantCopyAll => 'Copiar todo';

  @override
  String get assistantCopied => 'Conversación copiada.';

  @override
  String get assistantScope => 'Alcance';

  @override
  String get assistantScopeAll => 'Todos los libros';

  @override
  String get assistantScopeBible => 'La Biblia';

  @override
  String get assistantInput => 'Escribe tu pregunta…';

  @override
  String get assistantSend => 'Enviar';

  @override
  String get assistantThinking => 'Pensando…';

  @override
  String get assistantYou => 'Tú';

  @override
  String get assistantAnswerLabel => 'Asistente';

  @override
  String get assistantFailed => 'No se pudo obtener respuesta del proveedor.';

  @override
  String get readerLinkSetNone => 'Sin conjunto';

  @override
  String get readerLinkSetHelp =>
      'Los paneles con la misma letra siguen la misma referencia.';

  @override
  String get storeTitle => 'Tienda de módulos';

  @override
  String get storeIntro =>
      'El catálogo desacoplado reparte el contenido en módulos del dominio público y Creative Commons. Elige qué instalar: se descarga con progreso y luego se lee sin depender de la red.';

  @override
  String storeCount(int count) {
    return '$count recursos disponibles';
  }

  @override
  String get storeIncluded => 'Incluido';

  @override
  String get storeOpen => 'Abrir';

  @override
  String get storeSearch => 'Buscar recursos';

  @override
  String get storeAllTypes => 'Todos los tipos';

  @override
  String get storeAllSubjects => 'Todos los temas';

  @override
  String get storeAllPublishers => 'Todas las editoriales';

  @override
  String get storeEmpty => 'No hay recursos que coincidan.';

  @override
  String get storeError => 'No se pudo cargar el catálogo local.';

  @override
  String get storeRetry => 'Reintentar';

  @override
  String get storeOpenLibrary => 'Abrir la Biblioteca';

  @override
  String get storeLicense => 'Licencia';

  @override
  String get panelFullscreenEnter => 'Pantalla completa';

  @override
  String get panelFullscreenExit => 'Salir de pantalla completa';

  @override
  String get settingsTheme => 'Tema de la interfaz';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsThemeHelp => 'Claro, oscuro o según el sistema.';

  @override
  String get readerOriginal => 'Original';

  @override
  String get readerOriginalTooltip => 'Abrir el texto original';

  @override
  String get wordStudyTitle => 'Estudio de la palabra';

  @override
  String get wordStudyStrong => 'Strong';

  @override
  String get wordStudyTranslit => 'Transliteración';

  @override
  String get wordStudyLemma => 'Lema';

  @override
  String get wordStudyMorphology => 'Morfología';

  @override
  String get wordStudyGloss => 'Glosa';

  @override
  String get wordStudyGlossSource => 'Glosa de la fuente (inglés)';

  @override
  String get wordStudyOpenLexicon => 'Abrir en el léxico';

  @override
  String get wordStudyLexiconTitle => 'Léxico Strong';

  @override
  String get wordStudyLexiconError =>
      'No se pudo cargar la entrada del léxico.';

  @override
  String get wordStudyNoLexicon =>
      'No hay una entrada del léxico para esta palabra.';

  @override
  String get tabFullscreen => 'Pantalla completa';

  @override
  String get mapTitle => 'Mapa';

  @override
  String get mapLoadError => 'No se pudo cargar el mapa.';

  @override
  String get mapAttribution =>
      'Geometría: Natural Earth (dominio público) · Lugares: OpenBible.info (CC BY 4.0)';

  @override
  String get panelTitleAtlas => 'Atlas';

  @override
  String get panelTitleCourses => 'Cursos';

  @override
  String get panelTitleDocuments => 'Documentos';

  @override
  String get panelTitleMedia => 'Medios';

  @override
  String get panelTitleFavorites => 'Favoritos';

  @override
  String get panelTitlePsalms => 'Explorador de Salmos';

  @override
  String get toolsFavorites => 'Favoritos';

  @override
  String get toolsPsalms => 'Explorador de Salmos';

  @override
  String get atlasIntro =>
      'Explora los mapas del Factbook y del comentario. Se dibujan sin conexión con la geometría de Natural Earth y las coordenadas de OpenBible.info.';

  @override
  String get mediaIntro =>
      'Galería de contenido visual del catálogo. Cada ficha abre el mapa y la sección original que lo acompaña.';

  @override
  String get atlasSearchHint => 'Buscar un mapa o un lugar';

  @override
  String get mediaSearchHint => 'Buscar en los medios';

  @override
  String get atlasSourceAll => 'Todas las fuentes';

  @override
  String get atlasSourceFactbook => 'Factbook';

  @override
  String get atlasSourceCommentary => 'Comentario';

  @override
  String get atlasLoadError => 'No se pudo cargar esta entrada del catálogo.';

  @override
  String get mediaLoadError => 'No se pudieron cargar los medios.';

  @override
  String get atlasEmpty => 'Todavía no hay mapas en el catálogo empaquetado.';

  @override
  String get mediaEmpty =>
      'Todavía no hay contenido visual en el catálogo empaquetado.';

  @override
  String get atlasAttribution =>
      'Mapas propios del catálogo de Aletheia. La geometría y las coordenadas conservan su atribución.';

  @override
  String get atlasNoResults => 'Ningún mapa coincide con la búsqueda.';

  @override
  String atlasCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entradas',
      one: '1 entrada',
    );
    return '$_temp0';
  }

  @override
  String get mediaOpenMap => 'Abrir mapa';

  @override
  String get atlasOpenResource => 'Abrir la sección';

  @override
  String get coursesIntro =>
      'Rutas breves de estudio con lecturas de la RV1909. Elige una y avanza lección a lección.';

  @override
  String get coursesSearchHint => 'Buscar un curso';

  @override
  String get coursesNoResults => 'Ningún curso coincide con la búsqueda.';

  @override
  String coursesLessons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lecciones',
      one: '1 lección',
    );
    return '$_temp0';
  }

  @override
  String get courseCompleted =>
      'Curso completado. Puedes repasar sus lecturas cuando quieras.';

  @override
  String courseProgress(int done, int total) {
    return 'Progreso: $done de $total';
  }

  @override
  String get courseLessonRead => 'Leer';

  @override
  String get coursePanoramaTitle => 'Panorama bíblico';

  @override
  String get coursePanoramaDesc =>
      'Tres paradas para recorrer la historia bíblica: creación, éxodo y monarquía.';

  @override
  String get coursePanoramaLesson1Title => 'La creación y la alianza';

  @override
  String get coursePanoramaLesson1Detail =>
      'Lee el comienzo de Génesis y observa cómo Dios ordena la creación y llama a la vida.';

  @override
  String get coursePanoramaLesson2Title => 'Éxodo y liberación';

  @override
  String get coursePanoramaLesson2Detail =>
      'La zarza ardiente presenta el nombre de Dios y el comienzo de la liberación de Egipto.';

  @override
  String get coursePanoramaLesson3Title => 'Reyes y profetas';

  @override
  String get coursePanoramaLesson3Detail =>
      'La elección de David abre una nueva etapa de la historia de Israel.';

  @override
  String get courseGospelsTitle => 'Los Evangelios';

  @override
  String get courseGospelsDesc =>
      'El anuncio del Reino, la misericordia y la resurrección en tres lecturas.';

  @override
  String get courseGospelsLesson1Title => 'El Reino se acerca';

  @override
  String get courseGospelsLesson1Detail =>
      'Jesús proclama el Reino y llama a la conversión en Galilea.';

  @override
  String get courseGospelsLesson2Title => 'Parábolas y misericordia';

  @override
  String get courseGospelsLesson2Detail =>
      'Las parábolas de Lucas 15 muestran el corazón del Padre que busca a los perdidos.';

  @override
  String get courseGospelsLesson3Title => 'Cruz y resurrección';

  @override
  String get courseGospelsLesson3Detail =>
      'La tumba vacía abre el Evangelio de Juan y la misión de la comunidad.';

  @override
  String get coursePrayerTitle => 'Salmos y oración';

  @override
  String get coursePrayerDesc =>
      'Tres salmos para orar con confianza, lamento y alabanza.';

  @override
  String get coursePrayerLesson1Title => 'Confianza en el pastor';

  @override
  String get coursePrayerLesson1Detail =>
      'El Salmo 23 acompaña la oración con la imagen del pastor que cuida.';

  @override
  String get coursePrayerLesson2Title => 'El lamento sincero';

  @override
  String get coursePrayerLesson2Detail =>
      'El Salmo 42 enseña a llevar la sed y la tristeza delante de Dios.';

  @override
  String get coursePrayerLesson3Title => 'La alabanza de todo el pueblo';

  @override
  String get coursePrayerLesson3Detail =>
      'El Salmo 100 invita a celebrar la fidelidad de Dios con gratitud.';

  @override
  String get documentsIntro =>
      'Tres guías breves de estudio propias de Aletheia, pensadas para acompañar la lectura y la consulta del catálogo.';

  @override
  String get documentsSearchHint => 'Buscar en los documentos';

  @override
  String get documentsNoResults => 'Ningún documento coincide con la búsqueda.';

  @override
  String get documentsAttribution =>
      'Documentos propios de Aletheia; no reproducen obras licenciadas de terceros.';

  @override
  String get documentReadingTitle => 'Cómo leer la Biblia';

  @override
  String get documentReadingSubtitle =>
      'Un método sencillo en cuatro pasos: observar, interpretar, aplicar y orar.';

  @override
  String get documentReadingBody =>
      '## Antes de leer\n\nLa Biblia es una biblioteca de libros escritos en épocas distintas. Antes de buscar una aplicación inmediata, sitúa el pasaje: ¿quién escribe, a quién se dirige y qué problema o promesa aparece en el contexto?\n\n## Observar\n\nLee el texto despacio y anota lo que dice, no lo que esperas que diga. Fíjate en las palabras repetidas, las personas, los lugares, los contrastes y las órdenes. Una buena observación prepara una buena interpretación.\n\n## Interpretar\n\nPregunta qué significaba el pasaje para sus primeros lectores y cómo encaja en la historia bíblica. Compara traducciones y consulta el comentario o el diccionario cuando una palabra o una costumbre no sean claras.\n\n## Aplicar y orar\n\nLa aplicación nace del sentido del texto, no al revés. Termina convirtiendo lo que has visto en una oración: agradece, confiesa, pide ayuda y comprométete a un paso concreto.';

  @override
  String get documentTimelineTitle => 'Cronología bíblica';

  @override
  String get documentTimelineSubtitle =>
      'Cuatro etapas para orientarse en la historia del Antiguo y del Nuevo Testamento.';

  @override
  String get documentTimelineBody =>
      '## Patriarcas y éxodo\n\nGénesis presenta a Abraham, Isaac y Jacob; Éxodo narra la liberación de Egipto y la alianza del Sinaí. Son relatos de llamada, promesa y formación de un pueblo.\n\n## Monarquía y profetas\n\nSamuel, Saúl y David inauguran la monarquía. Los profetas llaman al pueblo a la fidelidad a la alianza y anuncian juicio y esperanza.\n\n## Exilio y retorno\n\nLa caída de Jerusalén y el exilio en Babilonia marcan una crisis profunda. Esdras y Nehemías relatan la reconstrucción; los salmos y los profetas guardan la memoria de la espera.\n\n## Jesús y la iglesia\n\nLos Evangelios presentan a Jesús como el cumplimiento de las promesas. Hechos y las cartas describen la comunidad que anuncia su muerte y resurrección.';

  @override
  String get documentGlossaryTitle => 'Glosario de estudio';

  @override
  String get documentGlossarySubtitle =>
      'Cuatro términos que aparecen una y otra vez en la lectura bíblica.';

  @override
  String get documentGlossaryBody =>
      '## Alianza\n\nUn vínculo establecido por Dios con su pueblo, con promesas y compromisos. No es un contrato entre iguales: Dios toma la iniciativa y sostiene la relación.\n\n## Gracia\n\nEl favor que Dios concede sin que sea una recompensa merecida. En el Nuevo Testamento es la base de la salvación y de la vida cristiana.\n\n## Justificación\n\nEl acto por el que Dios declara justo al pecador que cree, sobre la base de la obra de Cristo. No es una mejora moral previa, sino una nueva relación con Dios.\n\n## Mesianismo\n\nLa esperanza de un rey o enviado de Dios que restaure a su pueblo. Los Evangelios leen en Jesús el cumplimiento de esa espera, a la vez presente y futura.';

  @override
  String get favoritesIntro =>
      'Guarda pasajes para volver a ellos. También puedes añadir una referencia directamente.';

  @override
  String get favoritesAddHint => 'Referencia: Juan 3:16';

  @override
  String get favoritesAdd => 'Añadir';

  @override
  String get favoritesInvalidReference => 'No se reconoce esa referencia.';

  @override
  String get favoritesAlreadySaved => 'Ese pasaje ya está en Favoritos.';

  @override
  String get favoritesPassageSubtitle => 'Pasaje de la RV1909';

  @override
  String get favoritesSearchHint => 'Buscar en Favoritos';

  @override
  String get favoritesEmpty =>
      'Todavía no tienes favoritos. Usa la estrella del lector o añade una referencia.';

  @override
  String get favoritesNoResults => 'Ningún favorito coincide con la búsqueda.';

  @override
  String get favoritesOpen => 'Abrir favorito';

  @override
  String get favoritesRemove => 'Quitar de Favoritos';

  @override
  String get favoritesAdded => 'Añadido a Favoritos';

  @override
  String get favoritesRemoved => 'Quitado de Favoritos';

  @override
  String get psalmsIntro =>
      'Recorre los 150 salmos por género y abre cualquiera en el lector. Las categorías se solapan.';

  @override
  String get psalmsSearchHint => 'Buscar un salmo o una palabra';

  @override
  String psalmsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count salmos',
      one: '1 salmo',
    );
    return '$_temp0';
  }

  @override
  String get psalmsAll => 'Todos';

  @override
  String get psalmsNoResults => 'Ningún salmo coincide con la búsqueda.';

  @override
  String get psalmsAttribution =>
      'Clasificación propia de Aletheia; el texto bíblico es la RV1909, de dominio público.';

  @override
  String get psalmOfDay => 'Salmo del día';

  @override
  String psalmNumber(int number) {
    return 'Salmo $number';
  }

  @override
  String get psalmsOpen => 'Leer';

  @override
  String get psalmsSubtitle => 'Salmo de la RV1909';

  @override
  String get psalmCategoryPraise => 'Alabanza';

  @override
  String get psalmCategoryLament => 'Lamento';

  @override
  String get psalmCategoryTrust => 'Confianza';

  @override
  String get psalmCategoryThanks => 'Acción de gracias';

  @override
  String get psalmCategoryWisdom => 'Sabiduría';

  @override
  String get psalmCategoryMessianic => 'Mesiánicos';

  @override
  String get psalmCategoryPenitential => 'Penitenciales';

  @override
  String get psalmCategoryPilgrimage => 'Peregrinación';

  @override
  String get moduleInstall => 'Instalar';

  @override
  String get moduleCancel => 'Cancelar instalación';

  @override
  String moduleSize(String size) {
    return '$size';
  }

  @override
  String get moduleAvailableBody =>
      'Este recurso vive en el catálogo desacoplado: instálalo para leerlo sin depender de la red después.';

  @override
  String get moduleInstallFailed =>
      'No se pudo completar la instalación. Revisa la conexión y vuelve a intentarlo.';

  @override
  String moduleDownloading(String received) {
    return 'Descargando… $received';
  }

  @override
  String get moduleInstallUnavailable =>
      'Este recurso se descarga al abrirse; para gestionarlo como módulo usa la app de escritorio.';

  @override
  String readerBookNotAvailable(String book, String resource) {
    return '$book no está disponible en $resource. El catálogo desacoplado trae solo una parte de los libros en cada recurso.';
  }

  @override
  String readerOpenEquivalent(String book, String resource) {
    return 'Abrir $book en $resource';
  }

  @override
  String get storeInstallButton => 'Instalar';

  @override
  String get storeInstalledBadge => 'Instalado';

  @override
  String get storeUpdateBadge => 'Actualización disponible';

  @override
  String get storeUninstallButton => 'Desinstalar';

  @override
  String get storeCancelInstall => 'Cancelar';

  @override
  String get storeConfirmUninstall =>
      '¿Quitar el módulo de este dispositivo? Podrás volver a instalarlo desde aquí.';

  @override
  String get storeRemovedTitle => 'Módulo quitado';

  @override
  String storeUninstalledSnackbar(String module) {
    return 'Se quitó $module.';
  }

  @override
  String get storeInstallErrorTitle => 'La instalación falló';

  @override
  String get storeSectionInstalled => 'Instalados';

  @override
  String get storeSectionAvailable => 'Disponibles';

  @override
  String get storeSearchModuleHint =>
      'El índice de búsqueda local también es un módulo: sin él la búsqueda funciona con el servicio, no en frío.';

  @override
  String get libraryNotInstalledChip => 'No instalado';

  @override
  String get libraryInstalledChip => 'Instalado';

  @override
  String get dataCareTitle => 'Datos y respaldo';

  @override
  String get backupExport => 'Exportar respaldo…';

  @override
  String get backupExportHelp =>
      'Guarda tus notas, resaltados, favoritos, planes y diseños en un archivo de respaldo.';

  @override
  String backupExported(String path) {
    return 'Respaldo guardado en $path';
  }

  @override
  String get backupRestore => 'Restaurar respaldo…';

  @override
  String get backupRestoreHelp =>
      'Elige un respaldo anterior; se aplicará la próxima vez que abras Aletheia.';

  @override
  String get backupRestoreConfirmTitle => '¿Restaurar este respaldo?';

  @override
  String backupRestoreConfirmBody(String date, String version) {
    return 'Se restaurarán tus datos del $date (respaldo hecho con la versión $version). Tus datos actuales se guardan antes de reemplazarse.';
  }

  @override
  String get backupRestoreApply => 'Restaurar y reiniciar';

  @override
  String get backupStagedRestart =>
      'Respaldo listo: se aplicará la próxima vez que abras Aletheia.';

  @override
  String get crashLogExport => 'Exportar registro de fallos…';

  @override
  String get crashLogHelp =>
      'Registro local de errores, sin telemetría; sirve para reportar problemas.';

  @override
  String get crashLogEmpty => 'No hay registro de fallos.';

  @override
  String crashLogExported(String path) {
    return 'Registro guardado en $path';
  }

  @override
  String get crashLogClear => 'Borrar registro de fallos';

  @override
  String get crashLogCleared => 'Registro borrado.';

  @override
  String get updateCheck => 'Buscar actualizaciones';

  @override
  String get updateCheckHelp =>
      'Compara tu versión con la última publicada en GitHub. Sin telemetría.';

  @override
  String get updateNone => 'Estás usando la última versión.';

  @override
  String updateAvailableTitle(String version) {
    return 'Hay una versión nueva: $version';
  }

  @override
  String get updateAvailableBody =>
      'Puedes descargar el binario para tu plataforma desde la página de releases de GitHub.';

  @override
  String get updateOpenReleases => 'Abrir releases';

  @override
  String aboutVersion(String version) {
    return 'Aletheia $version';
  }

  @override
  String get exportPassage => 'Exportar pasaje…';

  @override
  String get exportNote => 'Exportar nota…';

  @override
  String get exportFormat => 'Formato';

  @override
  String get exportFormatMarkdown => 'Markdown';

  @override
  String get exportFormatHtml => 'HTML';

  @override
  String get exportFormatPlain => 'Texto plano';

  @override
  String get exportCopy => 'Copiar al portapapeles';

  @override
  String get exportSave => 'Guardar archivo…';

  @override
  String get exportPrint => 'Imprimir…';

  @override
  String get exportPrintHelp =>
      'Abre el pasaje en tu navegador con el diálogo de impresión.';

  @override
  String exportSaved(String path) {
    return 'Archivo guardado en $path';
  }

  @override
  String get exportCopied => 'Exportación copiada al portapapeles';
}
