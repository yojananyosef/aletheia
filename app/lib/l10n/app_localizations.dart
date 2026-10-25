import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('es'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'Aletheia'**
  String get appTitle;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @bannerDev.
  ///
  /// In es, this message translates to:
  /// **'Aletheia · catálogo bíblico de dominio público'**
  String get bannerDev;

  /// No description provided for @bannerOpenLibrary.
  ///
  /// In es, this message translates to:
  /// **'Abrir Biblioteca'**
  String get bannerOpenLibrary;

  /// No description provided for @bannerClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar banner'**
  String get bannerClose;

  /// No description provided for @navHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navHome;

  /// No description provided for @navLibrary.
  ///
  /// In es, this message translates to:
  /// **'Biblioteca'**
  String get navLibrary;

  /// No description provided for @navSearch.
  ///
  /// In es, this message translates to:
  /// **'Búsqueda'**
  String get navSearch;

  /// No description provided for @navBible.
  ///
  /// In es, this message translates to:
  /// **'Biblia'**
  String get navBible;

  /// No description provided for @navAssistant.
  ///
  /// In es, this message translates to:
  /// **'Asistente de estudio'**
  String get navAssistant;

  /// No description provided for @navTopics.
  ///
  /// In es, this message translates to:
  /// **'Temas'**
  String get navTopics;

  /// No description provided for @navGuidedStudy.
  ///
  /// In es, this message translates to:
  /// **'Estudio guiado'**
  String get navGuidedStudy;

  /// No description provided for @navNotes.
  ///
  /// In es, this message translates to:
  /// **'Notas'**
  String get navNotes;

  /// No description provided for @navTools.
  ///
  /// In es, this message translates to:
  /// **'Herramientas'**
  String get navTools;

  /// No description provided for @navQuickActions.
  ///
  /// In es, this message translates to:
  /// **'Acciones rápidas'**
  String get navQuickActions;

  /// No description provided for @navStore.
  ///
  /// In es, this message translates to:
  /// **'Tienda'**
  String get navStore;

  /// No description provided for @navLayouts.
  ///
  /// In es, this message translates to:
  /// **'Diseños'**
  String get navLayouts;

  /// No description provided for @navCloseAllTabs.
  ///
  /// In es, this message translates to:
  /// **'Cerrar todas las pestañas'**
  String get navCloseAllTabs;

  /// No description provided for @quickOpenCommentary.
  ///
  /// In es, this message translates to:
  /// **'Abrir un comentario'**
  String get quickOpenCommentary;

  /// No description provided for @quickOpenStudyBible.
  ///
  /// In es, this message translates to:
  /// **'Abrir una Biblia de estudio'**
  String get quickOpenStudyBible;

  /// No description provided for @quickCompareBibles.
  ///
  /// In es, this message translates to:
  /// **'Comparar versiones'**
  String get quickCompareBibles;

  /// No description provided for @quickOpenDictionary.
  ///
  /// In es, this message translates to:
  /// **'Abrir un diccionario bíblico'**
  String get quickOpenDictionary;

  /// No description provided for @quickOpenDevotional.
  ///
  /// In es, this message translates to:
  /// **'Abrir el devocional de hoy'**
  String get quickOpenDevotional;

  /// No description provided for @moreOptions.
  ///
  /// In es, this message translates to:
  /// **'Más opciones'**
  String get moreOptions;

  /// No description provided for @menuSettings.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get menuSettings;

  /// No description provided for @menuResourceCatalog.
  ///
  /// In es, this message translates to:
  /// **'Catálogo de recursos'**
  String get menuResourceCatalog;

  /// No description provided for @menuOriginalStore.
  ///
  /// In es, this message translates to:
  /// **'Tienda de la app original (no aplica)'**
  String get menuOriginalStore;

  /// No description provided for @menuDownloadApp.
  ///
  /// In es, this message translates to:
  /// **'Descargar la app original (no aplica)'**
  String get menuDownloadApp;

  /// No description provided for @sidebarExpand.
  ///
  /// In es, this message translates to:
  /// **'Expandir barra lateral'**
  String get sidebarExpand;

  /// No description provided for @sidebarCollapse.
  ///
  /// In es, this message translates to:
  /// **'Colapsar barra lateral'**
  String get sidebarCollapse;

  /// No description provided for @layoutOne.
  ///
  /// In es, this message translates to:
  /// **'Una columna'**
  String get layoutOne;

  /// No description provided for @layoutTwo.
  ///
  /// In es, this message translates to:
  /// **'Dos columnas'**
  String get layoutTwo;

  /// No description provided for @layoutTwoRows.
  ///
  /// In es, this message translates to:
  /// **'Dos filas'**
  String get layoutTwoRows;

  /// No description provided for @layoutThree.
  ///
  /// In es, this message translates to:
  /// **'Tres columnas'**
  String get layoutThree;

  /// No description provided for @layoutFour.
  ///
  /// In es, this message translates to:
  /// **'Cuadrícula 2×2'**
  String get layoutFour;

  /// No description provided for @omniboxHint.
  ///
  /// In es, this message translates to:
  /// **'Pasaje o tema'**
  String get omniboxHint;

  /// No description provided for @omniboxGoto.
  ///
  /// In es, this message translates to:
  /// **'Ir a {reference}'**
  String omniboxGoto(String reference);

  /// No description provided for @omniboxSearch.
  ///
  /// In es, this message translates to:
  /// **'Buscar «{query}»'**
  String omniboxSearch(String query);

  /// No description provided for @workspaceEmptyTile.
  ///
  /// In es, this message translates to:
  /// **'Sin pestañas — abre algo desde la barra lateral'**
  String get workspaceEmptyTile;

  /// No description provided for @panelCommands.
  ///
  /// In es, this message translates to:
  /// **'Comandos del panel'**
  String get panelCommands;

  /// No description provided for @tabClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar pestaña'**
  String get tabClose;

  /// No description provided for @tabDuplicate.
  ///
  /// In es, this message translates to:
  /// **'Duplicar esta pestaña'**
  String get tabDuplicate;

  /// No description provided for @tabCloseThis.
  ///
  /// In es, this message translates to:
  /// **'Cerrar esta pestaña'**
  String get tabCloseThis;

  /// No description provided for @tabCloseToRight.
  ///
  /// In es, this message translates to:
  /// **'Cerrar pestañas a la derecha'**
  String get tabCloseToRight;

  /// No description provided for @tabCloseOthers.
  ///
  /// In es, this message translates to:
  /// **'Cerrar otras pestañas'**
  String get tabCloseOthers;

  /// No description provided for @tabCloseAll.
  ///
  /// In es, this message translates to:
  /// **'Cerrar todas las pestañas'**
  String get tabCloseAll;

  /// No description provided for @panelTitleDashboard.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get panelTitleDashboard;

  /// No description provided for @panelTitleLibrary.
  ///
  /// In es, this message translates to:
  /// **'Biblioteca'**
  String get panelTitleLibrary;

  /// No description provided for @panelTitleStore.
  ///
  /// In es, this message translates to:
  /// **'Tienda'**
  String get panelTitleStore;

  /// No description provided for @panelTitleSearch.
  ///
  /// In es, this message translates to:
  /// **'Búsqueda'**
  String get panelTitleSearch;

  /// No description provided for @panelTitleResource.
  ///
  /// In es, this message translates to:
  /// **'Recurso'**
  String get panelTitleResource;

  /// No description provided for @panelTitleBible.
  ///
  /// In es, this message translates to:
  /// **'Biblia'**
  String get panelTitleBible;

  /// No description provided for @panelTitleStudyAssistant.
  ///
  /// In es, this message translates to:
  /// **'Asistente de estudio'**
  String get panelTitleStudyAssistant;

  /// No description provided for @panelTitleFactbook.
  ///
  /// In es, this message translates to:
  /// **'Temas'**
  String get panelTitleFactbook;

  /// No description provided for @panelTitleGuidedStudy.
  ///
  /// In es, this message translates to:
  /// **'Estudio guiado'**
  String get panelTitleGuidedStudy;

  /// No description provided for @panelTitleNotes.
  ///
  /// In es, this message translates to:
  /// **'Notas'**
  String get panelTitleNotes;

  /// No description provided for @panelTitleTools.
  ///
  /// In es, this message translates to:
  /// **'Herramientas'**
  String get panelTitleTools;

  /// No description provided for @panelTitleTextComparison.
  ///
  /// In es, this message translates to:
  /// **'Comparación de textos'**
  String get panelTitleTextComparison;

  /// No description provided for @panelTitleDevotional.
  ///
  /// In es, this message translates to:
  /// **'Devocional del día'**
  String get panelTitleDevotional;

  /// No description provided for @panelTitleSettings.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get panelTitleSettings;

  /// No description provided for @placeholderDashboard.
  ///
  /// In es, this message translates to:
  /// **'Estado del espacio de trabajo y banners configurables (M3).'**
  String get placeholderDashboard;

  /// No description provided for @placeholderLibrary.
  ///
  /// In es, this message translates to:
  /// **'La Biblioteca se abre desde la barra lateral como panel flotante (M2): búsqueda, facetas y detalle de recursos.'**
  String get placeholderLibrary;

  /// No description provided for @placeholderStore.
  ///
  /// In es, this message translates to:
  /// **'Catálogo navegable de recursos de dominio público (M5). Sin compras: los recursos propios se marcan como disponibles.'**
  String get placeholderStore;

  /// No description provided for @placeholderResource.
  ///
  /// In es, this message translates to:
  /// **'Lector de recursos no bíblicos (M5): comentarios, diccionarios y libros desde el catálogo.'**
  String get placeholderResource;

  /// No description provided for @placeholderStudyAssistant.
  ///
  /// In es, this message translates to:
  /// **'Asistente de estudio (plugin IA opcional, M6): chat con citas a recursos, adjuntos y selección de alcance.'**
  String get placeholderStudyAssistant;

  /// No description provided for @placeholderFactbook.
  ///
  /// In es, this message translates to:
  /// **'Temas (M5): artículos por tema o referencia con secciones y temas relacionados.'**
  String get placeholderFactbook;

  /// No description provided for @placeholderGuidedStudy.
  ///
  /// In es, this message translates to:
  /// **'Estudio guiado (M6): guías (estudio de palabras, exégesis, pasaje, bosquejo de sermón) y flujos de trabajo guiados.'**
  String get placeholderGuidedStudy;

  /// No description provided for @placeholderTools.
  ///
  /// In es, this message translates to:
  /// **'Centro de herramientas (M5): Atlas, Documentos, Favoritos, Información, Multimedia, Explorador de Salmos, Gestor de planes de lectura, Comparación de textos.'**
  String get placeholderTools;

  /// No description provided for @placeholderTextComparison.
  ///
  /// In es, this message translates to:
  /// **'Comparación de textos (M5): referencia + conjunto de versiones en columnas sincronizadas por versículo.'**
  String get placeholderTextComparison;

  /// No description provided for @placeholderDevotional.
  ///
  /// In es, this message translates to:
  /// **'Devocional del día (M5): recursos con calendario (formato MM-DD), navegación mañana/tarde.'**
  String get placeholderDevotional;

  /// No description provided for @placeholderFallback.
  ///
  /// In es, this message translates to:
  /// **'Pendiente en próximos milestones.'**
  String get placeholderFallback;

  /// No description provided for @readerBack.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get readerBack;

  /// No description provided for @readerForward.
  ///
  /// In es, this message translates to:
  /// **'Adelante'**
  String get readerForward;

  /// No description provided for @readerChangeBook.
  ///
  /// In es, this message translates to:
  /// **'Cambiar libro'**
  String get readerChangeBook;

  /// No description provided for @readerModeHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get readerModeHome;

  /// No description provided for @readerModeSearch.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get readerModeSearch;

  /// No description provided for @readerModeNotes.
  ///
  /// In es, this message translates to:
  /// **'Notas'**
  String get readerModeNotes;

  /// No description provided for @readerModeFormat.
  ///
  /// In es, this message translates to:
  /// **'Formato'**
  String get readerModeFormat;

  /// No description provided for @readerModeView.
  ///
  /// In es, this message translates to:
  /// **'Vista'**
  String get readerModeView;

  /// No description provided for @readerModeMore.
  ///
  /// In es, this message translates to:
  /// **'Más'**
  String get readerModeMore;

  /// No description provided for @readerSearchInResource.
  ///
  /// In es, this message translates to:
  /// **'Buscar en este recurso'**
  String get readerSearchInResource;

  /// No description provided for @readerToolsSoon.
  ///
  /// In es, this message translates to:
  /// **'Herramientas — M6'**
  String get readerToolsSoon;

  /// No description provided for @readerCopyReference.
  ///
  /// In es, this message translates to:
  /// **'Copiar referencia'**
  String get readerCopyReference;

  /// No description provided for @readerCopyCitation.
  ///
  /// In es, this message translates to:
  /// **'Copiar cita'**
  String get readerCopyCitation;

  /// No description provided for @readerCopyPassageAndCitation.
  ///
  /// In es, this message translates to:
  /// **'Copiar pasaje y cita'**
  String get readerCopyPassageAndCitation;

  /// No description provided for @readerCopied.
  ///
  /// In es, this message translates to:
  /// **'Copiado al portapapeles'**
  String get readerCopied;

  /// No description provided for @readerContents.
  ///
  /// In es, this message translates to:
  /// **'Índice'**
  String get readerContents;

  /// No description provided for @readerContentsTooltip.
  ///
  /// In es, this message translates to:
  /// **'Índice de contenidos'**
  String get readerContentsTooltip;

  /// No description provided for @readerArticle.
  ///
  /// In es, this message translates to:
  /// **'Artículo'**
  String get readerArticle;

  /// No description provided for @readerArticleStepTo.
  ///
  /// In es, this message translates to:
  /// **'Ir a artículo'**
  String get readerArticleStepTo;

  /// No description provided for @readerArticlePrevious.
  ///
  /// In es, this message translates to:
  /// **'Artículo anterior'**
  String get readerArticlePrevious;

  /// No description provided for @readerArticleNext.
  ///
  /// In es, this message translates to:
  /// **'Artículo siguiente'**
  String get readerArticleNext;

  /// No description provided for @readerPrevChapter.
  ///
  /// In es, this message translates to:
  /// **'Capítulo anterior'**
  String get readerPrevChapter;

  /// No description provided for @readerNextChapter.
  ///
  /// In es, this message translates to:
  /// **'Capítulo siguiente'**
  String get readerNextChapter;

  /// No description provided for @readerLinkSet.
  ///
  /// In es, this message translates to:
  /// **'Conjunto de vínculos'**
  String get readerLinkSet;

  /// No description provided for @readerLinkSetSoon.
  ///
  /// In es, this message translates to:
  /// **'Conjunto de vínculos — M6'**
  String get readerLinkSetSoon;

  /// No description provided for @readerInsights.
  ///
  /// In es, this message translates to:
  /// **'Análisis'**
  String get readerInsights;

  /// No description provided for @readerInfo.
  ///
  /// In es, this message translates to:
  /// **'Información'**
  String get readerInfo;

  /// No description provided for @insightsTitle.
  ///
  /// In es, this message translates to:
  /// **'Ideas'**
  String get insightsTitle;

  /// No description provided for @insightsClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar el panel'**
  String get insightsClose;

  /// No description provided for @insightsBookInfoTab.
  ///
  /// In es, this message translates to:
  /// **'Información del libro'**
  String get insightsBookInfoTab;

  /// No description provided for @insightsAbout.
  ///
  /// In es, this message translates to:
  /// **'Acerca de {title}'**
  String insightsAbout(String title);

  /// No description provided for @insightsAuthor.
  ///
  /// In es, this message translates to:
  /// **'Autor'**
  String get insightsAuthor;

  /// No description provided for @insightsPublisher.
  ///
  /// In es, this message translates to:
  /// **'Editorial'**
  String get insightsPublisher;

  /// No description provided for @insightsEdition.
  ///
  /// In es, this message translates to:
  /// **'Edición'**
  String get insightsEdition;

  /// No description provided for @insightsLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get insightsLanguage;

  /// No description provided for @insightsType.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get insightsType;

  /// No description provided for @insightsStats.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get insightsStats;

  /// No description provided for @insightsVerseCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 versículo} other{{count} versículos}}'**
  String insightsVerseCount(int count);

  /// No description provided for @insightsSectionCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 sección} other{{count} secciones}}'**
  String insightsSectionCount(int count);

  /// No description provided for @insightsAuxId.
  ///
  /// In es, this message translates to:
  /// **'Identificador'**
  String get insightsAuxId;

  /// No description provided for @insightsAuxType.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get insightsAuxType;

  /// No description provided for @insightsAuxSource.
  ///
  /// In es, this message translates to:
  /// **'Fuente'**
  String get insightsAuxSource;

  /// No description provided for @insightsAuxiliary.
  ///
  /// In es, this message translates to:
  /// **'Información auxiliar'**
  String get insightsAuxiliary;

  /// No description provided for @insightsBookInfoUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Sin ficha del recurso.'**
  String get insightsBookInfoUnavailable;

  /// No description provided for @insightsCopyright.
  ///
  /// In es, this message translates to:
  /// **'Copyright'**
  String get insightsCopyright;

  /// No description provided for @insightsLicenseUnknown.
  ///
  /// In es, this message translates to:
  /// **'Licencia no indicada.'**
  String get insightsLicenseUnknown;

  /// No description provided for @insightsRelatedBooks.
  ///
  /// In es, this message translates to:
  /// **'Libros relacionados'**
  String get insightsRelatedBooks;

  /// No description provided for @insightsNoBooks.
  ///
  /// In es, this message translates to:
  /// **'Ningún recurso del catálogo cita esta referencia.'**
  String get insightsNoBooks;

  /// No description provided for @insightsRelatedPassages.
  ///
  /// In es, this message translates to:
  /// **'Pasajes relacionados'**
  String get insightsRelatedPassages;

  /// No description provided for @insightsCrossReferences.
  ///
  /// In es, this message translates to:
  /// **'Referencias cruzadas'**
  String get insightsCrossReferences;

  /// No description provided for @insightsNoPassages.
  ///
  /// In es, this message translates to:
  /// **'Sin pasajes relacionados en el catálogo actual.'**
  String get insightsNoPassages;

  /// No description provided for @insightsRelatedError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el contenido relacionado.'**
  String get insightsRelatedError;

  /// No description provided for @insightsMore.
  ///
  /// In es, this message translates to:
  /// **'Más »'**
  String get insightsMore;

  /// No description provided for @readingPlanStart.
  ///
  /// In es, this message translates to:
  /// **'Comenzar plan de lectura'**
  String get readingPlanStart;

  /// No description provided for @readerHideLocationBar.
  ///
  /// In es, this message translates to:
  /// **'Ocultar la barra de ubicación'**
  String get readerHideLocationBar;

  /// No description provided for @readerShowLocationBar.
  ///
  /// In es, this message translates to:
  /// **'Mostrar la barra de ubicación'**
  String get readerShowLocationBar;

  /// No description provided for @readerHideSecondaryToolbar.
  ///
  /// In es, this message translates to:
  /// **'Ocultar la barra secundaria'**
  String get readerHideSecondaryToolbar;

  /// No description provided for @readerShowSecondaryToolbar.
  ///
  /// In es, this message translates to:
  /// **'Mostrar la barra secundaria'**
  String get readerShowSecondaryToolbar;

  /// No description provided for @readerHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get readerHistory;

  /// No description provided for @readerHistoryPanel.
  ///
  /// In es, this message translates to:
  /// **'Historial del panel'**
  String get readerHistoryPanel;

  /// No description provided for @readerHistoryEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin historial todavía'**
  String get readerHistoryEmpty;

  /// No description provided for @readerLoadMoreChapters.
  ///
  /// In es, this message translates to:
  /// **'Cargar más capítulos'**
  String get readerLoadMoreChapters;

  /// No description provided for @readerEnd.
  ///
  /// In es, this message translates to:
  /// **'— Fin —'**
  String get readerEnd;

  /// No description provided for @readerFootnote.
  ///
  /// In es, this message translates to:
  /// **'Nota {label}'**
  String readerFootnote(String label);

  /// No description provided for @readerFootnoteUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Nota al pie no disponible.'**
  String get readerFootnoteUnavailable;

  /// No description provided for @readerFootnoteA11y.
  ///
  /// In es, this message translates to:
  /// **'Nota al pie {label}: {text}'**
  String readerFootnoteA11y(String label, String text);

  /// No description provided for @readerFootnoteOpenHint.
  ///
  /// In es, this message translates to:
  /// **'Ver la nota al pie'**
  String get readerFootnoteOpenHint;

  /// No description provided for @readerXrefOpenHint.
  ///
  /// In es, this message translates to:
  /// **'Ir a la referencia cruzada'**
  String get readerXrefOpenHint;

  /// No description provided for @readerInvalidReference.
  ///
  /// In es, this message translates to:
  /// **'Referencia no válida: {reference}'**
  String readerInvalidReference(String reference);

  /// No description provided for @readerSectionMissing.
  ///
  /// In es, this message translates to:
  /// **'No se encontró {book} {chapter} en el documento.'**
  String readerSectionMissing(String book, int chapter);

  /// No description provided for @readerLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el documento: {error}'**
  String readerLoadError(String error);

  /// No description provided for @readerFootnoteList.
  ///
  /// In es, this message translates to:
  /// **'Notas al pie'**
  String get readerFootnoteList;

  /// No description provided for @contentsTitle.
  ///
  /// In es, this message translates to:
  /// **'Índice de contenidos'**
  String get contentsTitle;

  /// No description provided for @contentsFilter.
  ///
  /// In es, this message translates to:
  /// **'Filtrar libros'**
  String get contentsFilter;

  /// No description provided for @contentsSearch.
  ///
  /// In es, this message translates to:
  /// **'Buscar en el índice'**
  String get contentsSearch;

  /// No description provided for @contentsClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar el índice'**
  String get contentsClose;

  /// No description provided for @contentsChapter.
  ///
  /// In es, this message translates to:
  /// **'Capítulo {number}'**
  String contentsChapter(int number);

  /// No description provided for @changeBookTitle.
  ///
  /// In es, this message translates to:
  /// **'Cambiar libro'**
  String get changeBookTitle;

  /// No description provided for @changeBookLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las Biblias.\n{error}'**
  String changeBookLoadError(String error);

  /// No description provided for @changeBookEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados'**
  String get changeBookEmpty;

  /// No description provided for @panelSearchTitle.
  ///
  /// In es, this message translates to:
  /// **'Buscar en «{resource}»'**
  String panelSearchTitle(String resource);

  /// No description provided for @panelSearchSyntax.
  ///
  /// In es, this message translates to:
  /// **'Dentro de este recurso · palabras, \"frases\", AND/OR/NOT, WITHIN n WORDS'**
  String get panelSearchSyntax;

  /// No description provided for @searchFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo buscar'**
  String get searchFailed;

  /// No description provided for @panelSearchPrompt.
  ///
  /// In es, this message translates to:
  /// **'Escribe una consulta para buscar en todo el recurso. Cada resultado te lleva al versículo exacto.'**
  String get panelSearchPrompt;

  /// No description provided for @searchNoResults.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados para «{query}»'**
  String searchNoResults(String query);

  /// No description provided for @searchTryFewerWords.
  ///
  /// In es, this message translates to:
  /// **'Prueba con menos palabras'**
  String get searchTryFewerWords;

  /// No description provided for @searchTryFewerOrScope.
  ///
  /// In es, this message translates to:
  /// **'Prueba con menos palabras o otro ámbito'**
  String get searchTryFewerOrScope;

  /// No description provided for @searchResultsCountFor.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 resultado} other{{count} resultados}} para «{query}»'**
  String searchResultsCountFor(int count, String query);

  /// No description provided for @searchLoadMoreRemaining.
  ///
  /// In es, this message translates to:
  /// **'Cargar más ({count} restantes)'**
  String searchLoadMoreRemaining(int count);

  /// No description provided for @searchScope.
  ///
  /// In es, this message translates to:
  /// **'Ámbito: {scope}'**
  String searchScope(String scope);

  /// No description provided for @searchSyntaxTitle.
  ///
  /// In es, this message translates to:
  /// **'Sintaxis de búsqueda'**
  String get searchSyntaxTitle;

  /// No description provided for @searchSyntaxWord.
  ///
  /// In es, this message translates to:
  /// **'una palabra'**
  String get searchSyntaxWord;

  /// No description provided for @searchSyntaxPhrase.
  ///
  /// In es, this message translates to:
  /// **'\"en el principio\"'**
  String get searchSyntaxPhrase;

  /// No description provided for @searchSyntaxPhraseNote.
  ///
  /// In es, this message translates to:
  /// **'frase exacta'**
  String get searchSyntaxPhraseNote;

  /// No description provided for @searchSyntaxAnd.
  ///
  /// In es, this message translates to:
  /// **'Verbo AND principio'**
  String get searchSyntaxAnd;

  /// No description provided for @searchSyntaxAndNote.
  ///
  /// In es, this message translates to:
  /// **'ambas palabras (también OR y NOT)'**
  String get searchSyntaxAndNote;

  /// No description provided for @searchSyntaxWithin.
  ///
  /// In es, this message translates to:
  /// **'principio WITHIN 5 WORDS Verbo'**
  String get searchSyntaxWithin;

  /// No description provided for @searchSyntaxWithinNote.
  ///
  /// In es, this message translates to:
  /// **'a menos de 5 palabras de distancia'**
  String get searchSyntaxWithinNote;

  /// No description provided for @searchSyntaxBeforeNote.
  ///
  /// In es, this message translates to:
  /// **'un término aparece antes que el otro'**
  String get searchSyntaxBeforeNote;

  /// No description provided for @searchSyntaxNearNote.
  ///
  /// In es, this message translates to:
  /// **'a menos de 10 palabras (NEAR/5 para 5)'**
  String get searchSyntaxNearNote;

  /// No description provided for @searchSyntaxFieldNote.
  ///
  /// In es, this message translates to:
  /// **'pasaje y filtros: bible:, type:, language:, book:'**
  String get searchSyntaxFieldNote;

  /// No description provided for @searchSyntaxNote.
  ///
  /// In es, this message translates to:
  /// **'La búsqueda es insensible a mayúsculas y acentos. Combina la sintaxis con los filtros de tipo, idioma y libro; los resultados se agrupan por recurso.'**
  String get searchSyntaxNote;

  /// No description provided for @searchMorphologyTitle.
  ///
  /// In es, this message translates to:
  /// **'Morfología'**
  String get searchMorphologyTitle;

  /// No description provided for @searchKeyboardTitle.
  ///
  /// In es, this message translates to:
  /// **'Teclado griego y hebreo'**
  String get searchKeyboardTitle;

  /// No description provided for @searchKeyboardGreek.
  ///
  /// In es, this message translates to:
  /// **'Griego'**
  String get searchKeyboardGreek;

  /// No description provided for @searchKeyboardHebrew.
  ///
  /// In es, this message translates to:
  /// **'Hebreo'**
  String get searchKeyboardHebrew;

  /// No description provided for @searchKeyboardHint.
  ///
  /// In es, this message translates to:
  /// **'Toca una letra para insertarla en la búsqueda.'**
  String get searchKeyboardHint;

  /// No description provided for @searchKeyboardBackspace.
  ///
  /// In es, this message translates to:
  /// **'Borrar una letra'**
  String get searchKeyboardBackspace;

  /// No description provided for @searchFilterType.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get searchFilterType;

  /// No description provided for @searchFilterLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get searchFilterLanguage;

  /// No description provided for @searchFilterBook.
  ///
  /// In es, this message translates to:
  /// **'Libro'**
  String get searchFilterBook;

  /// No description provided for @searchFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get searchFilterAll;

  /// No description provided for @searchFilterAllBooks.
  ///
  /// In es, this message translates to:
  /// **'Todos los libros'**
  String get searchFilterAllBooks;

  /// No description provided for @searchFilterClear.
  ///
  /// In es, this message translates to:
  /// **'Limpiar filtros'**
  String get searchFilterClear;

  /// No description provided for @searchBack.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get searchBack;

  /// No description provided for @searchTitle.
  ///
  /// In es, this message translates to:
  /// **'Buscar en la Biblia y los libros'**
  String get searchTitle;

  /// No description provided for @searchHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial de búsquedas'**
  String get searchHistory;

  /// No description provided for @searchHistoryEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin búsquedas todavía'**
  String get searchHistoryEmpty;

  /// No description provided for @searchPromptTitle.
  ///
  /// In es, this message translates to:
  /// **'Busca en el catálogo'**
  String get searchPromptTitle;

  /// No description provided for @searchPromptBody.
  ///
  /// In es, this message translates to:
  /// **'Palabras, frases entre comillas, AND/OR/NOT, NEAR, WITHIN n WORDS y campos como bible:\"Jn 3\". Cada resultado abre el recurso en el pasaje exacto.'**
  String get searchPromptBody;

  /// No description provided for @searchIndexUnavailable.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el índice de búsqueda local. Reinstala la app o vuelve a generar el catálogo.'**
  String get searchIndexUnavailable;

  /// No description provided for @searchDownloadTitle.
  ///
  /// In es, this message translates to:
  /// **'Primera búsqueda: descargando el índice'**
  String get searchDownloadTitle;

  /// No description provided for @searchDownloadBody.
  ///
  /// In es, this message translates to:
  /// **'El índice pesa {size}. Se guardará en la caché del navegador para las próximas búsquedas.'**
  String searchDownloadBody(String size);

  /// No description provided for @searchDownloadProgress.
  ///
  /// In es, this message translates to:
  /// **'{received} de {total}'**
  String searchDownloadProgress(String received, String total);

  /// No description provided for @searchDownloadUnknown.
  ///
  /// In es, this message translates to:
  /// **'{received} descargados'**
  String searchDownloadUnknown(String received);

  /// No description provided for @searchDownloadCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get searchDownloadCancel;

  /// No description provided for @searchDownloadCancelled.
  ///
  /// In es, this message translates to:
  /// **'Descarga cancelada. La próxima búsqueda volverá a intentarlo.'**
  String get searchDownloadCancelled;

  /// No description provided for @scopeAll.
  ///
  /// In es, this message translates to:
  /// **'Todo'**
  String get scopeAll;

  /// No description provided for @scopeBible.
  ///
  /// In es, this message translates to:
  /// **'Biblia'**
  String get scopeBible;

  /// No description provided for @scopeBooks.
  ///
  /// In es, this message translates to:
  /// **'Libros'**
  String get scopeBooks;

  /// No description provided for @scopeFactbook.
  ///
  /// In es, this message translates to:
  /// **'Temas'**
  String get scopeFactbook;

  /// No description provided for @scopeMorph.
  ///
  /// In es, this message translates to:
  /// **'Morfología'**
  String get scopeMorph;

  /// No description provided for @scopeMedia.
  ///
  /// In es, this message translates to:
  /// **'Multimedia'**
  String get scopeMedia;

  /// No description provided for @scopeMaps.
  ///
  /// In es, this message translates to:
  /// **'Mapas'**
  String get scopeMaps;

  /// No description provided for @scopeTodoNote.
  ///
  /// In es, this message translates to:
  /// **'M5'**
  String get scopeTodoNote;

  /// No description provided for @scopeMorphNote.
  ///
  /// In es, this message translates to:
  /// **'M6'**
  String get scopeMorphNote;

  /// No description provided for @fmtMarkers.
  ///
  /// In es, this message translates to:
  /// **'Marcadores'**
  String get fmtMarkers;

  /// No description provided for @fmtReformat.
  ///
  /// In es, this message translates to:
  /// **'Reformato'**
  String get fmtReformat;

  /// No description provided for @fmtTypography.
  ///
  /// In es, this message translates to:
  /// **'Tipografía'**
  String get fmtTypography;

  /// No description provided for @fontSerif.
  ///
  /// In es, this message translates to:
  /// **'Serif'**
  String get fontSerif;

  /// No description provided for @fontSans.
  ///
  /// In es, this message translates to:
  /// **'Sans'**
  String get fontSans;

  /// No description provided for @fontMono.
  ///
  /// In es, this message translates to:
  /// **'Mono'**
  String get fontMono;

  /// No description provided for @fmtReformatTitle.
  ///
  /// In es, this message translates to:
  /// **'Reformato del texto'**
  String get fmtReformatTitle;

  /// No description provided for @fmtMarkersTitle.
  ///
  /// In es, this message translates to:
  /// **'Mostrar marcadores'**
  String get fmtMarkersTitle;

  /// No description provided for @fmtBibleText.
  ///
  /// In es, this message translates to:
  /// **'Texto bíblico'**
  String get fmtBibleText;

  /// No description provided for @fmtBibleTextFormatting.
  ///
  /// In es, this message translates to:
  /// **'Formato del texto bíblico'**
  String get fmtBibleTextFormatting;

  /// No description provided for @fmtNumbers.
  ///
  /// In es, this message translates to:
  /// **'Números de capítulo y versículo'**
  String get fmtNumbers;

  /// No description provided for @fmtFootnoteIndicators.
  ///
  /// In es, this message translates to:
  /// **'Indicadores de notas'**
  String get fmtFootnoteIndicators;

  /// No description provided for @fmtNonBibleText.
  ///
  /// In es, this message translates to:
  /// **'Texto no bíblico'**
  String get fmtNonBibleText;

  /// No description provided for @fmtOneVersePerLine.
  ///
  /// In es, this message translates to:
  /// **'Un versículo por línea'**
  String get fmtOneVersePerLine;

  /// No description provided for @fmtCorrespondingWords.
  ///
  /// In es, this message translates to:
  /// **'Palabras correspondientes'**
  String get fmtCorrespondingWords;

  /// No description provided for @fmtSameSurfaceText.
  ///
  /// In es, this message translates to:
  /// **'Mismo texto superficial'**
  String get fmtSameSurfaceText;

  /// No description provided for @fmtNote.
  ///
  /// In es, this message translates to:
  /// **'Reformatea el cuerpo principal del libro.'**
  String get fmtNote;

  /// No description provided for @fmtMarkersNote.
  ///
  /// In es, this message translates to:
  /// **'Añade marcadores para mostrar datos ocultos del libro. Con Marcadores activo, solo se ven los indicadores y resaltados de los cuadernos y etiquetas marcados.'**
  String get fmtMarkersNote;

  /// No description provided for @fmtSermons.
  ///
  /// In es, this message translates to:
  /// **'Sermones'**
  String get fmtSermons;

  /// No description provided for @fmtBibleStudies.
  ///
  /// In es, this message translates to:
  /// **'Estudios bíblicos'**
  String get fmtBibleStudies;

  /// No description provided for @fmtMarkersNotebooks.
  ///
  /// In es, this message translates to:
  /// **'Cuadernos'**
  String get fmtMarkersNotebooks;

  /// No description provided for @fmtMarkersTags.
  ///
  /// In es, this message translates to:
  /// **'Etiquetas'**
  String get fmtMarkersTags;

  /// No description provided for @fmtMarkersEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay cuadernos ni etiquetas. Crea una nota con cuaderno o etiqueta para filtrar los marcadores.'**
  String get fmtMarkersEmpty;

  /// No description provided for @viewPagedView.
  ///
  /// In es, this message translates to:
  /// **'Vista paginada'**
  String get viewPagedView;

  /// No description provided for @viewPagedTitle.
  ///
  /// In es, this message translates to:
  /// **'Vista paginada'**
  String get viewPagedTitle;

  /// No description provided for @viewColumns.
  ///
  /// In es, this message translates to:
  /// **'Columnas'**
  String get viewColumns;

  /// No description provided for @viewColumnsAuto.
  ///
  /// In es, this message translates to:
  /// **'Auto'**
  String get viewColumnsAuto;

  /// No description provided for @viewFootnotesOnPage.
  ///
  /// In es, this message translates to:
  /// **'Mostrar notas en la página'**
  String get viewFootnotesOnPage;

  /// No description provided for @viewLocatorBar.
  ///
  /// In es, this message translates to:
  /// **'Barra de ubicación'**
  String get viewLocatorBar;

  /// No description provided for @viewZoom.
  ///
  /// In es, this message translates to:
  /// **'Zoom'**
  String get viewZoom;

  /// No description provided for @viewFullScreen.
  ///
  /// In es, this message translates to:
  /// **'Pantalla completa'**
  String get viewFullScreen;

  /// No description provided for @viewExitFullScreen.
  ///
  /// In es, this message translates to:
  /// **'Salir de pantalla completa'**
  String get viewExitFullScreen;

  /// No description provided for @viewPageOf.
  ///
  /// In es, this message translates to:
  /// **'Página {page} de {total}'**
  String viewPageOf(int page, int total);

  /// No description provided for @viewPrevPage.
  ///
  /// In es, this message translates to:
  /// **'Página anterior'**
  String get viewPrevPage;

  /// No description provided for @viewNextPage.
  ///
  /// In es, this message translates to:
  /// **'Página siguiente'**
  String get viewNextPage;

  /// No description provided for @viewZoomReset.
  ///
  /// In es, this message translates to:
  /// **'Restablecer el zoom al 100 %'**
  String get viewZoomReset;

  /// No description provided for @settingsReset.
  ///
  /// In es, this message translates to:
  /// **'Restablecer valores'**
  String get settingsReset;

  /// No description provided for @settingsResetDone.
  ///
  /// In es, this message translates to:
  /// **'Valores restablecidos'**
  String get settingsResetDone;

  /// No description provided for @settingsCatalog.
  ///
  /// In es, this message translates to:
  /// **'Catálogo'**
  String get settingsCatalog;

  /// No description provided for @settingsServiceUrl.
  ///
  /// In es, this message translates to:
  /// **'Dirección del servicio'**
  String get settingsServiceUrl;

  /// No description provided for @settingsApply.
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get settingsApply;

  /// No description provided for @settingsCatalogModeAuto.
  ///
  /// In es, this message translates to:
  /// **'Automático'**
  String get settingsCatalogModeAuto;

  /// No description provided for @settingsCatalogModeLocal.
  ///
  /// In es, this message translates to:
  /// **'Solo incluidos'**
  String get settingsCatalogModeLocal;

  /// No description provided for @settingsCatalogModeRemote.
  ///
  /// In es, this message translates to:
  /// **'Solo servicio'**
  String get settingsCatalogModeRemote;

  /// No description provided for @settingsChecking.
  ///
  /// In es, this message translates to:
  /// **'Comprobando el servicio…'**
  String get settingsChecking;

  /// No description provided for @settingsOffline.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión — se usan los recursos incluidos en la app.'**
  String get settingsOffline;

  /// No description provided for @settingsOfflineError.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión: {error}'**
  String settingsOfflineError(String error);

  /// No description provided for @settingsOnline.
  ///
  /// In es, this message translates to:
  /// **'Conectado: {resources} recursos, {verses} versículos y {sections} entradas indexadas.'**
  String settingsOnline(int resources, String verses, String sections);

  /// No description provided for @settingsLocalReady.
  ///
  /// In es, this message translates to:
  /// **'Modo local: {resources} recursos, {verses} versículos y {sections} entradas indexadas.'**
  String settingsLocalReady(int resources, String verses, String sections);

  /// No description provided for @settingsRecheck.
  ///
  /// In es, this message translates to:
  /// **'Recomprobar'**
  String get settingsRecheck;

  /// No description provided for @settingsQuickActions.
  ///
  /// In es, this message translates to:
  /// **'Mostrar acciones rápidas'**
  String get settingsQuickActions;

  /// No description provided for @settingsBannersDashboard.
  ///
  /// In es, this message translates to:
  /// **'Mostrar banners en el panel de inicio'**
  String get settingsBannersDashboard;

  /// No description provided for @settingsBannersLayout.
  ///
  /// In es, this message translates to:
  /// **'Mostrar banners en los diseños'**
  String get settingsBannersLayout;

  /// No description provided for @settingsToolbarLocation.
  ///
  /// In es, this message translates to:
  /// **'Ubicación de la barra de aplicaciones'**
  String get settingsToolbarLocation;

  /// No description provided for @settingsToolbarLeft.
  ///
  /// In es, this message translates to:
  /// **'Izquierda'**
  String get settingsToolbarLeft;

  /// No description provided for @settingsToolbarTop.
  ///
  /// In es, this message translates to:
  /// **'Arriba'**
  String get settingsToolbarTop;

  /// No description provided for @settingsLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma de la interfaz'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsCitationStyle.
  ///
  /// In es, this message translates to:
  /// **'Estilo de citas'**
  String get settingsCitationStyle;

  /// No description provided for @citationTurabian.
  ///
  /// In es, this message translates to:
  /// **'Turabian (9.ª ed., nota completa)'**
  String get citationTurabian;

  /// No description provided for @citationSbl.
  ///
  /// In es, this message translates to:
  /// **'SBL (2.ª ed.)'**
  String get citationSbl;

  /// No description provided for @citationChicago.
  ///
  /// In es, this message translates to:
  /// **'Chicago (17.ª ed.)'**
  String get citationChicago;

  /// No description provided for @citationPlain.
  ///
  /// In es, this message translates to:
  /// **'Aletheia (simple)'**
  String get citationPlain;

  /// No description provided for @settingsCopyCitations.
  ///
  /// In es, this message translates to:
  /// **'Copiar la cita con el texto'**
  String get settingsCopyCitations;

  /// No description provided for @settingsHyperlinkCitations.
  ///
  /// In es, this message translates to:
  /// **'Enlazar las citas copiadas'**
  String get settingsHyperlinkCitations;

  /// No description provided for @settingsLimitedView.
  ///
  /// In es, this message translates to:
  /// **'Activar el modo de vista limitada'**
  String get settingsLimitedView;

  /// No description provided for @settingsLimitedViewHelp.
  ///
  /// In es, this message translates to:
  /// **'Vista accesible: sin paginación y con las notas al pie como lista al final de cada capítulo.'**
  String get settingsLimitedViewHelp;

  /// No description provided for @yes.
  ///
  /// In es, this message translates to:
  /// **'Sí'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In es, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @help.
  ///
  /// In es, this message translates to:
  /// **'Ayuda'**
  String get help;

  /// No description provided for @libraryFacets.
  ///
  /// In es, this message translates to:
  /// **'Facetas'**
  String get libraryFacets;

  /// No description provided for @libraryFind.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get libraryFind;

  /// No description provided for @libraryClear.
  ///
  /// In es, this message translates to:
  /// **'Limpiar'**
  String get libraryClear;

  /// No description provided for @libraryCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 recurso} other{{count} recursos}}'**
  String libraryCount(int count);

  /// No description provided for @libraryTabLibrary.
  ///
  /// In es, this message translates to:
  /// **'Biblioteca'**
  String get libraryTabLibrary;

  /// No description provided for @libraryTabStore.
  ///
  /// In es, this message translates to:
  /// **'Tienda'**
  String get libraryTabStore;

  /// No description provided for @libraryStoreSoon.
  ///
  /// In es, this message translates to:
  /// **'M5: catálogo de la tienda'**
  String get libraryStoreSoon;

  /// No description provided for @librarySort.
  ///
  /// In es, this message translates to:
  /// **'Ordenar'**
  String get librarySort;

  /// No description provided for @librarySortTitle.
  ///
  /// In es, this message translates to:
  /// **'por Título'**
  String get librarySortTitle;

  /// No description provided for @librarySortAuthor.
  ///
  /// In es, this message translates to:
  /// **'por Autor'**
  String get librarySortAuthor;

  /// No description provided for @librarySortDate.
  ///
  /// In es, this message translates to:
  /// **'por Fecha'**
  String get librarySortDate;

  /// No description provided for @libraryClearFilters.
  ///
  /// In es, this message translates to:
  /// **'Limpiar filtros'**
  String get libraryClearFilters;

  /// No description provided for @libraryFacetType.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get libraryFacetType;

  /// No description provided for @libraryFacetLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get libraryFacetLanguage;

  /// No description provided for @libraryFacetAuthor.
  ///
  /// In es, this message translates to:
  /// **'Autor'**
  String get libraryFacetAuthor;

  /// No description provided for @libraryFacetSubject.
  ///
  /// In es, this message translates to:
  /// **'Tema'**
  String get libraryFacetSubject;

  /// No description provided for @libraryFacetPublisher.
  ///
  /// In es, this message translates to:
  /// **'Editorial'**
  String get libraryFacetPublisher;

  /// No description provided for @libraryLoadMore.
  ///
  /// In es, this message translates to:
  /// **'Cargar más'**
  String get libraryLoadMore;

  /// No description provided for @libraryErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No se pudo consultar el catálogo'**
  String get libraryErrorTitle;

  /// No description provided for @libraryEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin recursos que coincidan con el filtro'**
  String get libraryEmpty;

  /// No description provided for @libraryBack.
  ///
  /// In es, this message translates to:
  /// **'Volver a la lista'**
  String get libraryBack;

  /// No description provided for @libraryOpen.
  ///
  /// In es, this message translates to:
  /// **'Abrir'**
  String get libraryOpen;

  /// No description provided for @libraryMore.
  ///
  /// In es, this message translates to:
  /// **'Más »'**
  String get libraryMore;

  /// No description provided for @libraryLess.
  ///
  /// In es, this message translates to:
  /// **'Menos «'**
  String get libraryLess;

  /// No description provided for @libraryStats.
  ///
  /// In es, this message translates to:
  /// **'{verses} versículos · {chapters} capítulos'**
  String libraryStats(String verses, String chapters);

  /// No description provided for @libraryLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando…'**
  String get libraryLoading;

  /// No description provided for @languageEs.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get languageEs;

  /// No description provided for @languageEn.
  ///
  /// In es, this message translates to:
  /// **'Inglés'**
  String get languageEn;

  /// No description provided for @languageEl.
  ///
  /// In es, this message translates to:
  /// **'Griego'**
  String get languageEl;

  /// No description provided for @languageHe.
  ///
  /// In es, this message translates to:
  /// **'Hebreo'**
  String get languageHe;

  /// No description provided for @languageLa.
  ///
  /// In es, this message translates to:
  /// **'Latín'**
  String get languageLa;

  /// No description provided for @typeBible.
  ///
  /// In es, this message translates to:
  /// **'Biblia'**
  String get typeBible;

  /// No description provided for @typeCommentary.
  ///
  /// In es, this message translates to:
  /// **'Comentario'**
  String get typeCommentary;

  /// No description provided for @typeDictionary.
  ///
  /// In es, this message translates to:
  /// **'Diccionario'**
  String get typeDictionary;

  /// No description provided for @typeEncyclopedia.
  ///
  /// In es, this message translates to:
  /// **'Enciclopedia'**
  String get typeEncyclopedia;

  /// No description provided for @typeDevotional.
  ///
  /// In es, this message translates to:
  /// **'Devocional'**
  String get typeDevotional;

  /// No description provided for @typeDataset.
  ///
  /// In es, this message translates to:
  /// **'Datos'**
  String get typeDataset;

  /// No description provided for @typeGuide.
  ///
  /// In es, this message translates to:
  /// **'Guía'**
  String get typeGuide;

  /// No description provided for @typeWorkflow.
  ///
  /// In es, this message translates to:
  /// **'Flujo de trabajo'**
  String get typeWorkflow;

  /// No description provided for @typeDocument.
  ///
  /// In es, this message translates to:
  /// **'Documento'**
  String get typeDocument;

  /// No description provided for @settingsCitationHelp.
  ///
  /// In es, this message translates to:
  /// **'Turabian (9.ª ed., nota completa) · SBL (2.ª ed.) · Chicago (17.ª ed.) · Aletheia (simple)'**
  String get settingsCitationHelp;

  /// No description provided for @resourceTitleCommentary.
  ///
  /// In es, this message translates to:
  /// **'Comentario'**
  String get resourceTitleCommentary;

  /// No description provided for @resourceTitleStudyBible.
  ///
  /// In es, this message translates to:
  /// **'Biblia de estudio'**
  String get resourceTitleStudyBible;

  /// No description provided for @resourceTitleDictionary.
  ///
  /// In es, this message translates to:
  /// **'Diccionario bíblico'**
  String get resourceTitleDictionary;

  /// No description provided for @resourceLabelMatthewHenry.
  ///
  /// In es, this message translates to:
  /// **'Matthew Henry (conciso)'**
  String get resourceLabelMatthewHenry;

  /// No description provided for @resourceLabelTsk.
  ///
  /// In es, this message translates to:
  /// **'Tesoro de conocimiento bíblico'**
  String get resourceLabelTsk;

  /// No description provided for @settingsBannersDashboardHelp.
  ///
  /// In es, this message translates to:
  /// **'Banner de novedades dentro del panel de inicio.'**
  String get settingsBannersDashboardHelp;

  /// No description provided for @settingsBannersLayoutHelp.
  ///
  /// In es, this message translates to:
  /// **'Los banners de los diseños (barra superior).'**
  String get settingsBannersLayoutHelp;

  /// No description provided for @settingsCopyHelp.
  ///
  /// In es, this message translates to:
  /// **'Al copiar un pasaje se añade su cita.'**
  String get settingsCopyHelp;

  /// No description provided for @settingsHyperlinkHelp.
  ///
  /// In es, this message translates to:
  /// **'Las citas copiadas enlazan al pasaje («ref:CANÓNICO»).'**
  String get settingsHyperlinkHelp;

  /// No description provided for @notesFind.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get notesFind;

  /// No description provided for @notesFindHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar en las notas'**
  String get notesFindHint;

  /// No description provided for @notesShare.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get notesShare;

  /// No description provided for @notesNewNote.
  ///
  /// In es, this message translates to:
  /// **'Nueva nota'**
  String get notesNewNote;

  /// No description provided for @notesAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get notesAll;

  /// No description provided for @notesResults.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 resultado} other{{count} resultados}}'**
  String notesResults(int count);

  /// No description provided for @notesFilters.
  ///
  /// In es, this message translates to:
  /// **'Filtros'**
  String get notesFilters;

  /// No description provided for @notesSidebarToggle.
  ///
  /// In es, this message translates to:
  /// **'Filtros y cuadernos'**
  String get notesSidebarToggle;

  /// No description provided for @notesNotebooks.
  ///
  /// In es, this message translates to:
  /// **'Cuadernos'**
  String get notesNotebooks;

  /// No description provided for @notesTrash.
  ///
  /// In es, this message translates to:
  /// **'Papelera'**
  String get notesTrash;

  /// No description provided for @notesByModified.
  ///
  /// In es, this message translates to:
  /// **'Fecha de modificación'**
  String get notesByModified;

  /// No description provided for @notesByCreated.
  ///
  /// In es, this message translates to:
  /// **'Fecha de creación'**
  String get notesByCreated;

  /// No description provided for @notesSortBy.
  ///
  /// In es, this message translates to:
  /// **'por {label}'**
  String notesSortBy(String label);

  /// No description provided for @notesByNotebook.
  ///
  /// In es, this message translates to:
  /// **'Cuaderno'**
  String get notesByNotebook;

  /// No description provided for @notesSortNotebookHint.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un cuaderno para activar el orden por cuaderno'**
  String get notesSortNotebookHint;

  /// No description provided for @notesDensity.
  ///
  /// In es, this message translates to:
  /// **'Densidad'**
  String get notesDensity;

  /// No description provided for @notesDensityDefault.
  ///
  /// In es, this message translates to:
  /// **'Predeterminado'**
  String get notesDensityDefault;

  /// No description provided for @notesDensityCompact.
  ///
  /// In es, this message translates to:
  /// **'Compacto'**
  String get notesDensityCompact;

  /// No description provided for @notesNewNoteInRef.
  ///
  /// In es, this message translates to:
  /// **'Nueva nota en {reference}'**
  String notesNewNoteInRef(String reference);

  /// No description provided for @notesByTitle.
  ///
  /// In es, this message translates to:
  /// **'por título'**
  String get notesByTitle;

  /// No description provided for @notesEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay notas'**
  String get notesEmpty;

  /// No description provided for @notesEmptyHint.
  ///
  /// In es, this message translates to:
  /// **'Crea una nota con «Nueva nota» o seleccionando un texto en el lector.'**
  String get notesEmptyHint;

  /// No description provided for @notesTrashEmpty.
  ///
  /// In es, this message translates to:
  /// **'La papelera está vacía'**
  String get notesTrashEmpty;

  /// No description provided for @notesTrashHint.
  ///
  /// In es, this message translates to:
  /// **'Puedes restaurar las notas o eliminarlas definitivamente.'**
  String get notesTrashHint;

  /// No description provided for @notesFilterKind.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get notesFilterKind;

  /// No description provided for @notesFilterKindNote.
  ///
  /// In es, this message translates to:
  /// **'Notas'**
  String get notesFilterKindNote;

  /// No description provided for @notesFilterKindHighlight.
  ///
  /// In es, this message translates to:
  /// **'Resaltados'**
  String get notesFilterKindHighlight;

  /// No description provided for @notesFilterNotebook.
  ///
  /// In es, this message translates to:
  /// **'Cuaderno'**
  String get notesFilterNotebook;

  /// No description provided for @notesFilterTag.
  ///
  /// In es, this message translates to:
  /// **'Etiqueta'**
  String get notesFilterTag;

  /// No description provided for @notesFilterResource.
  ///
  /// In es, this message translates to:
  /// **'Recurso'**
  String get notesFilterResource;

  /// No description provided for @notesFiltersClear.
  ///
  /// In es, this message translates to:
  /// **'Quitar los filtros'**
  String get notesFiltersClear;

  /// No description provided for @notesFiltersActive.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 filtro} other{{count} filtros}}'**
  String notesFiltersActive(num count);

  /// No description provided for @notesNewNotebook.
  ///
  /// In es, this message translates to:
  /// **'Nuevo cuaderno'**
  String get notesNewNotebook;

  /// No description provided for @notesNotebookName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del cuaderno'**
  String get notesNotebookName;

  /// No description provided for @notesNotebookCreate.
  ///
  /// In es, this message translates to:
  /// **'Crear cuaderno'**
  String get notesNotebookCreate;

  /// No description provided for @notesNotebookDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar el cuaderno «{name}»?'**
  String notesNotebookDeleteTitle(Object name);

  /// No description provided for @notesNotebookDeleteBody.
  ///
  /// In es, this message translates to:
  /// **'Las notas no se eliminan: solo se quitan del cuaderno.'**
  String get notesNotebookDeleteBody;

  /// No description provided for @notesNotebookEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin cuadernos todavía'**
  String get notesNotebookEmpty;

  /// No description provided for @notesNotebookNotes.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 nota} other{{count} notas}}'**
  String notesNotebookNotes(num count);

  /// No description provided for @notesRename.
  ///
  /// In es, this message translates to:
  /// **'Renombrar'**
  String get notesRename;

  /// No description provided for @notesRestore.
  ///
  /// In es, this message translates to:
  /// **'Restaurar'**
  String get notesRestore;

  /// No description provided for @notesPurge.
  ///
  /// In es, this message translates to:
  /// **'Eliminar definitivamente'**
  String get notesPurge;

  /// No description provided for @notesEmptyTrashAction.
  ///
  /// In es, this message translates to:
  /// **'Vaciar la papelera'**
  String get notesEmptyTrashAction;

  /// No description provided for @notesDuplicate.
  ///
  /// In es, this message translates to:
  /// **'Duplicar'**
  String get notesDuplicate;

  /// No description provided for @notesEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get notesEdit;

  /// No description provided for @notesOpen.
  ///
  /// In es, this message translates to:
  /// **'Abrir'**
  String get notesOpen;

  /// No description provided for @notesClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar la nota'**
  String get notesClose;

  /// No description provided for @notesShowInReader.
  ///
  /// In es, this message translates to:
  /// **'Mostrar en el lector'**
  String get notesShowInReader;

  /// No description provided for @notesNoAnchor.
  ///
  /// In es, this message translates to:
  /// **'Sin anclaje'**
  String get notesNoAnchor;

  /// No description provided for @notesAnchoredAt.
  ///
  /// In es, this message translates to:
  /// **'Anclada en {reference}'**
  String notesAnchoredAt(Object reference);

  /// No description provided for @notesItemCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 nota} other{{count} notas}}'**
  String notesItemCount(num count);

  /// No description provided for @notesTrashCount.
  ///
  /// In es, this message translates to:
  /// **'en la papelera: {count}'**
  String notesTrashCount(Object count);

  /// No description provided for @noteTitleHint.
  ///
  /// In es, this message translates to:
  /// **'Título de la nota'**
  String get noteTitleHint;

  /// No description provided for @noteBodyHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe una nota…'**
  String get noteBodyHint;

  /// No description provided for @noteQuoteLabel.
  ///
  /// In es, this message translates to:
  /// **'Cita'**
  String get noteQuoteLabel;

  /// No description provided for @noteQuoteRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar la cita'**
  String get noteQuoteRemove;

  /// No description provided for @noteFormatBold.
  ///
  /// In es, this message translates to:
  /// **'Negrita'**
  String get noteFormatBold;

  /// No description provided for @noteFormatItalic.
  ///
  /// In es, this message translates to:
  /// **'Cursiva'**
  String get noteFormatItalic;

  /// No description provided for @noteFormatUnderline.
  ///
  /// In es, this message translates to:
  /// **'Subrayado'**
  String get noteFormatUnderline;

  /// No description provided for @noteFormatHighlight.
  ///
  /// In es, this message translates to:
  /// **'Resaltado'**
  String get noteFormatHighlight;

  /// No description provided for @noteFormatBullets.
  ///
  /// In es, this message translates to:
  /// **'Lista con viñetas'**
  String get noteFormatBullets;

  /// No description provided for @noteFormatNumbered.
  ///
  /// In es, this message translates to:
  /// **'Lista numerada'**
  String get noteFormatNumbered;

  /// No description provided for @noteFormatQuote.
  ///
  /// In es, this message translates to:
  /// **'Cita en bloque'**
  String get noteFormatQuote;

  /// No description provided for @noteFormatReference.
  ///
  /// In es, this message translates to:
  /// **'Insertar referencia'**
  String get noteFormatReference;

  /// No description provided for @noteNotebooksLabel.
  ///
  /// In es, this message translates to:
  /// **'Cuadernos'**
  String get noteNotebooksLabel;

  /// No description provided for @noteNotebookAdd.
  ///
  /// In es, this message translates to:
  /// **'Añadir a un cuaderno'**
  String get noteNotebookAdd;

  /// No description provided for @noteTagsLabel.
  ///
  /// In es, this message translates to:
  /// **'Etiquetas'**
  String get noteTagsLabel;

  /// No description provided for @noteTagAdd.
  ///
  /// In es, this message translates to:
  /// **'Añadir etiqueta'**
  String get noteTagAdd;

  /// No description provided for @noteTagHint.
  ///
  /// In es, this message translates to:
  /// **'Nueva etiqueta'**
  String get noteTagHint;

  /// No description provided for @noteAnchorLabel.
  ///
  /// In es, this message translates to:
  /// **'Anclaje'**
  String get noteAnchorLabel;

  /// No description provided for @noteAnchorChange.
  ///
  /// In es, this message translates to:
  /// **'Cambiar el anclaje'**
  String get noteAnchorChange;

  /// No description provided for @noteSaved.
  ///
  /// In es, this message translates to:
  /// **'Guardado'**
  String get noteSaved;

  /// No description provided for @noteCreatedOn.
  ///
  /// In es, this message translates to:
  /// **'Creada el {date}'**
  String noteCreatedOn(Object date);

  /// No description provided for @noteModifiedOn.
  ///
  /// In es, this message translates to:
  /// **'Modificada el {date}'**
  String noteModifiedOn(Object date);

  /// No description provided for @noteDeletedOn.
  ///
  /// In es, this message translates to:
  /// **'Eliminada el {date}'**
  String noteDeletedOn(Object date);

  /// No description provided for @noteShareCopied.
  ///
  /// In es, this message translates to:
  /// **'Nota copiada al portapapeles'**
  String get noteShareCopied;

  /// No description provided for @noteShareMarkdown.
  ///
  /// In es, this message translates to:
  /// **'Copiar como Markdown'**
  String get noteShareMarkdown;

  /// No description provided for @noteShareText.
  ///
  /// In es, this message translates to:
  /// **'Copiar como texto'**
  String get noteShareText;

  /// No description provided for @noteKindNote.
  ///
  /// In es, this message translates to:
  /// **'Nota'**
  String get noteKindNote;

  /// No description provided for @noteKindHighlight.
  ///
  /// In es, this message translates to:
  /// **'Resaltado'**
  String get noteKindHighlight;

  /// No description provided for @noteColorYellow.
  ///
  /// In es, this message translates to:
  /// **'Amarillo'**
  String get noteColorYellow;

  /// No description provided for @noteColorGreen.
  ///
  /// In es, this message translates to:
  /// **'Verde'**
  String get noteColorGreen;

  /// No description provided for @noteColorBlue.
  ///
  /// In es, this message translates to:
  /// **'Azul'**
  String get noteColorBlue;

  /// No description provided for @noteColorRed.
  ///
  /// In es, this message translates to:
  /// **'Rojo'**
  String get noteColorRed;

  /// No description provided for @noteColorOrange.
  ///
  /// In es, this message translates to:
  /// **'Anaranjado'**
  String get noteColorOrange;

  /// No description provided for @noteColorPink.
  ///
  /// In es, this message translates to:
  /// **'Rosa'**
  String get noteColorPink;

  /// No description provided for @readerNotesNew.
  ///
  /// In es, this message translates to:
  /// **'Nueva nota'**
  String get readerNotesNew;

  /// No description provided for @readerNotesEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay notas en este recurso'**
  String get readerNotesEmpty;

  /// No description provided for @readerNotesEmptyHint.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un texto para crear una nota o un resaltado.'**
  String get readerNotesEmptyHint;

  /// No description provided for @readerNotesOnVerse.
  ///
  /// In es, this message translates to:
  /// **'Notas sobre el versículo {verse}'**
  String readerNotesOnVerse(Object verse);

  /// No description provided for @readerNoteMarker.
  ///
  /// In es, this message translates to:
  /// **'Notas en este versículo'**
  String get readerNoteMarker;

  /// No description provided for @readerHighlightCreated.
  ///
  /// In es, this message translates to:
  /// **'Resaltado añadido'**
  String get readerHighlightCreated;

  /// No description provided for @readerNoteCreated.
  ///
  /// In es, this message translates to:
  /// **'Nota creada'**
  String get readerNoteCreated;

  /// No description provided for @readerNotesView.
  ///
  /// In es, this message translates to:
  /// **'Notas de este recurso'**
  String get readerNotesView;

  /// No description provided for @selectionCopy.
  ///
  /// In es, this message translates to:
  /// **'Copiar'**
  String get selectionCopy;

  /// No description provided for @selectionLookUp.
  ///
  /// In es, this message translates to:
  /// **'Consultar'**
  String get selectionLookUp;

  /// No description provided for @selectionHighlight.
  ///
  /// In es, this message translates to:
  /// **'Resaltar'**
  String get selectionHighlight;

  /// No description provided for @selectionNote.
  ///
  /// In es, this message translates to:
  /// **'Nota'**
  String get selectionNote;

  /// No description provided for @selectionAddNote.
  ///
  /// In es, this message translates to:
  /// **'Agregar nota'**
  String get selectionAddNote;

  /// No description provided for @selectionSearch.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get selectionSearch;

  /// No description provided for @selectionMore.
  ///
  /// In es, this message translates to:
  /// **'Mostrar más opciones'**
  String get selectionMore;

  /// No description provided for @selectionVisualCopy.
  ///
  /// In es, this message translates to:
  /// **'Copia visual'**
  String get selectionVisualCopy;

  /// No description provided for @selectionUnderlineRed.
  ///
  /// In es, this message translates to:
  /// **'Subrayado rojo'**
  String get selectionUnderlineRed;

  /// No description provided for @selectionRemoveHighlight.
  ///
  /// In es, this message translates to:
  /// **'Quitar resaltado'**
  String get selectionRemoveHighlight;

  /// No description provided for @readerHighlightUpdated.
  ///
  /// In es, this message translates to:
  /// **'Resaltado actualizado'**
  String get readerHighlightUpdated;

  /// No description provided for @readerHighlightRemoved.
  ///
  /// In es, this message translates to:
  /// **'Resaltado quitado'**
  String get readerHighlightRemoved;

  /// No description provided for @highlightSwatch.
  ///
  /// In es, this message translates to:
  /// **'Resaltado {color}'**
  String highlightSwatch(String color);

  /// No description provided for @underlineSwatch.
  ///
  /// In es, this message translates to:
  /// **'Subrayado {color}'**
  String underlineSwatch(String color);

  /// No description provided for @selectionCitation.
  ///
  /// In es, this message translates to:
  /// **'Copiar cita'**
  String get selectionCitation;

  /// No description provided for @selectionNoteStub.
  ///
  /// In es, this message translates to:
  /// **'Nota'**
  String get selectionNoteStub;

  /// No description provided for @devotionalToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get devotionalToday;

  /// No description provided for @devotionalPrevious.
  ///
  /// In es, this message translates to:
  /// **'Día anterior'**
  String get devotionalPrevious;

  /// No description provided for @devotionalNext.
  ///
  /// In es, this message translates to:
  /// **'Día siguiente'**
  String get devotionalNext;

  /// No description provided for @devotionalPickDate.
  ///
  /// In es, this message translates to:
  /// **'Elegir fecha'**
  String get devotionalPickDate;

  /// No description provided for @devotionalEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'No hay lectura para esta fecha'**
  String get devotionalEmptyTitle;

  /// No description provided for @devotionalEmptyDetail.
  ///
  /// In es, this message translates to:
  /// **'Prueba con otro día o vuelve a hoy.'**
  String get devotionalEmptyDetail;

  /// No description provided for @factbookSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Tema o referencia'**
  String get factbookSearchHint;

  /// No description provided for @factbookLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la enciclopedia.'**
  String get factbookLoadError;

  /// No description provided for @factbookTopicsCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 tema} other{{count} temas}}'**
  String factbookTopicsCount(int count);

  /// No description provided for @factbookNoResults.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron temas'**
  String get factbookNoResults;

  /// No description provided for @factbookOpenPassage.
  ///
  /// In es, this message translates to:
  /// **'Abrir pasaje'**
  String get factbookOpenPassage;

  /// No description provided for @factbookLensAll.
  ///
  /// In es, this message translates to:
  /// **'Todo'**
  String get factbookLensAll;

  /// No description provided for @factbookLensBiblical.
  ///
  /// In es, this message translates to:
  /// **'Bíblico'**
  String get factbookLensBiblical;

  /// No description provided for @factbookLensLibrary.
  ///
  /// In es, this message translates to:
  /// **'Biblioteca'**
  String get factbookLensLibrary;

  /// No description provided for @factbookLensTheology.
  ///
  /// In es, this message translates to:
  /// **'Teológico'**
  String get factbookLensTheology;

  /// No description provided for @factbookLensCounseling.
  ///
  /// In es, this message translates to:
  /// **'Consejería'**
  String get factbookLensCounseling;

  /// No description provided for @factbookLensDiscover.
  ///
  /// In es, this message translates to:
  /// **'Descubra'**
  String get factbookLensDiscover;

  /// No description provided for @factbookBack.
  ///
  /// In es, this message translates to:
  /// **'Volver a los temas'**
  String get factbookBack;

  /// No description provided for @factbookReferences.
  ///
  /// In es, this message translates to:
  /// **'Referencias'**
  String get factbookReferences;

  /// No description provided for @factbookRelated.
  ///
  /// In es, this message translates to:
  /// **'Temas relacionados'**
  String get factbookRelated;

  /// No description provided for @catalogFilterHint.
  ///
  /// In es, this message translates to:
  /// **'Filtrar por título o tema'**
  String get catalogFilterHint;

  /// No description provided for @catalogEntriesCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 entrada} other{{count} entradas}}'**
  String catalogEntriesCount(int count);

  /// No description provided for @catalogBackToIndex.
  ///
  /// In es, this message translates to:
  /// **'Volver al índice'**
  String get catalogBackToIndex;

  /// No description provided for @compareReferenceHint.
  ///
  /// In es, this message translates to:
  /// **'Referencia'**
  String get compareReferenceHint;

  /// No description provided for @compareVersions.
  ///
  /// In es, this message translates to:
  /// **'Versiones'**
  String get compareVersions;

  /// No description provided for @compareVersionsCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 versión} other{{count} versiones}}'**
  String compareVersionsCount(int count);

  /// No description provided for @compareDifference.
  ///
  /// In es, this message translates to:
  /// **'{percent}% de diferencia'**
  String compareDifference(int percent);

  /// No description provided for @compareCopy.
  ///
  /// In es, this message translates to:
  /// **'Copiar comparación'**
  String get compareCopy;

  /// No description provided for @compareCopied.
  ///
  /// In es, this message translates to:
  /// **'Comparación copiada al portapapeles'**
  String get compareCopied;

  /// No description provided for @compareNoVersions.
  ///
  /// In es, this message translates to:
  /// **'No hay versiones disponibles'**
  String get compareNoVersions;

  /// No description provided for @compareSingleVersion.
  ///
  /// In es, this message translates to:
  /// **'Solo hay una versión disponible; inicia el servicio de catálogo para comparar más.'**
  String get compareSingleVersion;

  /// No description provided for @compareLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el capítulo.'**
  String get compareLoadError;

  /// No description provided for @compareNoChapter.
  ///
  /// In es, this message translates to:
  /// **'La referencia no existe en esta versión.'**
  String get compareNoChapter;

  /// No description provided for @compareInvalidReference.
  ///
  /// In es, this message translates to:
  /// **'Referencia no válida. Prueba, por ejemplo, «Juan 1».'**
  String get compareInvalidReference;

  /// No description provided for @compareVersionUnavailable.
  ///
  /// In es, this message translates to:
  /// **'No disponible en esta versión.'**
  String get compareVersionUnavailable;

  /// No description provided for @compareAddVersions.
  ///
  /// In es, this message translates to:
  /// **'Abrir Biblioteca'**
  String get compareAddVersions;

  /// No description provided for @layoutsSaved.
  ///
  /// In es, this message translates to:
  /// **'Diseños guardados'**
  String get layoutsSaved;

  /// No description provided for @layoutSaveCurrent.
  ///
  /// In es, this message translates to:
  /// **'Guardar el diseño actual…'**
  String get layoutSaveCurrent;

  /// No description provided for @layoutSaveTitle.
  ///
  /// In es, this message translates to:
  /// **'Guardar diseño'**
  String get layoutSaveTitle;

  /// No description provided for @layoutNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre del diseño'**
  String get layoutNameLabel;

  /// No description provided for @layoutNameHint.
  ///
  /// In es, this message translates to:
  /// **'p. ej., Estudio de Juan'**
  String get layoutNameHint;

  /// No description provided for @layoutSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get layoutSave;

  /// No description provided for @layoutSavedToast.
  ///
  /// In es, this message translates to:
  /// **'Diseño guardado'**
  String get layoutSavedToast;

  /// No description provided for @layoutDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar diseño'**
  String get layoutDelete;

  /// No description provided for @layoutDeleteQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar el diseño «{name}»?'**
  String layoutDeleteQuestion(String name);

  /// No description provided for @layoutDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get layoutDeleteConfirm;

  /// No description provided for @layoutNoSaved.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay diseños guardados'**
  String get layoutNoSaved;

  /// No description provided for @layoutAppliedToast.
  ///
  /// In es, this message translates to:
  /// **'Diseño «{name}» aplicado'**
  String layoutAppliedToast(String name);

  /// No description provided for @guidedFindHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar una guía'**
  String get guidedFindHint;

  /// No description provided for @guidedGuides.
  ///
  /// In es, this message translates to:
  /// **'Guías'**
  String get guidedGuides;

  /// No description provided for @guidedWorkflows.
  ///
  /// In es, this message translates to:
  /// **'Flujos de trabajo'**
  String get guidedWorkflows;

  /// No description provided for @guidedNoMatch.
  ///
  /// In es, this message translates to:
  /// **'Ninguna guía coincide con la búsqueda.'**
  String get guidedNoMatch;

  /// No description provided for @guidedParamWord.
  ///
  /// In es, this message translates to:
  /// **'Palabra'**
  String get guidedParamWord;

  /// No description provided for @guidedParamReference.
  ///
  /// In es, this message translates to:
  /// **'Referencia'**
  String get guidedParamReference;

  /// No description provided for @guidedGenerate.
  ///
  /// In es, this message translates to:
  /// **'Generar guía'**
  String get guidedGenerate;

  /// No description provided for @guidedBack.
  ///
  /// In es, this message translates to:
  /// **'Todas las guías'**
  String get guidedBack;

  /// No description provided for @guidedStepDone.
  ///
  /// In es, this message translates to:
  /// **'Marcar el paso'**
  String get guidedStepDone;

  /// No description provided for @guidedActionReader.
  ///
  /// In es, this message translates to:
  /// **'Abrir en el lector'**
  String get guidedActionReader;

  /// No description provided for @guidedActionCompare.
  ///
  /// In es, this message translates to:
  /// **'Comparar versiones'**
  String get guidedActionCompare;

  /// No description provided for @guidedActionFactbook.
  ///
  /// In es, this message translates to:
  /// **'Ver en Temas'**
  String get guidedActionFactbook;

  /// No description provided for @guidedActionSearch.
  ///
  /// In es, this message translates to:
  /// **'Buscar en el catálogo'**
  String get guidedActionSearch;

  /// No description provided for @guidedActionNotes.
  ///
  /// In es, this message translates to:
  /// **'Abrir Notas'**
  String get guidedActionNotes;

  /// No description provided for @guideWordTitle.
  ///
  /// In es, this message translates to:
  /// **'Estudio de palabras bíblicas'**
  String get guideWordTitle;

  /// No description provided for @guideWordDesc.
  ///
  /// In es, this message translates to:
  /// **'Analiza una palabra clave y sus apariciones en el catálogo.'**
  String get guideWordDesc;

  /// No description provided for @guideExegeticalTitle.
  ///
  /// In es, this message translates to:
  /// **'Guía exegética'**
  String get guideExegeticalTitle;

  /// No description provided for @guideExegeticalDesc.
  ///
  /// In es, this message translates to:
  /// **'Contexto, estructura y género del pasaje, paso a paso.'**
  String get guideExegeticalDesc;

  /// No description provided for @guidePassageTitle.
  ///
  /// In es, this message translates to:
  /// **'Guía de pasajes'**
  String get guidePassageTitle;

  /// No description provided for @guidePassageDesc.
  ///
  /// In es, this message translates to:
  /// **'Recorre un pasaje con las herramientas y el catálogo.'**
  String get guidePassageDesc;

  /// No description provided for @guideSermonTitle.
  ///
  /// In es, this message translates to:
  /// **'Guía para sermones'**
  String get guideSermonTitle;

  /// No description provided for @guideSermonDesc.
  ///
  /// In es, this message translates to:
  /// **'Del texto al bosquejo del mensaje.'**
  String get guideSermonDesc;

  /// No description provided for @workflowBasicTitle.
  ///
  /// In es, this message translates to:
  /// **'Estudio bíblico básico'**
  String get workflowBasicTitle;

  /// No description provided for @workflowBasicDesc.
  ///
  /// In es, this message translates to:
  /// **'Cinco pasos clásicos para estudiar un pasaje.'**
  String get workflowBasicDesc;

  /// No description provided for @workflowInductiveTitle.
  ///
  /// In es, this message translates to:
  /// **'Estudio bíblico inductivo'**
  String get workflowInductiveTitle;

  /// No description provided for @workflowInductiveDesc.
  ///
  /// In es, this message translates to:
  /// **'Observación, interpretación y aplicación.'**
  String get workflowInductiveDesc;

  /// No description provided for @workflowLectioTitle.
  ///
  /// In es, this message translates to:
  /// **'Lectio divina'**
  String get workflowLectioTitle;

  /// No description provided for @workflowLectioDesc.
  ///
  /// In es, this message translates to:
  /// **'Lectura orante en cuatro movimientos.'**
  String get workflowLectioDesc;

  /// No description provided for @stepPrayTitle.
  ///
  /// In es, this message translates to:
  /// **'Ora y prepara el corazón'**
  String get stepPrayTitle;

  /// No description provided for @stepPrayDetail.
  ///
  /// In es, this message translates to:
  /// **'Pide al Señor que abra tu entendimiento antes de leer.'**
  String get stepPrayDetail;

  /// No description provided for @stepReadTitle.
  ///
  /// In es, this message translates to:
  /// **'Lee el pasaje completo'**
  String get stepReadTitle;

  /// No description provided for @stepReadDetail.
  ///
  /// In es, this message translates to:
  /// **'Lee {param} dos o tres veces, sin detenerte en los detalles.'**
  String stepReadDetail(String param);

  /// No description provided for @stepContextTitle.
  ///
  /// In es, this message translates to:
  /// **'Estudia el contexto'**
  String get stepContextTitle;

  /// No description provided for @stepContextDetail.
  ///
  /// In es, this message translates to:
  /// **'¿Quién escribe, a quién y por qué? Consulta los temas del pasaje.'**
  String get stepContextDetail;

  /// No description provided for @stepObserveTitle.
  ///
  /// In es, this message translates to:
  /// **'Observa el texto'**
  String get stepObserveTitle;

  /// No description provided for @stepObserveDetail.
  ///
  /// In es, this message translates to:
  /// **'Repeticiones, contrastes, conectores y tiempos verbales.'**
  String get stepObserveDetail;

  /// No description provided for @stepInterpretTitle.
  ///
  /// In es, this message translates to:
  /// **'Interpreta'**
  String get stepInterpretTitle;

  /// No description provided for @stepInterpretDetail.
  ///
  /// In es, this message translates to:
  /// **'¿Qué significaba entonces? ¿Qué dice aquí y ahora?'**
  String get stepInterpretDetail;

  /// No description provided for @stepApplyTitle.
  ///
  /// In es, this message translates to:
  /// **'Aplica'**
  String get stepApplyTitle;

  /// No description provided for @stepApplyDetail.
  ///
  /// In es, this message translates to:
  /// **'¿Qué te pide Dios hoy con este texto? Escríbelo en Notas.'**
  String get stepApplyDetail;

  /// No description provided for @stepNoteTitle.
  ///
  /// In es, this message translates to:
  /// **'Anota tus conclusiones'**
  String get stepNoteTitle;

  /// No description provided for @stepNoteDetail.
  ///
  /// In es, this message translates to:
  /// **'Ancla una nota al versículo y resume lo que descubriste.'**
  String get stepNoteDetail;

  /// No description provided for @stepWordTitle.
  ///
  /// In es, this message translates to:
  /// **'Analiza las palabras clave'**
  String get stepWordTitle;

  /// No description provided for @stepWordDetail.
  ///
  /// In es, this message translates to:
  /// **'Busca «{param}» en el catálogo y compara sus apariciones.'**
  String stepWordDetail(String param);

  /// No description provided for @stepCrossTitle.
  ///
  /// In es, this message translates to:
  /// **'Sigue las referencias cruzadas'**
  String get stepCrossTitle;

  /// No description provided for @stepCrossDetail.
  ///
  /// In es, this message translates to:
  /// **'Abre Ideas ▸ Pasajes relacionados en el lector y sigue las citas.'**
  String get stepCrossDetail;

  /// No description provided for @stepCompareTitle.
  ///
  /// In es, this message translates to:
  /// **'Compara traducciones'**
  String get stepCompareTitle;

  /// No description provided for @stepCompareDetail.
  ///
  /// In es, this message translates to:
  /// **'Compara el pasaje con la otra versión del catálogo.'**
  String get stepCompareDetail;

  /// No description provided for @stepOutlineTitle.
  ///
  /// In es, this message translates to:
  /// **'Bosqueja el mensaje'**
  String get stepOutlineTitle;

  /// No description provided for @stepOutlineDetail.
  ///
  /// In es, this message translates to:
  /// **'Tres puntos con su aplicación, anotados en Notas.'**
  String get stepOutlineDetail;

  /// No description provided for @stepThemeTitle.
  ///
  /// In es, this message translates to:
  /// **'Encuentra el tema central'**
  String get stepThemeTitle;

  /// No description provided for @stepThemeDetail.
  ///
  /// In es, this message translates to:
  /// **'Consulta los temas del pasaje en Temas y elige el eje del mensaje.'**
  String get stepThemeDetail;

  /// No description provided for @stepLectioTitle.
  ///
  /// In es, this message translates to:
  /// **'Lectio: lee despacio'**
  String get stepLectioTitle;

  /// No description provided for @stepLectioDetail.
  ///
  /// In es, this message translates to:
  /// **'Lee {param} en voz alta, saboreando cada frase.'**
  String stepLectioDetail(String param);

  /// No description provided for @stepMeditatioTitle.
  ///
  /// In es, this message translates to:
  /// **'Meditatio: rumia el texto'**
  String get stepMeditatioTitle;

  /// No description provided for @stepMeditatioDetail.
  ///
  /// In es, this message translates to:
  /// **'¿Qué palabra o frase te llama la atención? ¿Por qué?'**
  String get stepMeditatioDetail;

  /// No description provided for @stepOratioTitle.
  ///
  /// In es, this message translates to:
  /// **'Oratio: responde en oración'**
  String get stepOratioTitle;

  /// No description provided for @stepOratioDetail.
  ///
  /// In es, this message translates to:
  /// **'Convierte el texto en tu propia oración.'**
  String get stepOratioDetail;

  /// No description provided for @stepContemplatioTitle.
  ///
  /// In es, this message translates to:
  /// **'Contemplatio: descansa en Dios'**
  String get stepContemplatioTitle;

  /// No description provided for @stepContemplatioDetail.
  ///
  /// In es, this message translates to:
  /// **'Quédate en silencio con lo que Dios te mostró.'**
  String get stepContemplatioDetail;

  /// No description provided for @toolsAtlas.
  ///
  /// In es, this message translates to:
  /// **'Atlas'**
  String get toolsAtlas;

  /// No description provided for @toolsCourses.
  ///
  /// In es, this message translates to:
  /// **'Cursos'**
  String get toolsCourses;

  /// No description provided for @toolsDocuments.
  ///
  /// In es, this message translates to:
  /// **'Documentos'**
  String get toolsDocuments;

  /// No description provided for @toolsInfo.
  ///
  /// In es, this message translates to:
  /// **'Información'**
  String get toolsInfo;

  /// No description provided for @toolsMedia.
  ///
  /// In es, this message translates to:
  /// **'Medios'**
  String get toolsMedia;

  /// No description provided for @toolsPlans.
  ///
  /// In es, this message translates to:
  /// **'Planes de lectura'**
  String get toolsPlans;

  /// No description provided for @toolsSoon.
  ///
  /// In es, this message translates to:
  /// **'Pronto'**
  String get toolsSoon;

  /// No description provided for @panelTitleReadingPlans.
  ///
  /// In es, this message translates to:
  /// **'Planes de lectura'**
  String get panelTitleReadingPlans;

  /// No description provided for @plansIntro.
  ///
  /// In es, this message translates to:
  /// **'Elige un plan para leer la Biblia con un ritmo constante. El progreso se guarda en tu equipo.'**
  String get plansIntro;

  /// No description provided for @plansEmpty.
  ///
  /// In es, this message translates to:
  /// **'No tienes un plan activo. Elige uno para empezar.'**
  String get plansEmpty;

  /// No description provided for @plansAvailable.
  ///
  /// In es, this message translates to:
  /// **'Planes disponibles'**
  String get plansAvailable;

  /// No description provided for @plansOther.
  ///
  /// In es, this message translates to:
  /// **'Otros planes'**
  String get plansOther;

  /// No description provided for @plansInProgress.
  ///
  /// In es, this message translates to:
  /// **'En curso'**
  String get plansInProgress;

  /// No description provided for @plansOpenToday.
  ///
  /// In es, this message translates to:
  /// **'Abrir la lectura de hoy'**
  String get plansOpenToday;

  /// No description provided for @plansMarkRead.
  ///
  /// In es, this message translates to:
  /// **'Marcar día como leído'**
  String get plansMarkRead;

  /// No description provided for @plansStop.
  ///
  /// In es, this message translates to:
  /// **'Detener plan'**
  String get plansStop;

  /// No description provided for @plansDayOf.
  ///
  /// In es, this message translates to:
  /// **'Día {day} de {days}'**
  String plansDayOf(int day, int days);

  /// No description provided for @plansCompleted.
  ///
  /// In es, this message translates to:
  /// **'¡Plan completado! Puedes empezar otro cuando quieras.'**
  String get plansCompleted;

  /// No description provided for @plansToday.
  ///
  /// In es, this message translates to:
  /// **'Lectura de hoy'**
  String get plansToday;

  /// No description provided for @plansDays.
  ///
  /// In es, this message translates to:
  /// **'{days} días'**
  String plansDays(int days);

  /// No description provided for @plansStart.
  ///
  /// In es, this message translates to:
  /// **'Comenzar'**
  String get plansStart;

  /// No description provided for @plansReplaceTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Reemplazar el plan activo?'**
  String get plansReplaceTitle;

  /// No description provided for @plansReplaceBody.
  ///
  /// In es, this message translates to:
  /// **'Ya tienes un plan de lectura en curso. Si empiezas otro, se perderá su progreso.'**
  String get plansReplaceBody;

  /// No description provided for @plansReplace.
  ///
  /// In es, this message translates to:
  /// **'Reemplazar'**
  String get plansReplace;

  /// No description provided for @planBibleYearTitle.
  ///
  /// In es, this message translates to:
  /// **'Biblia en un año'**
  String get planBibleYearTitle;

  /// No description provided for @planBibleYearDesc.
  ///
  /// In es, this message translates to:
  /// **'Todo el canon, unos tres capítulos al día.'**
  String get planBibleYearDesc;

  /// No description provided for @planGospels30Title.
  ///
  /// In es, this message translates to:
  /// **'Evangelios en 30 días'**
  String get planGospels30Title;

  /// No description provided for @planGospels30Desc.
  ///
  /// In es, this message translates to:
  /// **'Mateo, Marcos, Lucas y Juan completos.'**
  String get planGospels30Desc;

  /// No description provided for @planPsalms31Title.
  ///
  /// In es, this message translates to:
  /// **'Salmos y Proverbios en 31 días'**
  String get planPsalms31Title;

  /// No description provided for @planPsalms31Desc.
  ///
  /// In es, this message translates to:
  /// **'Sabiduría diaria durante un mes.'**
  String get planPsalms31Desc;

  /// No description provided for @planNt90Title.
  ///
  /// In es, this message translates to:
  /// **'Nuevo Testamento en 90 días'**
  String get planNt90Title;

  /// No description provided for @planNt90Desc.
  ///
  /// In es, this message translates to:
  /// **'Los 27 libros del Nuevo Testamento.'**
  String get planNt90Desc;

  /// No description provided for @readingPlanView.
  ///
  /// In es, this message translates to:
  /// **'Ver plan de lectura'**
  String get readingPlanView;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Continúa donde lo dejaste y retoma tus herramientas.'**
  String get dashboardSubtitle;

  /// No description provided for @dashboardContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar la lectura'**
  String get dashboardContinue;

  /// No description provided for @dashboardContinueEmpty.
  ///
  /// In es, this message translates to:
  /// **'Abre un pasaje desde la barra lateral o con el buscador para verlo aquí.'**
  String get dashboardContinueEmpty;

  /// No description provided for @dashboardPlan.
  ///
  /// In es, this message translates to:
  /// **'Plan de lectura'**
  String get dashboardPlan;

  /// No description provided for @dashboardPlanEmpty.
  ///
  /// In es, this message translates to:
  /// **'No tienes un plan activo.'**
  String get dashboardPlanEmpty;

  /// No description provided for @dashboardPlanChoose.
  ///
  /// In es, this message translates to:
  /// **'Elegir un plan'**
  String get dashboardPlanChoose;

  /// No description provided for @dashboardPlanView.
  ///
  /// In es, this message translates to:
  /// **'Ver el plan'**
  String get dashboardPlanView;

  /// No description provided for @dashboardNotes.
  ///
  /// In es, this message translates to:
  /// **'Notas'**
  String get dashboardNotes;

  /// No description provided for @dashboardNotesCount.
  ///
  /// In es, this message translates to:
  /// **'{notes, plural, =1{1 nota} other{{notes} notas}} · {highlights, plural, =1{1 resaltado} other{{highlights} resaltados}}'**
  String dashboardNotesCount(int notes, int highlights);

  /// No description provided for @dashboardNotesOpen.
  ///
  /// In es, this message translates to:
  /// **'Abrir Notas'**
  String get dashboardNotesOpen;

  /// No description provided for @dashboardDevotional.
  ///
  /// In es, this message translates to:
  /// **'Devocional de hoy'**
  String get dashboardDevotional;

  /// No description provided for @dashboardDevotionalOpen.
  ///
  /// In es, this message translates to:
  /// **'Abrir el devocional'**
  String get dashboardDevotionalOpen;

  /// No description provided for @dashboardGuided.
  ///
  /// In es, this message translates to:
  /// **'Estudio guiado'**
  String get dashboardGuided;

  /// No description provided for @dashboardGuidedOpen.
  ///
  /// In es, this message translates to:
  /// **'Abrir el estudio guiado'**
  String get dashboardGuidedOpen;

  /// No description provided for @dashboardTools.
  ///
  /// In es, this message translates to:
  /// **'Herramientas'**
  String get dashboardTools;

  /// No description provided for @assistantLead.
  ///
  /// In es, this message translates to:
  /// **'Solo pregunta. Usaré tu biblioteca para responder preguntas como…'**
  String get assistantLead;

  /// No description provided for @assistantPrompt1.
  ///
  /// In es, this message translates to:
  /// **'¿Qué enseña Juan 1 sobre el Verbo?'**
  String get assistantPrompt1;

  /// No description provided for @assistantPrompt2.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo describe el Salmo 23 al pastor?'**
  String get assistantPrompt2;

  /// No description provided for @assistantPrompt3.
  ///
  /// In es, this message translates to:
  /// **'¿Qué dicen los evangelios sobre el perdón?'**
  String get assistantPrompt3;

  /// No description provided for @assistantAiNotice.
  ///
  /// In es, this message translates to:
  /// **'Esta función usa IA. Verifica siempre los resultados.'**
  String get assistantAiNotice;

  /// No description provided for @assistantConnect.
  ///
  /// In es, this message translates to:
  /// **'Conectar un proveedor de IA'**
  String get assistantConnect;

  /// No description provided for @assistantConnectTail.
  ///
  /// In es, this message translates to:
  /// **'para empezar la conversación.'**
  String get assistantConnectTail;

  /// No description provided for @assistantDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Asistente de estudio'**
  String get assistantDialogTitle;

  /// No description provided for @assistantDialogBody.
  ///
  /// In es, this message translates to:
  /// **'El asistente es un plugin opcional: esta instalación no tiene ningún proveedor de IA conectado. Cuando lo conectes, las respuestas llegarán con citas de tu biblioteca. Mientras tanto, el Estudio guiado y las demás herramientas funcionan en local.'**
  String get assistantDialogBody;

  /// No description provided for @assistantDialogOpenGuided.
  ///
  /// In es, this message translates to:
  /// **'Abrir el Estudio guiado'**
  String get assistantDialogOpenGuided;

  /// No description provided for @assistantChatHint.
  ///
  /// In es, this message translates to:
  /// **'Haz una pregunta sobre tu biblioteca: las respuestas llegan con citas que abren el lector.'**
  String get assistantChatHint;

  /// No description provided for @assistantNew.
  ///
  /// In es, this message translates to:
  /// **'Nuevo'**
  String get assistantNew;

  /// No description provided for @assistantRecent.
  ///
  /// In es, this message translates to:
  /// **'Recientes'**
  String get assistantRecent;

  /// No description provided for @assistantRecentEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay preguntas.'**
  String get assistantRecentEmpty;

  /// No description provided for @assistantCopyAll.
  ///
  /// In es, this message translates to:
  /// **'Copiar todo'**
  String get assistantCopyAll;

  /// No description provided for @assistantCopied.
  ///
  /// In es, this message translates to:
  /// **'Conversación copiada.'**
  String get assistantCopied;

  /// No description provided for @assistantScope.
  ///
  /// In es, this message translates to:
  /// **'Alcance'**
  String get assistantScope;

  /// No description provided for @assistantScopeAll.
  ///
  /// In es, this message translates to:
  /// **'Todos los libros'**
  String get assistantScopeAll;

  /// No description provided for @assistantScopeBible.
  ///
  /// In es, this message translates to:
  /// **'La Biblia'**
  String get assistantScopeBible;

  /// No description provided for @assistantInput.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu pregunta…'**
  String get assistantInput;

  /// No description provided for @assistantSend.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get assistantSend;

  /// No description provided for @assistantThinking.
  ///
  /// In es, this message translates to:
  /// **'Pensando…'**
  String get assistantThinking;

  /// No description provided for @assistantYou.
  ///
  /// In es, this message translates to:
  /// **'Tú'**
  String get assistantYou;

  /// No description provided for @assistantAnswerLabel.
  ///
  /// In es, this message translates to:
  /// **'Asistente'**
  String get assistantAnswerLabel;

  /// No description provided for @assistantFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo obtener respuesta del proveedor.'**
  String get assistantFailed;

  /// No description provided for @readerLinkSetNone.
  ///
  /// In es, this message translates to:
  /// **'Sin conjunto'**
  String get readerLinkSetNone;

  /// No description provided for @readerLinkSetHelp.
  ///
  /// In es, this message translates to:
  /// **'Los paneles con la misma letra siguen la misma referencia.'**
  String get readerLinkSetHelp;

  /// No description provided for @storeTitle.
  ///
  /// In es, this message translates to:
  /// **'Tienda de módulos'**
  String get storeTitle;

  /// No description provided for @storeIntro.
  ///
  /// In es, this message translates to:
  /// **'El catálogo desacoplado reparte el contenido en módulos del dominio público y Creative Commons. Elige qué instalar: se descarga con progreso y luego se lee sin depender de la red.'**
  String get storeIntro;

  /// No description provided for @storeCount.
  ///
  /// In es, this message translates to:
  /// **'{count} recursos disponibles'**
  String storeCount(int count);

  /// No description provided for @storeIncluded.
  ///
  /// In es, this message translates to:
  /// **'Incluido'**
  String get storeIncluded;

  /// No description provided for @storeOpen.
  ///
  /// In es, this message translates to:
  /// **'Abrir'**
  String get storeOpen;

  /// No description provided for @storeSearch.
  ///
  /// In es, this message translates to:
  /// **'Buscar recursos'**
  String get storeSearch;

  /// No description provided for @storeAllTypes.
  ///
  /// In es, this message translates to:
  /// **'Todos los tipos'**
  String get storeAllTypes;

  /// No description provided for @storeAllSubjects.
  ///
  /// In es, this message translates to:
  /// **'Todos los temas'**
  String get storeAllSubjects;

  /// No description provided for @storeAllPublishers.
  ///
  /// In es, this message translates to:
  /// **'Todas las editoriales'**
  String get storeAllPublishers;

  /// No description provided for @storeEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay recursos que coincidan.'**
  String get storeEmpty;

  /// No description provided for @storeError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el catálogo local.'**
  String get storeError;

  /// No description provided for @storeRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get storeRetry;

  /// No description provided for @storeOpenLibrary.
  ///
  /// In es, this message translates to:
  /// **'Abrir la Biblioteca'**
  String get storeOpenLibrary;

  /// No description provided for @storeLicense.
  ///
  /// In es, this message translates to:
  /// **'Licencia'**
  String get storeLicense;

  /// No description provided for @panelFullscreenEnter.
  ///
  /// In es, this message translates to:
  /// **'Pantalla completa'**
  String get panelFullscreenEnter;

  /// No description provided for @panelFullscreenExit.
  ///
  /// In es, this message translates to:
  /// **'Salir de pantalla completa'**
  String get panelFullscreenExit;

  /// No description provided for @settingsTheme.
  ///
  /// In es, this message translates to:
  /// **'Tema de la interfaz'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeHelp.
  ///
  /// In es, this message translates to:
  /// **'Claro, oscuro o según el sistema.'**
  String get settingsThemeHelp;

  /// No description provided for @readerOriginal.
  ///
  /// In es, this message translates to:
  /// **'Original'**
  String get readerOriginal;

  /// No description provided for @readerOriginalTooltip.
  ///
  /// In es, this message translates to:
  /// **'Abrir el texto original'**
  String get readerOriginalTooltip;

  /// No description provided for @wordStudyTitle.
  ///
  /// In es, this message translates to:
  /// **'Estudio de la palabra'**
  String get wordStudyTitle;

  /// No description provided for @wordStudyStrong.
  ///
  /// In es, this message translates to:
  /// **'Strong'**
  String get wordStudyStrong;

  /// No description provided for @wordStudyTranslit.
  ///
  /// In es, this message translates to:
  /// **'Transliteración'**
  String get wordStudyTranslit;

  /// No description provided for @wordStudyLemma.
  ///
  /// In es, this message translates to:
  /// **'Lema'**
  String get wordStudyLemma;

  /// No description provided for @wordStudyMorphology.
  ///
  /// In es, this message translates to:
  /// **'Morfología'**
  String get wordStudyMorphology;

  /// No description provided for @wordStudyGloss.
  ///
  /// In es, this message translates to:
  /// **'Glosa'**
  String get wordStudyGloss;

  /// No description provided for @wordStudyGlossSource.
  ///
  /// In es, this message translates to:
  /// **'Glosa de la fuente (inglés)'**
  String get wordStudyGlossSource;

  /// No description provided for @wordStudyOpenLexicon.
  ///
  /// In es, this message translates to:
  /// **'Abrir en el léxico'**
  String get wordStudyOpenLexicon;

  /// No description provided for @wordStudyLexiconTitle.
  ///
  /// In es, this message translates to:
  /// **'Léxico Strong'**
  String get wordStudyLexiconTitle;

  /// No description provided for @wordStudyLexiconError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la entrada del léxico.'**
  String get wordStudyLexiconError;

  /// No description provided for @wordStudyNoLexicon.
  ///
  /// In es, this message translates to:
  /// **'No hay una entrada del léxico para esta palabra.'**
  String get wordStudyNoLexicon;

  /// No description provided for @tabFullscreen.
  ///
  /// In es, this message translates to:
  /// **'Pantalla completa'**
  String get tabFullscreen;

  /// No description provided for @mapTitle.
  ///
  /// In es, this message translates to:
  /// **'Mapa'**
  String get mapTitle;

  /// No description provided for @mapLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el mapa.'**
  String get mapLoadError;

  /// No description provided for @mapAttribution.
  ///
  /// In es, this message translates to:
  /// **'Geometría: Natural Earth (dominio público) · Lugares: OpenBible.info (CC BY 4.0)'**
  String get mapAttribution;

  /// No description provided for @panelTitleAtlas.
  ///
  /// In es, this message translates to:
  /// **'Atlas'**
  String get panelTitleAtlas;

  /// No description provided for @panelTitleCourses.
  ///
  /// In es, this message translates to:
  /// **'Cursos'**
  String get panelTitleCourses;

  /// No description provided for @panelTitleDocuments.
  ///
  /// In es, this message translates to:
  /// **'Documentos'**
  String get panelTitleDocuments;

  /// No description provided for @panelTitleMedia.
  ///
  /// In es, this message translates to:
  /// **'Medios'**
  String get panelTitleMedia;

  /// No description provided for @panelTitleFavorites.
  ///
  /// In es, this message translates to:
  /// **'Favoritos'**
  String get panelTitleFavorites;

  /// No description provided for @panelTitlePsalms.
  ///
  /// In es, this message translates to:
  /// **'Explorador de Salmos'**
  String get panelTitlePsalms;

  /// No description provided for @toolsFavorites.
  ///
  /// In es, this message translates to:
  /// **'Favoritos'**
  String get toolsFavorites;

  /// No description provided for @toolsPsalms.
  ///
  /// In es, this message translates to:
  /// **'Explorador de Salmos'**
  String get toolsPsalms;

  /// No description provided for @atlasIntro.
  ///
  /// In es, this message translates to:
  /// **'Explora los mapas del Factbook y del comentario. Se dibujan sin conexión con la geometría de Natural Earth y las coordenadas de OpenBible.info.'**
  String get atlasIntro;

  /// No description provided for @mediaIntro.
  ///
  /// In es, this message translates to:
  /// **'Galería de contenido visual del catálogo. Cada ficha abre el mapa y la sección original que lo acompaña.'**
  String get mediaIntro;

  /// No description provided for @atlasSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar un mapa o un lugar'**
  String get atlasSearchHint;

  /// No description provided for @mediaSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar en los medios'**
  String get mediaSearchHint;

  /// No description provided for @atlasSourceAll.
  ///
  /// In es, this message translates to:
  /// **'Todas las fuentes'**
  String get atlasSourceAll;

  /// No description provided for @atlasSourceFactbook.
  ///
  /// In es, this message translates to:
  /// **'Factbook'**
  String get atlasSourceFactbook;

  /// No description provided for @atlasSourceCommentary.
  ///
  /// In es, this message translates to:
  /// **'Comentario'**
  String get atlasSourceCommentary;

  /// No description provided for @atlasLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar esta entrada del catálogo.'**
  String get atlasLoadError;

  /// No description provided for @mediaLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los medios.'**
  String get mediaLoadError;

  /// No description provided for @atlasEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay mapas en el catálogo empaquetado.'**
  String get atlasEmpty;

  /// No description provided for @mediaEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay contenido visual en el catálogo empaquetado.'**
  String get mediaEmpty;

  /// No description provided for @atlasAttribution.
  ///
  /// In es, this message translates to:
  /// **'Mapas propios del catálogo de Aletheia. La geometría y las coordenadas conservan su atribución.'**
  String get atlasAttribution;

  /// No description provided for @atlasNoResults.
  ///
  /// In es, this message translates to:
  /// **'Ningún mapa coincide con la búsqueda.'**
  String get atlasNoResults;

  /// No description provided for @atlasCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 entrada} other{{count} entradas}}'**
  String atlasCount(int count);

  /// No description provided for @mediaOpenMap.
  ///
  /// In es, this message translates to:
  /// **'Abrir mapa'**
  String get mediaOpenMap;

  /// No description provided for @atlasOpenResource.
  ///
  /// In es, this message translates to:
  /// **'Abrir la sección'**
  String get atlasOpenResource;

  /// No description provided for @coursesIntro.
  ///
  /// In es, this message translates to:
  /// **'Rutas breves de estudio con lecturas de la RV1909. Elige una y avanza lección a lección.'**
  String get coursesIntro;

  /// No description provided for @coursesSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar un curso'**
  String get coursesSearchHint;

  /// No description provided for @coursesNoResults.
  ///
  /// In es, this message translates to:
  /// **'Ningún curso coincide con la búsqueda.'**
  String get coursesNoResults;

  /// No description provided for @coursesLessons.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 lección} other{{count} lecciones}}'**
  String coursesLessons(int count);

  /// No description provided for @courseCompleted.
  ///
  /// In es, this message translates to:
  /// **'Curso completado. Puedes repasar sus lecturas cuando quieras.'**
  String get courseCompleted;

  /// No description provided for @courseProgress.
  ///
  /// In es, this message translates to:
  /// **'Progreso: {done} de {total}'**
  String courseProgress(int done, int total);

  /// No description provided for @courseLessonRead.
  ///
  /// In es, this message translates to:
  /// **'Leer'**
  String get courseLessonRead;

  /// No description provided for @coursePanoramaTitle.
  ///
  /// In es, this message translates to:
  /// **'Panorama bíblico'**
  String get coursePanoramaTitle;

  /// No description provided for @coursePanoramaDesc.
  ///
  /// In es, this message translates to:
  /// **'Tres paradas para recorrer la historia bíblica: creación, éxodo y monarquía.'**
  String get coursePanoramaDesc;

  /// No description provided for @coursePanoramaLesson1Title.
  ///
  /// In es, this message translates to:
  /// **'La creación y la alianza'**
  String get coursePanoramaLesson1Title;

  /// No description provided for @coursePanoramaLesson1Detail.
  ///
  /// In es, this message translates to:
  /// **'Lee el comienzo de Génesis y observa cómo Dios ordena la creación y llama a la vida.'**
  String get coursePanoramaLesson1Detail;

  /// No description provided for @coursePanoramaLesson2Title.
  ///
  /// In es, this message translates to:
  /// **'Éxodo y liberación'**
  String get coursePanoramaLesson2Title;

  /// No description provided for @coursePanoramaLesson2Detail.
  ///
  /// In es, this message translates to:
  /// **'La zarza ardiente presenta el nombre de Dios y el comienzo de la liberación de Egipto.'**
  String get coursePanoramaLesson2Detail;

  /// No description provided for @coursePanoramaLesson3Title.
  ///
  /// In es, this message translates to:
  /// **'Reyes y profetas'**
  String get coursePanoramaLesson3Title;

  /// No description provided for @coursePanoramaLesson3Detail.
  ///
  /// In es, this message translates to:
  /// **'La elección de David abre una nueva etapa de la historia de Israel.'**
  String get coursePanoramaLesson3Detail;

  /// No description provided for @courseGospelsTitle.
  ///
  /// In es, this message translates to:
  /// **'Los Evangelios'**
  String get courseGospelsTitle;

  /// No description provided for @courseGospelsDesc.
  ///
  /// In es, this message translates to:
  /// **'El anuncio del Reino, la misericordia y la resurrección en tres lecturas.'**
  String get courseGospelsDesc;

  /// No description provided for @courseGospelsLesson1Title.
  ///
  /// In es, this message translates to:
  /// **'El Reino se acerca'**
  String get courseGospelsLesson1Title;

  /// No description provided for @courseGospelsLesson1Detail.
  ///
  /// In es, this message translates to:
  /// **'Jesús proclama el Reino y llama a la conversión en Galilea.'**
  String get courseGospelsLesson1Detail;

  /// No description provided for @courseGospelsLesson2Title.
  ///
  /// In es, this message translates to:
  /// **'Parábolas y misericordia'**
  String get courseGospelsLesson2Title;

  /// No description provided for @courseGospelsLesson2Detail.
  ///
  /// In es, this message translates to:
  /// **'Las parábolas de Lucas 15 muestran el corazón del Padre que busca a los perdidos.'**
  String get courseGospelsLesson2Detail;

  /// No description provided for @courseGospelsLesson3Title.
  ///
  /// In es, this message translates to:
  /// **'Cruz y resurrección'**
  String get courseGospelsLesson3Title;

  /// No description provided for @courseGospelsLesson3Detail.
  ///
  /// In es, this message translates to:
  /// **'La tumba vacía abre el Evangelio de Juan y la misión de la comunidad.'**
  String get courseGospelsLesson3Detail;

  /// No description provided for @coursePrayerTitle.
  ///
  /// In es, this message translates to:
  /// **'Salmos y oración'**
  String get coursePrayerTitle;

  /// No description provided for @coursePrayerDesc.
  ///
  /// In es, this message translates to:
  /// **'Tres salmos para orar con confianza, lamento y alabanza.'**
  String get coursePrayerDesc;

  /// No description provided for @coursePrayerLesson1Title.
  ///
  /// In es, this message translates to:
  /// **'Confianza en el pastor'**
  String get coursePrayerLesson1Title;

  /// No description provided for @coursePrayerLesson1Detail.
  ///
  /// In es, this message translates to:
  /// **'El Salmo 23 acompaña la oración con la imagen del pastor que cuida.'**
  String get coursePrayerLesson1Detail;

  /// No description provided for @coursePrayerLesson2Title.
  ///
  /// In es, this message translates to:
  /// **'El lamento sincero'**
  String get coursePrayerLesson2Title;

  /// No description provided for @coursePrayerLesson2Detail.
  ///
  /// In es, this message translates to:
  /// **'El Salmo 42 enseña a llevar la sed y la tristeza delante de Dios.'**
  String get coursePrayerLesson2Detail;

  /// No description provided for @coursePrayerLesson3Title.
  ///
  /// In es, this message translates to:
  /// **'La alabanza de todo el pueblo'**
  String get coursePrayerLesson3Title;

  /// No description provided for @coursePrayerLesson3Detail.
  ///
  /// In es, this message translates to:
  /// **'El Salmo 100 invita a celebrar la fidelidad de Dios con gratitud.'**
  String get coursePrayerLesson3Detail;

  /// No description provided for @documentsIntro.
  ///
  /// In es, this message translates to:
  /// **'Tres guías breves de estudio propias de Aletheia, pensadas para acompañar la lectura y la consulta del catálogo.'**
  String get documentsIntro;

  /// No description provided for @documentsSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar en los documentos'**
  String get documentsSearchHint;

  /// No description provided for @documentsNoResults.
  ///
  /// In es, this message translates to:
  /// **'Ningún documento coincide con la búsqueda.'**
  String get documentsNoResults;

  /// No description provided for @documentsAttribution.
  ///
  /// In es, this message translates to:
  /// **'Documentos propios de Aletheia; no reproducen obras licenciadas de terceros.'**
  String get documentsAttribution;

  /// No description provided for @documentReadingTitle.
  ///
  /// In es, this message translates to:
  /// **'Cómo leer la Biblia'**
  String get documentReadingTitle;

  /// No description provided for @documentReadingSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Un método sencillo en cuatro pasos: observar, interpretar, aplicar y orar.'**
  String get documentReadingSubtitle;

  /// No description provided for @documentReadingBody.
  ///
  /// In es, this message translates to:
  /// **'## Antes de leer\n\nLa Biblia es una biblioteca de libros escritos en épocas distintas. Antes de buscar una aplicación inmediata, sitúa el pasaje: ¿quién escribe, a quién se dirige y qué problema o promesa aparece en el contexto?\n\n## Observar\n\nLee el texto despacio y anota lo que dice, no lo que esperas que diga. Fíjate en las palabras repetidas, las personas, los lugares, los contrastes y las órdenes. Una buena observación prepara una buena interpretación.\n\n## Interpretar\n\nPregunta qué significaba el pasaje para sus primeros lectores y cómo encaja en la historia bíblica. Compara traducciones y consulta el comentario o el diccionario cuando una palabra o una costumbre no sean claras.\n\n## Aplicar y orar\n\nLa aplicación nace del sentido del texto, no al revés. Termina convirtiendo lo que has visto en una oración: agradece, confiesa, pide ayuda y comprométete a un paso concreto.'**
  String get documentReadingBody;

  /// No description provided for @documentTimelineTitle.
  ///
  /// In es, this message translates to:
  /// **'Cronología bíblica'**
  String get documentTimelineTitle;

  /// No description provided for @documentTimelineSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cuatro etapas para orientarse en la historia del Antiguo y del Nuevo Testamento.'**
  String get documentTimelineSubtitle;

  /// No description provided for @documentTimelineBody.
  ///
  /// In es, this message translates to:
  /// **'## Patriarcas y éxodo\n\nGénesis presenta a Abraham, Isaac y Jacob; Éxodo narra la liberación de Egipto y la alianza del Sinaí. Son relatos de llamada, promesa y formación de un pueblo.\n\n## Monarquía y profetas\n\nSamuel, Saúl y David inauguran la monarquía. Los profetas llaman al pueblo a la fidelidad a la alianza y anuncian juicio y esperanza.\n\n## Exilio y retorno\n\nLa caída de Jerusalén y el exilio en Babilonia marcan una crisis profunda. Esdras y Nehemías relatan la reconstrucción; los salmos y los profetas guardan la memoria de la espera.\n\n## Jesús y la iglesia\n\nLos Evangelios presentan a Jesús como el cumplimiento de las promesas. Hechos y las cartas describen la comunidad que anuncia su muerte y resurrección.'**
  String get documentTimelineBody;

  /// No description provided for @documentGlossaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Glosario de estudio'**
  String get documentGlossaryTitle;

  /// No description provided for @documentGlossarySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cuatro términos que aparecen una y otra vez en la lectura bíblica.'**
  String get documentGlossarySubtitle;

  /// No description provided for @documentGlossaryBody.
  ///
  /// In es, this message translates to:
  /// **'## Alianza\n\nUn vínculo establecido por Dios con su pueblo, con promesas y compromisos. No es un contrato entre iguales: Dios toma la iniciativa y sostiene la relación.\n\n## Gracia\n\nEl favor que Dios concede sin que sea una recompensa merecida. En el Nuevo Testamento es la base de la salvación y de la vida cristiana.\n\n## Justificación\n\nEl acto por el que Dios declara justo al pecador que cree, sobre la base de la obra de Cristo. No es una mejora moral previa, sino una nueva relación con Dios.\n\n## Mesianismo\n\nLa esperanza de un rey o enviado de Dios que restaure a su pueblo. Los Evangelios leen en Jesús el cumplimiento de esa espera, a la vez presente y futura.'**
  String get documentGlossaryBody;

  /// No description provided for @favoritesIntro.
  ///
  /// In es, this message translates to:
  /// **'Guarda pasajes para volver a ellos. También puedes añadir una referencia directamente.'**
  String get favoritesIntro;

  /// No description provided for @favoritesAddHint.
  ///
  /// In es, this message translates to:
  /// **'Referencia: Juan 3:16'**
  String get favoritesAddHint;

  /// No description provided for @favoritesAdd.
  ///
  /// In es, this message translates to:
  /// **'Añadir'**
  String get favoritesAdd;

  /// No description provided for @favoritesInvalidReference.
  ///
  /// In es, this message translates to:
  /// **'No se reconoce esa referencia.'**
  String get favoritesInvalidReference;

  /// No description provided for @favoritesAlreadySaved.
  ///
  /// In es, this message translates to:
  /// **'Ese pasaje ya está en Favoritos.'**
  String get favoritesAlreadySaved;

  /// No description provided for @favoritesPassageSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Pasaje de la RV1909'**
  String get favoritesPassageSubtitle;

  /// No description provided for @favoritesSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar en Favoritos'**
  String get favoritesSearchHint;

  /// No description provided for @favoritesEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tienes favoritos. Usa la estrella del lector o añade una referencia.'**
  String get favoritesEmpty;

  /// No description provided for @favoritesNoResults.
  ///
  /// In es, this message translates to:
  /// **'Ningún favorito coincide con la búsqueda.'**
  String get favoritesNoResults;

  /// No description provided for @favoritesOpen.
  ///
  /// In es, this message translates to:
  /// **'Abrir favorito'**
  String get favoritesOpen;

  /// No description provided for @favoritesRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar de Favoritos'**
  String get favoritesRemove;

  /// No description provided for @favoritesAdded.
  ///
  /// In es, this message translates to:
  /// **'Añadido a Favoritos'**
  String get favoritesAdded;

  /// No description provided for @favoritesRemoved.
  ///
  /// In es, this message translates to:
  /// **'Quitado de Favoritos'**
  String get favoritesRemoved;

  /// No description provided for @psalmsIntro.
  ///
  /// In es, this message translates to:
  /// **'Recorre los 150 salmos por género y abre cualquiera en el lector. Las categorías se solapan.'**
  String get psalmsIntro;

  /// No description provided for @psalmsSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar un salmo o una palabra'**
  String get psalmsSearchHint;

  /// No description provided for @psalmsCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 salmo} other{{count} salmos}}'**
  String psalmsCount(int count);

  /// No description provided for @psalmsAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get psalmsAll;

  /// No description provided for @psalmsNoResults.
  ///
  /// In es, this message translates to:
  /// **'Ningún salmo coincide con la búsqueda.'**
  String get psalmsNoResults;

  /// No description provided for @psalmsAttribution.
  ///
  /// In es, this message translates to:
  /// **'Clasificación propia de Aletheia; el texto bíblico es la RV1909, de dominio público.'**
  String get psalmsAttribution;

  /// No description provided for @psalmOfDay.
  ///
  /// In es, this message translates to:
  /// **'Salmo del día'**
  String get psalmOfDay;

  /// No description provided for @psalmNumber.
  ///
  /// In es, this message translates to:
  /// **'Salmo {number}'**
  String psalmNumber(int number);

  /// No description provided for @psalmsOpen.
  ///
  /// In es, this message translates to:
  /// **'Leer'**
  String get psalmsOpen;

  /// No description provided for @psalmsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Salmo de la RV1909'**
  String get psalmsSubtitle;

  /// No description provided for @psalmCategoryPraise.
  ///
  /// In es, this message translates to:
  /// **'Alabanza'**
  String get psalmCategoryPraise;

  /// No description provided for @psalmCategoryLament.
  ///
  /// In es, this message translates to:
  /// **'Lamento'**
  String get psalmCategoryLament;

  /// No description provided for @psalmCategoryTrust.
  ///
  /// In es, this message translates to:
  /// **'Confianza'**
  String get psalmCategoryTrust;

  /// No description provided for @psalmCategoryThanks.
  ///
  /// In es, this message translates to:
  /// **'Acción de gracias'**
  String get psalmCategoryThanks;

  /// No description provided for @psalmCategoryWisdom.
  ///
  /// In es, this message translates to:
  /// **'Sabiduría'**
  String get psalmCategoryWisdom;

  /// No description provided for @psalmCategoryMessianic.
  ///
  /// In es, this message translates to:
  /// **'Mesiánicos'**
  String get psalmCategoryMessianic;

  /// No description provided for @psalmCategoryPenitential.
  ///
  /// In es, this message translates to:
  /// **'Penitenciales'**
  String get psalmCategoryPenitential;

  /// No description provided for @psalmCategoryPilgrimage.
  ///
  /// In es, this message translates to:
  /// **'Peregrinación'**
  String get psalmCategoryPilgrimage;

  /// No description provided for @moduleInstall.
  ///
  /// In es, this message translates to:
  /// **'Instalar'**
  String get moduleInstall;

  /// No description provided for @moduleCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar instalación'**
  String get moduleCancel;

  /// No description provided for @moduleSize.
  ///
  /// In es, this message translates to:
  /// **'{size}'**
  String moduleSize(String size);

  /// No description provided for @moduleAvailableBody.
  ///
  /// In es, this message translates to:
  /// **'Este recurso vive en el catálogo desacoplado: instálalo para leerlo sin depender de la red después.'**
  String get moduleAvailableBody;

  /// No description provided for @moduleInstallFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la instalación. Revisa la conexión y vuelve a intentarlo.'**
  String get moduleInstallFailed;

  /// No description provided for @moduleDownloading.
  ///
  /// In es, this message translates to:
  /// **'Descargando… {received}'**
  String moduleDownloading(String received);

  /// No description provided for @moduleInstallUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Este recurso se descarga al abrirse; para gestionarlo como módulo usa la app de escritorio.'**
  String get moduleInstallUnavailable;

  /// No description provided for @readerBookNotAvailable.
  ///
  /// In es, this message translates to:
  /// **'{book} no está disponible en {resource}. El catálogo desacoplado trae solo una parte de los libros en cada recurso.'**
  String readerBookNotAvailable(String book, String resource);

  /// No description provided for @readerOpenEquivalent.
  ///
  /// In es, this message translates to:
  /// **'Abrir {book} en {resource}'**
  String readerOpenEquivalent(String book, String resource);

  /// No description provided for @storeInstallButton.
  ///
  /// In es, this message translates to:
  /// **'Instalar'**
  String get storeInstallButton;

  /// No description provided for @storeInstalledBadge.
  ///
  /// In es, this message translates to:
  /// **'Instalado'**
  String get storeInstalledBadge;

  /// No description provided for @storeUpdateBadge.
  ///
  /// In es, this message translates to:
  /// **'Actualización disponible'**
  String get storeUpdateBadge;

  /// No description provided for @storeUninstallButton.
  ///
  /// In es, this message translates to:
  /// **'Desinstalar'**
  String get storeUninstallButton;

  /// No description provided for @storeCancelInstall.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get storeCancelInstall;

  /// No description provided for @storeConfirmUninstall.
  ///
  /// In es, this message translates to:
  /// **'¿Quitar el módulo de este dispositivo? Podrás volver a instalarlo desde aquí.'**
  String get storeConfirmUninstall;

  /// No description provided for @storeRemovedTitle.
  ///
  /// In es, this message translates to:
  /// **'Módulo quitado'**
  String get storeRemovedTitle;

  /// No description provided for @storeUninstalledSnackbar.
  ///
  /// In es, this message translates to:
  /// **'Se quitó {module}.'**
  String storeUninstalledSnackbar(String module);

  /// No description provided for @storeInstallErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'La instalación falló'**
  String get storeInstallErrorTitle;

  /// No description provided for @storeSectionInstalled.
  ///
  /// In es, this message translates to:
  /// **'Instalados'**
  String get storeSectionInstalled;

  /// No description provided for @storeSectionAvailable.
  ///
  /// In es, this message translates to:
  /// **'Disponibles'**
  String get storeSectionAvailable;

  /// No description provided for @storeSearchModuleHint.
  ///
  /// In es, this message translates to:
  /// **'El índice de búsqueda local también es un módulo: sin él la búsqueda funciona con el servicio, no en frío.'**
  String get storeSearchModuleHint;

  /// No description provided for @libraryNotInstalledChip.
  ///
  /// In es, this message translates to:
  /// **'No instalado'**
  String get libraryNotInstalledChip;

  /// No description provided for @libraryInstalledChip.
  ///
  /// In es, this message translates to:
  /// **'Instalado'**
  String get libraryInstalledChip;

  /// No description provided for @dataCareTitle.
  ///
  /// In es, this message translates to:
  /// **'Datos y respaldo'**
  String get dataCareTitle;

  /// No description provided for @backupExport.
  ///
  /// In es, this message translates to:
  /// **'Exportar respaldo…'**
  String get backupExport;

  /// No description provided for @backupExportHelp.
  ///
  /// In es, this message translates to:
  /// **'Guarda tus notas, resaltados, favoritos, planes y diseños en un archivo de respaldo.'**
  String get backupExportHelp;

  /// No description provided for @backupExported.
  ///
  /// In es, this message translates to:
  /// **'Respaldo guardado en {path}'**
  String backupExported(String path);

  /// No description provided for @backupRestore.
  ///
  /// In es, this message translates to:
  /// **'Restaurar respaldo…'**
  String get backupRestore;

  /// No description provided for @backupRestoreHelp.
  ///
  /// In es, this message translates to:
  /// **'Elige un respaldo anterior; se aplicará la próxima vez que abras Aletheia.'**
  String get backupRestoreHelp;

  /// No description provided for @backupRestoreConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Restaurar este respaldo?'**
  String get backupRestoreConfirmTitle;

  /// No description provided for @backupRestoreConfirmBody.
  ///
  /// In es, this message translates to:
  /// **'Se restaurarán tus datos del {date} (respaldo hecho con la versión {version}). Tus datos actuales se guardan antes de reemplazarse.'**
  String backupRestoreConfirmBody(String date, String version);

  /// No description provided for @backupRestoreApply.
  ///
  /// In es, this message translates to:
  /// **'Restaurar y reiniciar'**
  String get backupRestoreApply;

  /// No description provided for @backupStagedRestart.
  ///
  /// In es, this message translates to:
  /// **'Respaldo listo: se aplicará la próxima vez que abras Aletheia.'**
  String get backupStagedRestart;

  /// No description provided for @crashLogExport.
  ///
  /// In es, this message translates to:
  /// **'Exportar registro de fallos…'**
  String get crashLogExport;

  /// No description provided for @crashLogHelp.
  ///
  /// In es, this message translates to:
  /// **'Registro local de errores, sin telemetría; sirve para reportar problemas.'**
  String get crashLogHelp;

  /// No description provided for @crashLogEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay registro de fallos.'**
  String get crashLogEmpty;

  /// No description provided for @crashLogExported.
  ///
  /// In es, this message translates to:
  /// **'Registro guardado en {path}'**
  String crashLogExported(String path);

  /// No description provided for @crashLogClear.
  ///
  /// In es, this message translates to:
  /// **'Borrar registro de fallos'**
  String get crashLogClear;

  /// No description provided for @crashLogCleared.
  ///
  /// In es, this message translates to:
  /// **'Registro borrado.'**
  String get crashLogCleared;

  /// No description provided for @updateCheck.
  ///
  /// In es, this message translates to:
  /// **'Buscar actualizaciones'**
  String get updateCheck;

  /// No description provided for @updateCheckHelp.
  ///
  /// In es, this message translates to:
  /// **'Compara tu versión con la última publicada en GitHub. Sin telemetría.'**
  String get updateCheckHelp;

  /// No description provided for @updateNone.
  ///
  /// In es, this message translates to:
  /// **'Estás usando la última versión.'**
  String get updateNone;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In es, this message translates to:
  /// **'Hay una versión nueva: {version}'**
  String updateAvailableTitle(String version);

  /// No description provided for @updateAvailableBody.
  ///
  /// In es, this message translates to:
  /// **'Puedes descargar el binario para tu plataforma desde la página de releases de GitHub.'**
  String get updateAvailableBody;

  /// No description provided for @updateOpenReleases.
  ///
  /// In es, this message translates to:
  /// **'Abrir releases'**
  String get updateOpenReleases;

  /// No description provided for @aboutVersion.
  ///
  /// In es, this message translates to:
  /// **'Aletheia {version}'**
  String aboutVersion(String version);

  /// No description provided for @exportPassage.
  ///
  /// In es, this message translates to:
  /// **'Exportar pasaje…'**
  String get exportPassage;

  /// No description provided for @exportNote.
  ///
  /// In es, this message translates to:
  /// **'Exportar nota…'**
  String get exportNote;

  /// No description provided for @exportFormat.
  ///
  /// In es, this message translates to:
  /// **'Formato'**
  String get exportFormat;

  /// No description provided for @exportFormatMarkdown.
  ///
  /// In es, this message translates to:
  /// **'Markdown'**
  String get exportFormatMarkdown;

  /// No description provided for @exportFormatHtml.
  ///
  /// In es, this message translates to:
  /// **'HTML'**
  String get exportFormatHtml;

  /// No description provided for @exportFormatPlain.
  ///
  /// In es, this message translates to:
  /// **'Texto plano'**
  String get exportFormatPlain;

  /// No description provided for @exportCopy.
  ///
  /// In es, this message translates to:
  /// **'Copiar al portapapeles'**
  String get exportCopy;

  /// No description provided for @exportSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar archivo…'**
  String get exportSave;

  /// No description provided for @exportPrint.
  ///
  /// In es, this message translates to:
  /// **'Imprimir…'**
  String get exportPrint;

  /// No description provided for @exportPrintHelp.
  ///
  /// In es, this message translates to:
  /// **'Abre el pasaje en tu navegador con el diálogo de impresión.'**
  String get exportPrintHelp;

  /// No description provided for @exportSaved.
  ///
  /// In es, this message translates to:
  /// **'Archivo guardado en {path}'**
  String exportSaved(String path);

  /// No description provided for @exportCopied.
  ///
  /// In es, this message translates to:
  /// **'Exportación copiada al portapapeles'**
  String get exportCopied;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
