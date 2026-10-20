import 'package:flutter/material.dart';

/// Tokens visuales de M0 (aproximación propia al look de referencia).
///
/// El tema se resuelve con una paleta activa global. Los widgets consumen los
/// getters (`kPanelBg`, `kTextSecondary`, …) y el `MaterialApp` cambia la
/// paleta al alternar claro/oscuro. Para que los `const` no congelen los
/// colores, esos tokens son getters y no constantes de compilación.
const kAccent = Color(0xFF1A73E8);
const kAccentDark = Color(0xFF0B57D0);

/// Paleta de un tema. Los nombres coinciden con los tokens históricos.
class AletheiaPalette {
  const AletheiaPalette({
    required this.isDark,
    required this.workspaceBg,
    required this.sidebarBg,
    required this.panelBg,
    required this.border,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.fieldFill,
    required this.bannerBg,
  });

  final bool isDark;
  final Color workspaceBg;
  final Color sidebarBg;
  final Color panelBg;
  final Color border;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color fieldFill;
  final Color bannerBg;

  static const light = AletheiaPalette(
    isDark: false,
    workspaceBg: Color(0xFFEEEEEE),
    sidebarBg: Color(0xFFF7F8FA),
    panelBg: Colors.white,
    border: Color(0xFFDDE1E6),
    cardBorder: Color(0xFFE3E3E3),
    textPrimary: Color(0xFF202124),
    textSecondary: Color(0xFF5F6368),
    fieldFill: Color(0xFFF2F3F4),
    bannerBg: Color(0xFF00042F),
  );

  static const dark = AletheiaPalette(
    isDark: true,
    workspaceBg: Color(0xFF111315),
    sidebarBg: Color(0xFF17191C),
    panelBg: Color(0xFF1E2125),
    border: Color(0xFF34383E),
    cardBorder: Color(0xFF30343A),
    textPrimary: Color(0xFFE8EAED),
    textSecondary: Color(0xFFA8ADB5),
    fieldFill: Color(0xFF262A2F),
    bannerBg: Color(0xFF00042F),
  );
}

AletheiaPalette _activePalette = AletheiaPalette.light;

AletheiaPalette get activePalette => _activePalette;

void setActivePalette(AletheiaPalette palette) {
  _activePalette = palette;
}

Color get kWorkspaceBg => _activePalette.workspaceBg;
Color get kSidebarBg => _activePalette.sidebarBg;
Color get kPanelBg => _activePalette.panelBg;
Color get kBorder => _activePalette.border;
Color get kCardBorder => _activePalette.cardBorder;
Color get kTextPrimary => _activePalette.textPrimary;
Color get kTextSecondary => _activePalette.textSecondary;
Color get kBannerBg => _activePalette.bannerBg;
Color get kFieldFill => _activePalette.fieldFill;

/// Avisos (fondo de nota, texto de advertencia) legibles en ambos temas.
Color get kWarning =>
    _activePalette.isDark ? const Color(0xFFF5B971) : const Color(0xFF8A4B00);

/// Texto de error/eliminación legible en ambos temas.
Color get kDangerText =>
    _activePalette.isDark ? const Color(0xFFF2B8B5) : kError;

/// Color de error de los campos (el mismo que usa `InputDecoration`).
const kError = Color(0xFFB3261E);

/// Breakpoints de layout — se evalúan sobre el ancho de la ventana
/// (no sobre hardware), según la guía `flutter-build-responsive-layout`.
const double kSidebarWidth = 232;
const double kSidebarRailWidth = 52;
const double kSidebarAutoCollapseWidth = 880;
const double kBannerMinWidth = 760;

/// Ancho mínimo legible de un panel en el área de trabajo.
///
/// El original (ver la evidencia de reconocimiento) **nunca
/// apila** los paneles: los mantiene lado a lado y los encoge hasta ~120 px
/// antes de plegar el espacio a un solo panel (regla absurda en la práctica,
/// confirmado con el usuario). El clon es adaptativo: cuando el área de
/// trabajo no da para todos los tiles con este mínimo, muestra solo los que
/// caben (en orden, sin huecos vacíos) y el resto vuelve a aparecer al
/// ensanchar. Los tiles nunca se apilan en vertical.
const double kMinTileWidth = 320;

ThemeData _buildTheme(AletheiaPalette palette) {
  final base = palette.isDark
      ? ThemeData.dark(useMaterial3: true)
      : ThemeData.light(useMaterial3: true);
  final scheme = base.colorScheme.copyWith(
    brightness: palette.isDark ? Brightness.dark : Brightness.light,
    primary: kAccent,
    surface: palette.panelBg,
    onSurface: palette.textPrimary,
    onSurfaceVariant: palette.textSecondary,
    outline: palette.border,
    outlineVariant: palette.cardBorder,
    error: palette.isDark ? const Color(0xFFF2B8B5) : kError,
  );
  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.workspaceBg,
    canvasColor: palette.panelBg,
    cardColor: palette.panelBg,
    dividerColor: palette.border,
    dividerTheme: DividerThemeData(color: palette.border, thickness: 1),
    textTheme: base.textTheme.apply(
      bodyColor: palette.textPrimary,
      displayColor: palette.textPrimary,
    ),
    iconTheme: IconThemeData(
      size: 18,
      color: palette.isDark ? const Color(0xFFC7CBD1) : const Color(0xFF444B54),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: palette.panelBg,
      elevation: 3,
      shadowColor: const Color(0x33000000),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      menuPadding: const EdgeInsets.symmetric(vertical: 6),
      textStyle: TextStyle(fontSize: 13.5, color: palette.textPrimary),
      iconColor: palette.textSecondary,
      iconSize: 16,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.panelBg,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: palette.fieldFill,
      hintStyle: TextStyle(color: palette.textSecondary),
    ),
    visualDensity: VisualDensity.compact,
  );
}

ThemeData buildLightTheme() => _buildTheme(AletheiaPalette.light);

ThemeData buildDarkTheme() => _buildTheme(AletheiaPalette.dark);
