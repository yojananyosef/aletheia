// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Aletheia';

  @override
  String get retry => 'Try again';

  @override
  String get close => 'Close';

  @override
  String get cancel => 'Cancel';

  @override
  String get bannerDev => 'Aletheia · public-domain Bible catalog';

  @override
  String get bannerOpenLibrary => 'Open Library';

  @override
  String get bannerClose => 'Close banner';

  @override
  String get navHome => 'Home';

  @override
  String get navLibrary => 'Library';

  @override
  String get navSearch => 'Search';

  @override
  String get navBible => 'Bible';

  @override
  String get navAssistant => 'Study Assistant';

  @override
  String get navTopics => 'Topics';

  @override
  String get navGuidedStudy => 'Guided Study';

  @override
  String get navNotes => 'Notes';

  @override
  String get navTools => 'Tools';

  @override
  String get navQuickActions => 'Quick actions';

  @override
  String get navStore => 'Store';

  @override
  String get navLayouts => 'Layouts';

  @override
  String get navCloseAllTabs => 'Close all tabs';

  @override
  String get quickOpenCommentary => 'Open a commentary';

  @override
  String get quickOpenStudyBible => 'Open a study Bible';

  @override
  String get quickCompareBibles => 'Compare Bible versions';

  @override
  String get quickOpenDictionary => 'Open a Bible dictionary';

  @override
  String get quickOpenDevotional => 'Open today\'s devotional';

  @override
  String get moreOptions => 'More options';

  @override
  String get menuSettings => 'Settings';

  @override
  String get menuResourceCatalog => 'Resource catalog';

  @override
  String get menuOriginalStore => 'Original app store (not applicable)';

  @override
  String get menuDownloadApp => 'Download the original app (not applicable)';

  @override
  String get sidebarExpand => 'Expand sidebar';

  @override
  String get sidebarCollapse => 'Collapse sidebar';

  @override
  String get layoutOne => 'One column';

  @override
  String get layoutTwo => 'Two columns';

  @override
  String get layoutTwoRows => 'Two rows';

  @override
  String get layoutThree => 'Three columns';

  @override
  String get layoutFour => '2×2 grid';

  @override
  String get omniboxHint => 'Passage or topic';

  @override
  String omniboxGoto(String reference) {
    return 'Go to $reference';
  }

  @override
  String omniboxSearch(String query) {
    return 'Search “$query”';
  }

  @override
  String get workspaceEmptyTile => 'No tabs — open something from the sidebar';

  @override
  String get panelCommands => 'Panel commands';

  @override
  String get tabClose => 'Close tab';

  @override
  String get tabDuplicate => 'Duplicate this tab';

  @override
  String get tabCloseThis => 'Close this tab';

  @override
  String get tabCloseToRight => 'Close tabs to the right';

  @override
  String get tabCloseOthers => 'Close other tabs';

  @override
  String get tabCloseAll => 'Close all tabs';

  @override
  String get panelTitleDashboard => 'Home';

  @override
  String get panelTitleLibrary => 'Library';

  @override
  String get panelTitleStore => 'Store';

  @override
  String get panelTitleSearch => 'Search';

  @override
  String get panelTitleResource => 'Resource';

  @override
  String get panelTitleBible => 'Bible';

  @override
  String get panelTitleStudyAssistant => 'Study Assistant';

  @override
  String get panelTitleFactbook => 'Topics';

  @override
  String get panelTitleGuidedStudy => 'Guided Study';

  @override
  String get panelTitleNotes => 'Notes';

  @override
  String get panelTitleTools => 'Tools';

  @override
  String get panelTitleTextComparison => 'Text Comparison';

  @override
  String get panelTitleDevotional => 'Devotional of the day';

  @override
  String get panelTitleSettings => 'Settings';

  @override
  String get placeholderDashboard =>
      'Workspace status and configurable banners (M3).';

  @override
  String get placeholderLibrary =>
      'The Library opens from the sidebar as a floating panel (M2): search, facets and resource details.';

  @override
  String get placeholderStore =>
      'Browsable public-domain resource catalog (M5). No purchases: owned resources are marked as available.';

  @override
  String get placeholderResource =>
      'Non-Bible resource reader (M5): commentaries, dictionaries and books from the catalog.';

  @override
  String get placeholderStudyAssistant =>
      'Study Assistant (optional AI plugin, M6): chat with citations to resources, attachments and scope selection.';

  @override
  String get placeholderFactbook =>
      'Topics (M5): articles by topic or reference with sections and related topics.';

  @override
  String get placeholderGuidedStudy =>
      'Guided Study (M6): guides (word study, exegesis, passage, sermon outline) and guided workflows.';

  @override
  String get placeholderTools =>
      'Tools hub (M5): Atlas, Documents, Favorites, Information, Media, Psalms Explorer, Reading Plan Manager, Text Comparison.';

  @override
  String get placeholderTextComparison =>
      'Text Comparison (M5): reference + set of versions in verse-synchronized columns.';

  @override
  String get placeholderDevotional =>
      'Devotional (M5): resources with a calendar (MM-DD), morning/evening navigation.';

  @override
  String get placeholderFallback => 'Pending in upcoming milestones.';

  @override
  String get readerBack => 'Back';

  @override
  String get readerForward => 'Forward';

  @override
  String get readerChangeBook => 'Change book';

  @override
  String get readerModeHome => 'Home';

  @override
  String get readerModeSearch => 'Search';

  @override
  String get readerModeNotes => 'Notes';

  @override
  String get readerModeFormat => 'Formatting';

  @override
  String get readerModeView => 'View';

  @override
  String get readerModeMore => 'More';

  @override
  String get readerSearchInResource => 'Search this resource';

  @override
  String get readerToolsSoon => 'Tools — M6';

  @override
  String get readerCopyReference => 'Copy reference';

  @override
  String get readerCopyCitation => 'Copy citation';

  @override
  String get readerCopyPassageAndCitation => 'Copy passage and citation';

  @override
  String get readerCopied => 'Copied to clipboard';

  @override
  String get readerContents => 'Contents';

  @override
  String get readerContentsTooltip => 'Contents';

  @override
  String get readerArticle => 'Article';

  @override
  String get readerArticleStepTo => 'Step to article';

  @override
  String get readerArticlePrevious => 'Previous article';

  @override
  String get readerArticleNext => 'Next article';

  @override
  String get readerPrevChapter => 'Previous chapter';

  @override
  String get readerNextChapter => 'Next chapter';

  @override
  String get readerLinkSet => 'Link set';

  @override
  String get readerLinkSetSoon => 'Link set — M6';

  @override
  String get readerInsights => 'Insights';

  @override
  String get readerInfo => 'Info';

  @override
  String get insightsTitle => 'Insights';

  @override
  String get insightsClose => 'Close panel';

  @override
  String get insightsBookInfoTab => 'Book info';

  @override
  String insightsAbout(String title) {
    return 'About $title';
  }

  @override
  String get insightsAuthor => 'Author';

  @override
  String get insightsPublisher => 'Publisher';

  @override
  String get insightsEdition => 'Edition';

  @override
  String get insightsLanguage => 'Language';

  @override
  String get insightsType => 'Type';

  @override
  String get insightsStats => 'Stats';

  @override
  String insightsVerseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verses',
      one: '1 verse',
    );
    return '$_temp0';
  }

  @override
  String insightsSectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sections',
      one: '1 section',
    );
    return '$_temp0';
  }

  @override
  String get insightsAuxId => 'Identifier';

  @override
  String get insightsAuxType => 'Type';

  @override
  String get insightsAuxSource => 'Source';

  @override
  String get insightsAuxiliary => 'Auxiliary info';

  @override
  String get insightsBookInfoUnavailable => 'No resource info available.';

  @override
  String get insightsCopyright => 'Copyright';

  @override
  String get insightsLicenseUnknown => 'License not specified.';

  @override
  String get insightsRelatedBooks => 'Related books';

  @override
  String get insightsNoBooks => 'No catalog resource cites this reference.';

  @override
  String get insightsRelatedPassages => 'Related passages';

  @override
  String get insightsCrossReferences => 'Cross references';

  @override
  String get insightsNoPassages =>
      'No related passages in the current catalog.';

  @override
  String get insightsRelatedError => 'Related content could not be loaded.';

  @override
  String get insightsMore => 'More »';

  @override
  String get readingPlanStart => 'Start reading plan';

  @override
  String get readerHideLocationBar => 'Hide the locator bar';

  @override
  String get readerShowLocationBar => 'Show the locator bar';

  @override
  String get readerHideSecondaryToolbar => 'Hide the secondary toolbar';

  @override
  String get readerShowSecondaryToolbar => 'Show the secondary toolbar';

  @override
  String get readerHistory => 'History';

  @override
  String get readerHistoryPanel => 'Panel history';

  @override
  String get readerHistoryEmpty => 'No history yet';

  @override
  String get readerLoadMoreChapters => 'Load more chapters';

  @override
  String get readerEnd => '— End —';

  @override
  String readerFootnote(String label) {
    return 'Note $label';
  }

  @override
  String get readerFootnoteUnavailable => 'Footnote not available.';

  @override
  String readerFootnoteA11y(String label, String text) {
    return 'Footnote $label: $text';
  }

  @override
  String get readerFootnoteOpenHint => 'Open the footnote';

  @override
  String get readerXrefOpenHint => 'Go to the cross-reference';

  @override
  String readerInvalidReference(String reference) {
    return 'Invalid reference: $reference';
  }

  @override
  String readerSectionMissing(String book, int chapter) {
    return 'Could not find $book $chapter in the document.';
  }

  @override
  String readerLoadError(String error) {
    return 'Could not load the document: $error';
  }

  @override
  String get readerFootnoteList => 'Footnotes';

  @override
  String get contentsTitle => 'Contents';

  @override
  String get contentsFilter => 'Filter books';

  @override
  String get contentsSearch => 'Search contents';

  @override
  String get contentsClose => 'Close contents';

  @override
  String contentsChapter(int number) {
    return 'Chapter $number';
  }

  @override
  String get changeBookTitle => 'Change book';

  @override
  String changeBookLoadError(String error) {
    return 'Could not load Bibles.\n$error';
  }

  @override
  String get changeBookEmpty => 'No results';

  @override
  String panelSearchTitle(String resource) {
    return 'Search in “$resource”';
  }

  @override
  String get panelSearchSyntax =>
      'Within this resource · words, \"phrases\", AND/OR/NOT, WITHIN n WORDS';

  @override
  String get searchFailed => 'Search failed';

  @override
  String get panelSearchPrompt =>
      'Type a query to search the whole resource. Each result takes you to the exact verse.';

  @override
  String searchNoResults(String query) {
    return 'No results for “$query”';
  }

  @override
  String get searchTryFewerWords => 'Try fewer words';

  @override
  String get searchTryFewerOrScope => 'Try fewer words or another scope';

  @override
  String searchResultsCountFor(int count, String query) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
    );
    return '$_temp0 for “$query”';
  }

  @override
  String searchLoadMoreRemaining(int count) {
    return 'Load more ($count remaining)';
  }

  @override
  String searchScope(String scope) {
    return 'Scope: $scope';
  }

  @override
  String get searchSyntaxTitle => 'Search syntax';

  @override
  String get searchSyntaxWord => 'a word';

  @override
  String get searchSyntaxPhrase => '\"in the beginning\"';

  @override
  String get searchSyntaxPhraseNote => 'exact phrase';

  @override
  String get searchSyntaxAnd => 'God AND beginning';

  @override
  String get searchSyntaxAndNote => 'both words (also OR and NOT)';

  @override
  String get searchSyntaxWithin => 'beginning WITHIN 5 WORDS God';

  @override
  String get searchSyntaxWithinNote => 'within 5 words of each other';

  @override
  String get searchSyntaxBeforeNote => 'one term appears before the other';

  @override
  String get searchSyntaxNearNote => 'within 10 words (NEAR/5 for 5)';

  @override
  String get searchSyntaxFieldNote =>
      'passage and filters: bible:, type:, language:, book:';

  @override
  String get searchSyntaxNote =>
      'Search is case- and accent-insensitive. Combine syntax with type, language and book filters; results are grouped by resource.';

  @override
  String get searchMorphologyTitle => 'Morphology';

  @override
  String get searchKeyboardTitle => 'Greek and Hebrew keyboard';

  @override
  String get searchKeyboardGreek => 'Greek';

  @override
  String get searchKeyboardHebrew => 'Hebrew';

  @override
  String get searchKeyboardHint => 'Tap a letter to insert it into the search.';

  @override
  String get searchKeyboardBackspace => 'Delete a letter';

  @override
  String get searchFilterType => 'Type';

  @override
  String get searchFilterLanguage => 'Language';

  @override
  String get searchFilterBook => 'Book';

  @override
  String get searchFilterAll => 'All';

  @override
  String get searchFilterAllBooks => 'All books';

  @override
  String get searchFilterClear => 'Clear filters';

  @override
  String get searchBack => 'Back';

  @override
  String get searchTitle => 'Search the Bible and books';

  @override
  String get searchHistory => 'Search history';

  @override
  String get searchHistoryEmpty => 'No searches yet';

  @override
  String get searchPromptTitle => 'Search the catalog';

  @override
  String get searchPromptBody =>
      'Words, quoted phrases, AND/OR/NOT, NEAR, WITHIN n WORDS and fields such as bible:\"Jn 3\". Each result opens the resource at the exact passage.';

  @override
  String get searchIndexUnavailable =>
      'Search couldn\'t open the bundled index. Reinstall the app or rebuild the catalog.';

  @override
  String get searchDownloadTitle => 'First search: downloading the index';

  @override
  String searchDownloadBody(String size) {
    return 'The index is $size. It will be cached in your browser for future searches.';
  }

  @override
  String searchDownloadProgress(String received, String total) {
    return '$received of $total';
  }

  @override
  String searchDownloadUnknown(String received) {
    return '$received downloaded';
  }

  @override
  String get searchDownloadCancel => 'Cancel';

  @override
  String get searchDownloadCancelled =>
      'Download cancelled. The next search will try again.';

  @override
  String get scopeAll => 'All';

  @override
  String get scopeBible => 'Bible';

  @override
  String get scopeBooks => 'Books';

  @override
  String get scopeFactbook => 'Topics';

  @override
  String get scopeMorph => 'Morphology';

  @override
  String get scopeMedia => 'Media';

  @override
  String get scopeMaps => 'Maps';

  @override
  String get scopeTodoNote => 'M5';

  @override
  String get scopeMorphNote => 'M6';

  @override
  String get fmtMarkers => 'Markers';

  @override
  String get fmtReformat => 'Reformat';

  @override
  String get fmtTypography => 'Typeface';

  @override
  String get fontSerif => 'Serif';

  @override
  String get fontSans => 'Sans';

  @override
  String get fontMono => 'Mono';

  @override
  String get fmtReformatTitle => 'Reformat text';

  @override
  String get fmtMarkersTitle => 'Show markers';

  @override
  String get fmtBibleText => 'Bible text';

  @override
  String get fmtBibleTextFormatting => 'Bible text formatting';

  @override
  String get fmtNumbers => 'Chapter/Verse numbers';

  @override
  String get fmtFootnoteIndicators => 'Footnote indicators';

  @override
  String get fmtNonBibleText => 'Non-Bible text';

  @override
  String get fmtOneVersePerLine => 'One verse per line';

  @override
  String get fmtCorrespondingWords => 'Corresponding Words';

  @override
  String get fmtSameSurfaceText => 'Same surface text';

  @override
  String get fmtNote => 'Reformat the main body of the book.';

  @override
  String get fmtMarkersNote =>
      'Adds markers to show hidden data in the book. With Markers on, only the indicators and highlights of the checked notebooks and tags are shown.';

  @override
  String get fmtSermons => 'Sermons';

  @override
  String get fmtBibleStudies => 'Bible Studies';

  @override
  String get fmtMarkersNotebooks => 'Notebooks';

  @override
  String get fmtMarkersTags => 'Tags';

  @override
  String get fmtMarkersEmpty =>
      'No notebooks or tags yet. Create a note with a notebook or tag to filter markers.';

  @override
  String get viewPagedView => 'Paged view';

  @override
  String get viewPagedTitle => 'Paged view';

  @override
  String get viewColumns => 'Columns';

  @override
  String get viewColumnsAuto => 'Auto';

  @override
  String get viewFootnotesOnPage => 'Show footnotes on page';

  @override
  String get viewLocatorBar => 'Locator bar';

  @override
  String get viewZoom => 'Zoom';

  @override
  String get viewFullScreen => 'Full screen';

  @override
  String get viewExitFullScreen => 'Exit full screen';

  @override
  String viewPageOf(int page, int total) {
    return 'Page $page of $total';
  }

  @override
  String get viewPrevPage => 'Previous page';

  @override
  String get viewNextPage => 'Next page';

  @override
  String get viewZoomReset => 'Reset zoom to 100%';

  @override
  String get settingsReset => 'Reset defaults';

  @override
  String get settingsResetDone => 'Defaults restored';

  @override
  String get settingsCatalog => 'Catalog';

  @override
  String get settingsServiceUrl => 'Service address';

  @override
  String get settingsApply => 'Apply';

  @override
  String get settingsCatalogModeAuto => 'Automatic';

  @override
  String get settingsCatalogModeLocal => 'Bundled only';

  @override
  String get settingsCatalogModeRemote => 'Service only';

  @override
  String get settingsChecking => 'Checking the service…';

  @override
  String get settingsOffline =>
      'Offline — the resources bundled with the app are used.';

  @override
  String settingsOfflineError(String error) {
    return 'Offline: $error';
  }

  @override
  String settingsOnline(int resources, String verses, String sections) {
    return 'Connected: $resources resources, $verses verses and $sections indexed entries.';
  }

  @override
  String settingsLocalReady(int resources, String verses, String sections) {
    return 'Local mode: $resources resources, $verses verses and $sections indexed entries.';
  }

  @override
  String get settingsRecheck => 'Check again';

  @override
  String get settingsQuickActions => 'Show quick actions';

  @override
  String get settingsBannersDashboard => 'Show banners in Dashboard';

  @override
  String get settingsBannersLayout => 'Show banners in Layouts';

  @override
  String get settingsToolbarLocation => 'Application toolbar location';

  @override
  String get settingsToolbarLeft => 'Left';

  @override
  String get settingsToolbarTop => 'Top';

  @override
  String get settingsLanguage => 'Interface language';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsCitationStyle => 'Citation style';

  @override
  String get citationTurabian => 'Turabian (9th ed., full note)';

  @override
  String get citationSbl => 'SBL (2nd ed.)';

  @override
  String get citationChicago => 'Chicago (17th ed.)';

  @override
  String get citationPlain => 'Aletheia (plain)';

  @override
  String get settingsCopyCitations => 'Copy citation with text';

  @override
  String get settingsHyperlinkCitations => 'Hyperlink copied citations';

  @override
  String get settingsLimitedView => 'Enable limited view mode';

  @override
  String get settingsLimitedViewHelp =>
      'Accessible view: no pagination and footnotes listed at the end of each chapter.';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get help => 'Help';

  @override
  String get libraryFacets => 'Facets';

  @override
  String get libraryFind => 'Find';

  @override
  String get libraryClear => 'Clear';

  @override
  String libraryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resources',
      one: '1 resource',
    );
    return '$_temp0';
  }

  @override
  String get libraryTabLibrary => 'Library';

  @override
  String get libraryTabStore => 'Store';

  @override
  String get libraryStoreSoon => 'M5: store catalog';

  @override
  String get librarySort => 'Sort';

  @override
  String get librarySortTitle => 'by Title';

  @override
  String get librarySortAuthor => 'by Author';

  @override
  String get librarySortDate => 'by Date';

  @override
  String get libraryClearFilters => 'Clear filters';

  @override
  String get libraryFacetType => 'Type';

  @override
  String get libraryFacetLanguage => 'Language';

  @override
  String get libraryFacetAuthor => 'Author';

  @override
  String get libraryFacetSubject => 'Subject';

  @override
  String get libraryFacetPublisher => 'Publisher';

  @override
  String get libraryLoadMore => 'Load more';

  @override
  String get libraryErrorTitle => 'Could not reach the catalog';

  @override
  String get libraryEmpty => 'No resources match the filter';

  @override
  String get libraryBack => 'Back to list';

  @override
  String get libraryOpen => 'Open';

  @override
  String get libraryMore => 'More »';

  @override
  String get libraryLess => 'Less «';

  @override
  String libraryStats(String verses, String chapters) {
    return '$verses verses · $chapters chapters';
  }

  @override
  String get libraryLoading => 'Loading…';

  @override
  String get languageEs => 'Spanish';

  @override
  String get languageEn => 'English';

  @override
  String get languageEl => 'Greek';

  @override
  String get languageHe => 'Hebrew';

  @override
  String get languageLa => 'Latin';

  @override
  String get typeBible => 'Bible';

  @override
  String get typeCommentary => 'Commentary';

  @override
  String get typeDictionary => 'Dictionary';

  @override
  String get typeEncyclopedia => 'Encyclopedia';

  @override
  String get typeDevotional => 'Devotional';

  @override
  String get typeDataset => 'Dataset';

  @override
  String get typeGuide => 'Guide';

  @override
  String get typeWorkflow => 'Workflow';

  @override
  String get typeDocument => 'Document';

  @override
  String get settingsCitationHelp =>
      'Turabian (9th ed., full note) · SBL (2nd ed.) · Chicago (17th ed.) · Aletheia (plain)';

  @override
  String get resourceTitleCommentary => 'Commentary';

  @override
  String get resourceTitleStudyBible => 'Study Bible';

  @override
  String get resourceTitleDictionary => 'Bible dictionary';

  @override
  String get resourceLabelMatthewHenry => 'Matthew Henry (concise)';

  @override
  String get resourceLabelTsk => 'Treasury of Scripture Knowledge';

  @override
  String get settingsBannersDashboardHelp =>
      'What’s-new banner inside the Dashboard panel.';

  @override
  String get settingsBannersLayoutHelp => 'The layout banners (top bar).';

  @override
  String get settingsCopyHelp => 'Copying a passage adds its citation.';

  @override
  String get settingsHyperlinkHelp =>
      'Copied citations link to the passage (“ref:CANON”).';

  @override
  String get notesFind => 'Find';

  @override
  String get notesFindHint => 'Find in notes';

  @override
  String get notesShare => 'Share';

  @override
  String get notesNewNote => 'New note';

  @override
  String get notesAll => 'All';

  @override
  String notesResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String get notesFilters => 'Filters';

  @override
  String get notesSidebarToggle => 'Filters and notebooks';

  @override
  String get notesNotebooks => 'Notebooks';

  @override
  String get notesTrash => 'Trash';

  @override
  String get notesByModified => 'Modification date';

  @override
  String get notesByCreated => 'Creation date';

  @override
  String notesSortBy(String label) {
    return 'by $label';
  }

  @override
  String get notesByNotebook => 'Notebook';

  @override
  String get notesSortNotebookHint =>
      'Select a notebook to enable notebook order';

  @override
  String get notesDensity => 'Density';

  @override
  String get notesDensityDefault => 'Default';

  @override
  String get notesDensityCompact => 'Compact';

  @override
  String notesNewNoteInRef(String reference) {
    return 'New note in $reference';
  }

  @override
  String get notesByTitle => 'by Title';

  @override
  String get notesEmpty => 'No notes yet';

  @override
  String get notesEmptyHint =>
      'Create a note with “New note” or by selecting text in the reader.';

  @override
  String get notesTrashEmpty => 'Trash is empty';

  @override
  String get notesTrashHint =>
      'You can restore notes or delete them permanently.';

  @override
  String get notesFilterKind => 'Type';

  @override
  String get notesFilterKindNote => 'Notes';

  @override
  String get notesFilterKindHighlight => 'Highlights';

  @override
  String get notesFilterNotebook => 'Notebook';

  @override
  String get notesFilterTag => 'Tag';

  @override
  String get notesFilterResource => 'Resource';

  @override
  String get notesFiltersClear => 'Clear filters';

  @override
  String notesFiltersActive(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filters',
      one: '1 filter',
    );
    return '$_temp0';
  }

  @override
  String get notesNewNotebook => 'New notebook';

  @override
  String get notesNotebookName => 'Notebook name';

  @override
  String get notesNotebookCreate => 'Create notebook';

  @override
  String notesNotebookDeleteTitle(Object name) {
    return 'Delete the notebook “$name”?';
  }

  @override
  String get notesNotebookDeleteBody =>
      'Notes are not deleted: they are only removed from the notebook.';

  @override
  String get notesNotebookEmpty => 'No notebooks yet';

  @override
  String notesNotebookNotes(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return '$_temp0';
  }

  @override
  String get notesRename => 'Rename';

  @override
  String get notesRestore => 'Restore';

  @override
  String get notesPurge => 'Delete permanently';

  @override
  String get notesEmptyTrashAction => 'Empty trash';

  @override
  String get notesDuplicate => 'Duplicate';

  @override
  String get notesEdit => 'Edit';

  @override
  String get notesOpen => 'Open';

  @override
  String get notesClose => 'Close note';

  @override
  String get notesShowInReader => 'Show in reader';

  @override
  String get notesNoAnchor => 'No anchor';

  @override
  String notesAnchoredAt(Object reference) {
    return 'Anchored at $reference';
  }

  @override
  String notesItemCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return '$_temp0';
  }

  @override
  String notesTrashCount(Object count) {
    return 'in trash: $count';
  }

  @override
  String get noteTitleHint => 'Note title';

  @override
  String get noteBodyHint => 'Write a note…';

  @override
  String get noteQuoteLabel => 'Quote';

  @override
  String get noteQuoteRemove => 'Remove quote';

  @override
  String get noteFormatBold => 'Bold';

  @override
  String get noteFormatItalic => 'Italic';

  @override
  String get noteFormatUnderline => 'Underline';

  @override
  String get noteFormatHighlight => 'Highlight';

  @override
  String get noteFormatBullets => 'Bulleted list';

  @override
  String get noteFormatNumbered => 'Numbered list';

  @override
  String get noteFormatQuote => 'Block quote';

  @override
  String get noteFormatReference => 'Insert reference';

  @override
  String get noteNotebooksLabel => 'Notebooks';

  @override
  String get noteNotebookAdd => 'Add to notebook';

  @override
  String get noteTagsLabel => 'Tags';

  @override
  String get noteTagAdd => 'Add tag';

  @override
  String get noteTagHint => 'New tag';

  @override
  String get noteAnchorLabel => 'Anchor';

  @override
  String get noteAnchorChange => 'Change anchor';

  @override
  String get noteSaved => 'Saved';

  @override
  String noteCreatedOn(Object date) {
    return 'Created on $date';
  }

  @override
  String noteModifiedOn(Object date) {
    return 'Modified on $date';
  }

  @override
  String noteDeletedOn(Object date) {
    return 'Deleted on $date';
  }

  @override
  String get noteShareCopied => 'Note copied to clipboard';

  @override
  String get noteShareMarkdown => 'Copy as Markdown';

  @override
  String get noteShareText => 'Copy as text';

  @override
  String get noteKindNote => 'Note';

  @override
  String get noteKindHighlight => 'Highlight';

  @override
  String get noteColorYellow => 'Yellow';

  @override
  String get noteColorGreen => 'Green';

  @override
  String get noteColorBlue => 'Blue';

  @override
  String get noteColorRed => 'Red';

  @override
  String get noteColorOrange => 'Orange';

  @override
  String get noteColorPink => 'Pink';

  @override
  String get readerNotesNew => 'New note';

  @override
  String get readerNotesEmpty => 'No notes in this resource';

  @override
  String get readerNotesEmptyHint =>
      'Select text to create a note or a highlight.';

  @override
  String readerNotesOnVerse(Object verse) {
    return 'Notes on verse $verse';
  }

  @override
  String get readerNoteMarker => 'Notes on this verse';

  @override
  String get readerHighlightCreated => 'Highlight added';

  @override
  String get readerNoteCreated => 'Note created';

  @override
  String get readerNotesView => 'Notes in this resource';

  @override
  String get selectionCopy => 'Copy';

  @override
  String get selectionLookUp => 'Look up';

  @override
  String get selectionHighlight => 'Highlight';

  @override
  String get selectionNote => 'Note';

  @override
  String get selectionAddNote => 'Add note';

  @override
  String get selectionSearch => 'Search';

  @override
  String get selectionMore => 'Show more options';

  @override
  String get selectionVisualCopy => 'Visual copy';

  @override
  String get selectionUnderlineRed => 'Red underline';

  @override
  String get selectionRemoveHighlight => 'Remove highlight';

  @override
  String get readerHighlightUpdated => 'Highlight updated';

  @override
  String get readerHighlightRemoved => 'Highlight removed';

  @override
  String highlightSwatch(String color) {
    return '$color highlight';
  }

  @override
  String underlineSwatch(String color) {
    return '$color underline';
  }

  @override
  String get selectionCitation => 'Copy citation';

  @override
  String get selectionNoteStub => 'Note';

  @override
  String get devotionalToday => 'Today';

  @override
  String get devotionalPrevious => 'Previous day';

  @override
  String get devotionalNext => 'Next day';

  @override
  String get devotionalPickDate => 'Pick a date';

  @override
  String get devotionalEmptyTitle => 'No reading for this date';

  @override
  String get devotionalEmptyDetail => 'Try another day or go back to today.';

  @override
  String get factbookSearchHint => 'Topic or reference';

  @override
  String get factbookLoadError => 'The encyclopedia could not be loaded.';

  @override
  String factbookTopicsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count topics',
      one: '1 topic',
    );
    return '$_temp0';
  }

  @override
  String get factbookNoResults => 'No topics found';

  @override
  String get factbookOpenPassage => 'Open passage';

  @override
  String get factbookLensAll => 'All';

  @override
  String get factbookLensBiblical => 'Biblical';

  @override
  String get factbookLensLibrary => 'Library';

  @override
  String get factbookLensTheology => 'Theological';

  @override
  String get factbookLensCounseling => 'Counseling';

  @override
  String get factbookLensDiscover => 'Discover';

  @override
  String get factbookBack => 'Back to topics';

  @override
  String get factbookReferences => 'References';

  @override
  String get factbookRelated => 'Related topics';

  @override
  String get catalogFilterHint => 'Filter by title or topic';

  @override
  String catalogEntriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return '$_temp0';
  }

  @override
  String get catalogBackToIndex => 'Back to index';

  @override
  String get compareReferenceHint => 'Reference';

  @override
  String get compareVersions => 'Versions';

  @override
  String compareVersionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count versions',
      one: '1 version',
    );
    return '$_temp0';
  }

  @override
  String compareDifference(int percent) {
    return '$percent% difference';
  }

  @override
  String get compareCopy => 'Copy comparison';

  @override
  String get compareCopied => 'Comparison copied to the clipboard';

  @override
  String get compareNoVersions => 'No versions available';

  @override
  String get compareSingleVersion =>
      'Only one version is available; start the catalog service to compare more.';

  @override
  String get compareLoadError => 'The chapter could not be loaded.';

  @override
  String get compareNoChapter =>
      'The reference does not exist in this version.';

  @override
  String get compareInvalidReference =>
      'Invalid reference. Try, for example, “John 1”.';

  @override
  String get compareVersionUnavailable => 'Not available in this version.';

  @override
  String get compareAddVersions => 'Open Library';

  @override
  String get layoutsSaved => 'Saved layouts';

  @override
  String get layoutSaveCurrent => 'Save current layout…';

  @override
  String get layoutSaveTitle => 'Save layout';

  @override
  String get layoutNameLabel => 'Layout name';

  @override
  String get layoutNameHint => 'e.g., Study of John';

  @override
  String get layoutSave => 'Save';

  @override
  String get layoutSavedToast => 'Layout saved';

  @override
  String get layoutDelete => 'Delete layout';

  @override
  String layoutDeleteQuestion(String name) {
    return 'Delete the layout “$name”?';
  }

  @override
  String get layoutDeleteConfirm => 'Delete';

  @override
  String get layoutNoSaved => 'No saved layouts yet';

  @override
  String layoutAppliedToast(String name) {
    return 'Layout “$name” applied';
  }

  @override
  String get guidedFindHint => 'Find a guide';

  @override
  String get guidedGuides => 'Guides';

  @override
  String get guidedWorkflows => 'Workflows';

  @override
  String get guidedNoMatch => 'No guide matches the search.';

  @override
  String get guidedParamWord => 'Word';

  @override
  String get guidedParamReference => 'Reference';

  @override
  String get guidedGenerate => 'Generate guide';

  @override
  String get guidedBack => 'All guides';

  @override
  String get guidedStepDone => 'Mark step';

  @override
  String get guidedActionReader => 'Open in reader';

  @override
  String get guidedActionCompare => 'Compare versions';

  @override
  String get guidedActionFactbook => 'View in Topics';

  @override
  String get guidedActionSearch => 'Search the catalog';

  @override
  String get guidedActionNotes => 'Open Notes';

  @override
  String get guideWordTitle => 'Bible Word Study';

  @override
  String get guideWordDesc =>
      'Analyze a key word and its occurrences in the catalog.';

  @override
  String get guideExegeticalTitle => 'Exegetical Guide';

  @override
  String get guideExegeticalDesc =>
      'Context, structure and genre of the passage, step by step.';

  @override
  String get guidePassageTitle => 'Passage Guide';

  @override
  String get guidePassageDesc =>
      'Walk through a passage with the tools and the catalog.';

  @override
  String get guideSermonTitle => 'Sermon Starter Guide';

  @override
  String get guideSermonDesc => 'From the text to the outline of the message.';

  @override
  String get workflowBasicTitle => 'Basic Bible Study';

  @override
  String get workflowBasicDesc => 'Five classic steps to study a passage.';

  @override
  String get workflowInductiveTitle => 'Inductive Bible Study';

  @override
  String get workflowInductiveDesc =>
      'Observation, interpretation and application.';

  @override
  String get workflowLectioTitle => 'Lectio Divina';

  @override
  String get workflowLectioDesc => 'Prayerful reading in four movements.';

  @override
  String get stepPrayTitle => 'Pray and prepare your heart';

  @override
  String get stepPrayDetail =>
      'Ask the Lord to open your understanding before reading.';

  @override
  String get stepReadTitle => 'Read the whole passage';

  @override
  String stepReadDetail(String param) {
    return 'Read $param two or three times, without stopping on details.';
  }

  @override
  String get stepContextTitle => 'Study the context';

  @override
  String get stepContextDetail =>
      'Who writes, to whom and why? Check the topics of the passage.';

  @override
  String get stepObserveTitle => 'Observe the text';

  @override
  String get stepObserveDetail =>
      'Repetitions, contrasts, connectives and verb tenses.';

  @override
  String get stepInterpretTitle => 'Interpret';

  @override
  String get stepInterpretDetail =>
      'What did it mean then? What does it say here and now?';

  @override
  String get stepApplyTitle => 'Apply';

  @override
  String get stepApplyDetail =>
      'What is God asking of you today? Write it in Notes.';

  @override
  String get stepNoteTitle => 'Write down your conclusions';

  @override
  String get stepNoteDetail =>
      'Anchor a note to the verse and summarize what you found.';

  @override
  String get stepWordTitle => 'Analyze the key words';

  @override
  String stepWordDetail(String param) {
    return 'Search “$param” in the catalog and compare its occurrences.';
  }

  @override
  String get stepCrossTitle => 'Follow the cross references';

  @override
  String get stepCrossDetail =>
      'Open Insights ▸ Related passages in the reader and follow the citations.';

  @override
  String get stepCompareTitle => 'Compare translations';

  @override
  String get stepCompareDetail =>
      'Compare the passage with the other version in the catalog.';

  @override
  String get stepOutlineTitle => 'Outline the message';

  @override
  String get stepOutlineDetail =>
      'Three points with their application, written in Notes.';

  @override
  String get stepThemeTitle => 'Find the central theme';

  @override
  String get stepThemeDetail =>
      'Check the topics of the passage in Topics and pick the axis of the message.';

  @override
  String get stepLectioTitle => 'Lectio: read slowly';

  @override
  String stepLectioDetail(String param) {
    return 'Read $param aloud, savoring each sentence.';
  }

  @override
  String get stepMeditatioTitle => 'Meditatio: chew on the text';

  @override
  String get stepMeditatioDetail =>
      'Which word or phrase catches your attention? Why?';

  @override
  String get stepOratioTitle => 'Oratio: respond in prayer';

  @override
  String get stepOratioDetail => 'Turn the text into your own prayer.';

  @override
  String get stepContemplatioTitle => 'Contemplatio: rest in God';

  @override
  String get stepContemplatioDetail =>
      'Stay in silence with what God showed you.';

  @override
  String get toolsAtlas => 'Atlas';

  @override
  String get toolsCourses => 'Courses';

  @override
  String get toolsDocuments => 'Documents';

  @override
  String get toolsInfo => 'Information';

  @override
  String get toolsMedia => 'Media';

  @override
  String get toolsPlans => 'Reading plans';

  @override
  String get toolsSoon => 'Soon';

  @override
  String get panelTitleReadingPlans => 'Reading plans';

  @override
  String get plansIntro =>
      'Pick a plan to read the Bible at a steady pace. Progress is saved on your device.';

  @override
  String get plansEmpty => 'You have no active plan. Pick one to get started.';

  @override
  String get plansAvailable => 'Available plans';

  @override
  String get plansOther => 'Other plans';

  @override
  String get plansInProgress => 'In progress';

  @override
  String get plansOpenToday => 'Open today\'s reading';

  @override
  String get plansMarkRead => 'Mark day as read';

  @override
  String get plansStop => 'Stop plan';

  @override
  String plansDayOf(int day, int days) {
    return 'Day $day of $days';
  }

  @override
  String get plansCompleted =>
      'Plan complete! You can start another one whenever you like.';

  @override
  String get plansToday => 'Today\'s reading';

  @override
  String plansDays(int days) {
    return '$days days';
  }

  @override
  String get plansStart => 'Start';

  @override
  String get plansReplaceTitle => 'Replace the active plan?';

  @override
  String get plansReplaceBody =>
      'You already have a reading plan in progress. Starting another one will lose its progress.';

  @override
  String get plansReplace => 'Replace';

  @override
  String get planBibleYearTitle => 'Bible in a year';

  @override
  String get planBibleYearDesc =>
      'The whole canon, about three chapters a day.';

  @override
  String get planGospels30Title => 'Gospels in 30 days';

  @override
  String get planGospels30Desc => 'Matthew, Mark, Luke and John in full.';

  @override
  String get planPsalms31Title => 'Psalms and Proverbs in 31 days';

  @override
  String get planPsalms31Desc => 'Daily wisdom for a month.';

  @override
  String get planNt90Title => 'New Testament in 90 days';

  @override
  String get planNt90Desc => 'All 27 New Testament books.';

  @override
  String get readingPlanView => 'View reading plan';

  @override
  String get dashboardSubtitle =>
      'Pick up where you left off and get back to your tools.';

  @override
  String get dashboardContinue => 'Continue reading';

  @override
  String get dashboardContinueEmpty =>
      'Open a passage from the sidebar or the search box to see it here.';

  @override
  String get dashboardPlan => 'Reading plan';

  @override
  String get dashboardPlanEmpty => 'You don\'t have an active plan.';

  @override
  String get dashboardPlanChoose => 'Choose a plan';

  @override
  String get dashboardPlanView => 'View the plan';

  @override
  String get dashboardNotes => 'Notes';

  @override
  String dashboardNotesCount(int notes, int highlights) {
    String _temp0 = intl.Intl.pluralLogic(
      notes,
      locale: localeName,
      other: '$notes notes',
      one: '1 note',
    );
    String _temp1 = intl.Intl.pluralLogic(
      highlights,
      locale: localeName,
      other: '$highlights highlights',
      one: '1 highlight',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get dashboardNotesOpen => 'Open Notes';

  @override
  String get dashboardDevotional => 'Today\'s devotional';

  @override
  String get dashboardDevotionalOpen => 'Open the devotional';

  @override
  String get dashboardGuided => 'Guided study';

  @override
  String get dashboardGuidedOpen => 'Open guided study';

  @override
  String get dashboardTools => 'Tools';

  @override
  String get assistantLead =>
      'Just ask. I\'ll use your library to answer questions like…';

  @override
  String get assistantPrompt1 => 'What does John 1 teach about the Word?';

  @override
  String get assistantPrompt2 => 'How does Psalm 23 describe the shepherd?';

  @override
  String get assistantPrompt3 => 'What do the Gospels say about forgiveness?';

  @override
  String get assistantAiNotice =>
      'This feature uses AI. Always double-check results.';

  @override
  String get assistantConnect => 'Connect an AI provider';

  @override
  String get assistantConnectTail => 'to start a conversation.';

  @override
  String get assistantDialogTitle => 'Study Assistant';

  @override
  String get assistantDialogBody =>
      'The assistant is an optional plugin: this installation has no AI provider connected. Once you connect one, answers will come with citations from your library. In the meantime, guided study and the other tools work locally.';

  @override
  String get assistantDialogOpenGuided => 'Open guided study';

  @override
  String get assistantChatHint =>
      'Ask about your library: answers come with citations that open the reader.';

  @override
  String get assistantNew => 'New';

  @override
  String get assistantRecent => 'Recent';

  @override
  String get assistantRecentEmpty => 'No questions yet.';

  @override
  String get assistantCopyAll => 'Copy all';

  @override
  String get assistantCopied => 'Conversation copied.';

  @override
  String get assistantScope => 'Scope';

  @override
  String get assistantScopeAll => 'All books';

  @override
  String get assistantScopeBible => 'The Bible';

  @override
  String get assistantInput => 'Type your question…';

  @override
  String get assistantSend => 'Send';

  @override
  String get assistantThinking => 'Thinking…';

  @override
  String get assistantYou => 'You';

  @override
  String get assistantAnswerLabel => 'Assistant';

  @override
  String get assistantFailed => 'Couldn\'t get a response from the provider.';

  @override
  String get readerLinkSetNone => 'No link set';

  @override
  String get readerLinkSetHelp =>
      'Panels with the same letter follow the same reference.';

  @override
  String get storeTitle => 'Module store';

  @override
  String get storeIntro =>
      'The decoupled catalog splits content into public-domain and Creative Commons modules. Choose what to install: downloads run with progress and, once installed, reading works without the network.';

  @override
  String storeCount(int count) {
    return '$count resources available';
  }

  @override
  String get storeIncluded => 'Included';

  @override
  String get storeOpen => 'Open';

  @override
  String get storeSearch => 'Search resources';

  @override
  String get storeAllTypes => 'All types';

  @override
  String get storeAllSubjects => 'All subjects';

  @override
  String get storeAllPublishers => 'All publishers';

  @override
  String get storeEmpty => 'No matching resources.';

  @override
  String get storeError => 'The local catalog could not be loaded.';

  @override
  String get storeRetry => 'Retry';

  @override
  String get storeOpenLibrary => 'Open Library';

  @override
  String get storeLicense => 'License';

  @override
  String get panelFullscreenEnter => 'Full screen';

  @override
  String get panelFullscreenExit => 'Exit full screen';

  @override
  String get settingsTheme => 'Interface theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeHelp => 'Light, dark, or match the system.';

  @override
  String get readerOriginal => 'Original';

  @override
  String get readerOriginalTooltip => 'Open the original text';

  @override
  String get wordStudyTitle => 'Word study';

  @override
  String get wordStudyStrong => 'Strong';

  @override
  String get wordStudyTranslit => 'Transliteration';

  @override
  String get wordStudyLemma => 'Lemma';

  @override
  String get wordStudyMorphology => 'Morphology';

  @override
  String get wordStudyGloss => 'Gloss';

  @override
  String get wordStudyGlossSource => 'Source gloss (English)';

  @override
  String get wordStudyOpenLexicon => 'Open in lexicon';

  @override
  String get wordStudyLexiconTitle => 'Strong\'s lexicon';

  @override
  String get wordStudyLexiconError => 'The lexicon entry could not be loaded.';

  @override
  String get wordStudyNoLexicon => 'No lexicon entry for this word.';

  @override
  String get tabFullscreen => 'Full screen';

  @override
  String get mapTitle => 'Map';

  @override
  String get mapLoadError => 'The map could not be loaded.';

  @override
  String get mapZoomIn => 'Zoom in the map';

  @override
  String get mapZoomOut => 'Zoom out of the map';

  @override
  String get mapZoomReset => 'Fit the whole map';

  @override
  String get mapFullView => 'Open full map';

  @override
  String get mapAttribution =>
      'Geometry: Natural Earth (public domain) · Places: OpenBible.info (CC BY 4.0)';

  @override
  String get panelTitleAtlas => 'Atlas';

  @override
  String get panelTitleCourses => 'Courses';

  @override
  String get panelTitleDocuments => 'Documents';

  @override
  String get panelTitleMedia => 'Media';

  @override
  String get panelTitleFavorites => 'Favorites';

  @override
  String get panelTitlePsalms => 'Psalms Explorer';

  @override
  String get toolsFavorites => 'Favorites';

  @override
  String get toolsPsalms => 'Psalms Explorer';

  @override
  String get atlasIntro =>
      'Explore the maps from the Factbook and the commentary. They are drawn offline with Natural Earth geometry and OpenBible.info coordinates.';

  @override
  String get mediaIntro =>
      'A gallery of visual catalog content. Each card opens the map and the original section that accompanies it.';

  @override
  String get atlasSearchHint => 'Search for a map or place';

  @override
  String get mediaSearchHint => 'Search media';

  @override
  String get atlasSourceAll => 'All sources';

  @override
  String get atlasSourceFactbook => 'Factbook';

  @override
  String get atlasSourceCommentary => 'Commentary';

  @override
  String get atlasLoadError => 'Could not load this catalog entry.';

  @override
  String get mediaLoadError => 'Could not load the media.';

  @override
  String get atlasEmpty => 'There are no maps in the bundled catalog yet.';

  @override
  String get mediaEmpty =>
      'There is no visual content in the bundled catalog yet.';

  @override
  String get atlasAttribution =>
      'Maps from Aletheia\'s own catalog. Geometry and coordinates keep their attribution.';

  @override
  String get atlasNoResults => 'No map matches the search.';

  @override
  String atlasCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return '$_temp0';
  }

  @override
  String get mediaOpenMap => 'Open map';

  @override
  String get atlasOpenResource => 'Open section';

  @override
  String get coursesIntro =>
      'Short study paths with RV1909 readings. Pick one and move through it lesson by lesson.';

  @override
  String get coursesSearchHint => 'Search for a course';

  @override
  String get coursesNoResults => 'No course matches the search.';

  @override
  String coursesLessons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lessons',
      one: '1 lesson',
    );
    return '$_temp0';
  }

  @override
  String get courseCompleted =>
      'Course complete. You can revisit its readings whenever you like.';

  @override
  String courseProgress(int done, int total) {
    return 'Progress: $done of $total';
  }

  @override
  String get courseLessonRead => 'Read';

  @override
  String get coursePanoramaTitle => 'Bible overview';

  @override
  String get coursePanoramaDesc =>
      'Three stops through the biblical story: creation, exodus, and monarchy.';

  @override
  String get coursePanoramaLesson1Title => 'Creation and covenant';

  @override
  String get coursePanoramaLesson1Detail =>
      'Read the beginning of Genesis and notice how God orders creation and calls forth life.';

  @override
  String get coursePanoramaLesson2Title => 'Exodus and liberation';

  @override
  String get coursePanoramaLesson2Detail =>
      'The burning bush reveals God\'s name and begins the liberation from Egypt.';

  @override
  String get coursePanoramaLesson3Title => 'Kings and prophets';

  @override
  String get coursePanoramaLesson3Detail =>
      'David\'s anointing opens a new stage in Israel\'s history.';

  @override
  String get courseGospelsTitle => 'The Gospels';

  @override
  String get courseGospelsDesc =>
      'The announcement of the Kingdom, mercy, and resurrection in three readings.';

  @override
  String get courseGospelsLesson1Title => 'The Kingdom draws near';

  @override
  String get courseGospelsLesson1Detail =>
      'Jesus proclaims the Kingdom and calls for repentance in Galilee.';

  @override
  String get courseGospelsLesson2Title => 'Parables and mercy';

  @override
  String get courseGospelsLesson2Detail =>
      'The parables of Luke 15 show the Father\'s heart as he seeks the lost.';

  @override
  String get courseGospelsLesson3Title => 'Cross and resurrection';

  @override
  String get courseGospelsLesson3Detail =>
      'The empty tomb opens John\'s Gospel and the mission of the community.';

  @override
  String get coursePrayerTitle => 'Psalms and prayer';

  @override
  String get coursePrayerDesc =>
      'Three psalms for praying with trust, lament, and praise.';

  @override
  String get coursePrayerLesson1Title => 'Trust in the shepherd';

  @override
  String get coursePrayerLesson1Detail =>
      'Psalm 23 accompanies prayer with the image of the shepherd who cares.';

  @override
  String get coursePrayerLesson2Title => 'Honest lament';

  @override
  String get coursePrayerLesson2Detail =>
      'Psalm 42 teaches us to bring thirst and sorrow before God.';

  @override
  String get coursePrayerLesson3Title => 'The praise of all the people';

  @override
  String get coursePrayerLesson3Detail =>
      'Psalm 100 invites us to celebrate God\'s faithfulness with gratitude.';

  @override
  String get documentsIntro =>
      'Three short study guides written by Aletheia to accompany reading and catalog study.';

  @override
  String get documentsSearchHint => 'Search documents';

  @override
  String get documentsNoResults => 'No document matches the search.';

  @override
  String get documentsAttribution =>
      'Original Aletheia documents; they do not reproduce licensed third-party works.';

  @override
  String get documentReadingTitle => 'How to read the Bible';

  @override
  String get documentReadingSubtitle =>
      'A simple four-step method: observe, interpret, apply, and pray.';

  @override
  String get documentReadingBody =>
      '## Before reading\n\nThe Bible is a library of books written in different periods. Before looking for an immediate application, locate the passage: who is writing, to whom, and what problem or promise appears in the context?\n\n## Observe\n\nRead slowly and write down what the text says, not what you expect it to say. Notice repeated words, people, places, contrasts, and commands. Good observation prepares good interpretation.\n\n## Interpret\n\nAsk what the passage meant to its first readers and how it fits the biblical story. Compare translations and consult the commentary or dictionary when a word or custom is unclear.\n\n## Apply and pray\n\nApplication grows from the meaning of the text, not the other way around. End by turning what you have seen into prayer: give thanks, confess, ask for help, and commit to one concrete step.';

  @override
  String get documentTimelineTitle => 'Biblical timeline';

  @override
  String get documentTimelineSubtitle =>
      'Four stages to orient yourself in the history of the Old and New Testaments.';

  @override
  String get documentTimelineBody =>
      '## Patriarchs and exodus\n\nGenesis presents Abraham, Isaac, and Jacob; Exodus narrates the liberation from Egypt and the covenant at Sinai. These are stories of calling, promise, and the formation of a people.\n\n## Monarchy and prophets\n\nSamuel, Saul, and David inaugurate the monarchy. The prophets call the people to covenant faithfulness and announce judgment and hope.\n\n## Exile and return\n\nThe fall of Jerusalem and the Babylonian exile mark a deep crisis. Ezra and Nehemiah tell of reconstruction; the psalms and prophets preserve the memory of waiting.\n\n## Jesus and the church\n\nThe Gospels present Jesus as the fulfillment of the promises. Acts and the letters describe the community that proclaims his death and resurrection.';

  @override
  String get documentGlossaryTitle => 'Study glossary';

  @override
  String get documentGlossarySubtitle =>
      'Four terms that appear again and again in biblical reading.';

  @override
  String get documentGlossaryBody =>
      '## Covenant\n\nA bond established by God with his people, with promises and commitments. It is not a contract between equals: God takes the initiative and sustains the relationship.\n\n## Grace\n\nThe favor God gives without it being a deserved reward. In the New Testament it is the basis of salvation and the Christian life.\n\n## Justification\n\nGod\'s act of declaring the sinner who believes to be righteous on the basis of Christ\'s work. It is not prior moral improvement but a new relationship with God.\n\n## Messianism\n\nThe hope for a king or envoy of God who will restore his people. The Gospels read Jesus as the fulfillment of that hope, both present and future.';

  @override
  String get favoritesIntro =>
      'Save passages to return to them. You can also add a reference directly.';

  @override
  String get favoritesAddHint => 'Reference: John 3:16';

  @override
  String get favoritesAdd => 'Add';

  @override
  String get favoritesInvalidReference => 'That reference is not recognized.';

  @override
  String get favoritesAlreadySaved => 'That passage is already in Favorites.';

  @override
  String get favoritesPassageSubtitle => 'RV1909 passage';

  @override
  String get favoritesSearchHint => 'Search Favorites';

  @override
  String get favoritesEmpty =>
      'No favorites yet. Use the star in the reader or add a reference.';

  @override
  String get favoritesNoResults => 'No favorite matches the search.';

  @override
  String get favoritesOpen => 'Open favorite';

  @override
  String get favoritesRemove => 'Remove from Favorites';

  @override
  String get favoritesAdded => 'Added to Favorites';

  @override
  String get favoritesRemoved => 'Removed from Favorites';

  @override
  String get psalmsIntro =>
      'Browse the 150 psalms by genre and open any of them in the reader. Categories overlap.';

  @override
  String get psalmsSearchHint => 'Search for a psalm or a word';

  @override
  String psalmsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count psalms',
      one: '1 psalm',
    );
    return '$_temp0';
  }

  @override
  String get psalmsAll => 'All';

  @override
  String get psalmsNoResults => 'No psalm matches the search.';

  @override
  String get psalmsAttribution =>
      'Aletheia\'s own classification; the biblical text is the public-domain RV1909.';

  @override
  String get psalmOfDay => 'Psalm of the day';

  @override
  String psalmNumber(int number) {
    return 'Psalm $number';
  }

  @override
  String get psalmsOpen => 'Read';

  @override
  String get psalmsSubtitle => 'RV1909 psalm';

  @override
  String get psalmCategoryPraise => 'Praise';

  @override
  String get psalmCategoryLament => 'Lament';

  @override
  String get psalmCategoryTrust => 'Trust';

  @override
  String get psalmCategoryThanks => 'Thanksgiving';

  @override
  String get psalmCategoryWisdom => 'Wisdom';

  @override
  String get psalmCategoryMessianic => 'Messianic';

  @override
  String get psalmCategoryPenitential => 'Penitential';

  @override
  String get psalmCategoryPilgrimage => 'Pilgrimage';

  @override
  String get moduleInstall => 'Install';

  @override
  String get moduleCancel => 'Cancel install';

  @override
  String moduleSize(String size) {
    return '$size';
  }

  @override
  String get moduleAvailableBody =>
      'This resource lives in the decoupled catalog: install it to read it without depending on the network afterwards.';

  @override
  String get moduleInstallFailed =>
      'The install did not finish. Check your connection and try again.';

  @override
  String moduleDownloading(String received) {
    return 'Downloading… $received';
  }

  @override
  String get moduleInstallUnavailable =>
      'This resource downloads when opened; desktop app manages modules explicitly.';

  @override
  String readerBookNotAvailable(String book, String resource) {
    return '$book is not available in $resource. The decoupled catalog ships only part of the books per resource.';
  }

  @override
  String readerOpenEquivalent(String book, String resource) {
    return 'Open $book in $resource';
  }

  @override
  String get storeInstallButton => 'Install';

  @override
  String get storeInstalledBadge => 'Installed';

  @override
  String get storeUpdateBadge => 'Update available';

  @override
  String get storeUninstallButton => 'Uninstall';

  @override
  String get storeCancelInstall => 'Cancel';

  @override
  String get storeConfirmUninstall =>
      'Remove the module from this device? You can reinstall it from here later.';

  @override
  String get storeRemovedTitle => 'Module removed';

  @override
  String storeUninstalledSnackbar(String module) {
    return '$module removed.';
  }

  @override
  String get storeInstallErrorTitle => 'Install failed';

  @override
  String get storeSectionInstalled => 'Installed';

  @override
  String get storeSectionAvailable => 'Available';

  @override
  String get storeSearchModuleHint =>
      'The local search index is a module too: without it search falls back to the service instead of working offline.';

  @override
  String get libraryNotInstalledChip => 'Not installed';

  @override
  String get libraryInstalledChip => 'Installed';

  @override
  String get dataCareTitle => 'Data & backup';

  @override
  String get backupExport => 'Export backup…';

  @override
  String get backupExportHelp =>
      'Save your notes, highlights, favorites, plans and layouts into a backup file.';

  @override
  String backupExported(String path) {
    return 'Backup saved to $path';
  }

  @override
  String get backupRestore => 'Restore backup…';

  @override
  String get backupRestoreHelp =>
      'Pick an earlier backup; it will be applied next time you open Aletheia.';

  @override
  String get backupRestoreConfirmTitle => 'Restore this backup?';

  @override
  String backupRestoreConfirmBody(String date, String version) {
    return 'Your data from $date (backup created with version $version) will be restored. Your current data is kept before replacing it.';
  }

  @override
  String get backupRestoreApply => 'Restore and restart';

  @override
  String get backupStagedRestart =>
      'Backup ready: it will be applied next time you open Aletheia.';

  @override
  String get crashLogExport => 'Export crash log…';

  @override
  String get crashLogHelp =>
      'Local error log, no telemetry; useful to report issues.';

  @override
  String get crashLogEmpty => 'No crash log yet.';

  @override
  String crashLogExported(String path) {
    return 'Log saved to $path';
  }

  @override
  String get crashLogClear => 'Clear crash log';

  @override
  String get crashLogCleared => 'Log cleared.';

  @override
  String get updateCheck => 'Check for updates';

  @override
  String get updateCheckHelp =>
      'Compares your version with the latest GitHub release. No telemetry.';

  @override
  String get updateNone => 'You are using the latest version.';

  @override
  String updateAvailableTitle(String version) {
    return 'New version available: $version';
  }

  @override
  String get updateAvailableBody =>
      'You can download the binary for your platform from the GitHub releases page.';

  @override
  String get updateOpenReleases => 'Open releases';

  @override
  String aboutVersion(String version) {
    return 'Aletheia $version';
  }

  @override
  String get exportPassage => 'Export passage…';

  @override
  String get exportNote => 'Export note…';

  @override
  String get exportFormat => 'Format';

  @override
  String get exportFormatMarkdown => 'Markdown';

  @override
  String get exportFormatHtml => 'HTML';

  @override
  String get exportFormatPlain => 'Plain text';

  @override
  String get exportCopy => 'Copy to clipboard';

  @override
  String get exportSave => 'Save file…';

  @override
  String get exportPrint => 'Print…';

  @override
  String get exportPrintHelp =>
      'Opens the passage in your browser with the print dialog.';

  @override
  String exportSaved(String path) {
    return 'File saved to $path';
  }

  @override
  String get exportCopied => 'Export copied to clipboard';
}
