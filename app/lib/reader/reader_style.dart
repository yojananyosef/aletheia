/// Tokens de tipografía del lector (M1).
///
/// El original usa una serif para el cuerpo de texto; aquí usamos la serif
/// del sistema con una lista de respaldo por plataforma (Linux/Windows/macOS).
/// El usuario puede elegir la pila **por recurso** (pestaña del lector):
/// serif (predeterminada), sans o monoespaciada.
library;

import 'package:flutter/material.dart';

import '../core/theme.dart';

const List<String> kReaderFontFallback = [
  'DejaVu Serif',
  'Liberation Serif',
  'Noto Serif',
  'Georgia',
  'Times New Roman',
];

/// Pilas de tipografía disponibles por recurso (`TabDisplay.font`).
const Map<String, List<String>> kReaderFontStacks = {
  'serif': kReaderFontFallback,
  'sans': [
    'DejaVu Sans',
    'Liberation Sans',
    'Noto Sans',
    'Segoe UI',
    'Roboto',
    'Helvetica',
  ],
  'mono': ['DejaVu Sans Mono', 'Liberation Mono', 'Consolas', 'Menlo'],
};

/// Resuelve la pila por clave (`serif` por defecto).
List<String> readerFontStack(String key) =>
    kReaderFontStacks[key] ?? kReaderFontFallback;

const double kReaderBodySize = 15.5;

TextStyle readerBodyStyle({
  double size = kReaderBodySize,
  Color? color,
  String font = 'serif',
}) {
  final stack = readerFontStack(font);
  return TextStyle(
    fontFamily: stack.first,
    fontFamilyFallback: stack.sublist(1),
    fontSize: size,
    height: 1.55,
    color: color ?? kTextPrimary,
  );
}

TextStyle readerHeadingStyle({String font = 'serif'}) =>
    readerBodyStyle(size: 17.5, font: font).copyWith(
      fontWeight: FontWeight.w700,
    );

TextStyle readerSectionHeadingStyle({String font = 'serif'}) =>
    readerBodyStyle(size: 17, font: font).copyWith(
      fontWeight: FontWeight.w700,
    );

TextStyle readerChapterNumberStyle({String font = 'serif'}) =>
    readerBodyStyle(size: 30, font: font).copyWith(
      fontWeight: FontWeight.w600,
      height: 1.2,
    );

TextStyle readerMarkerStyle({String font = 'serif'}) =>
    readerBodyStyle(size: 10, font: font)
        .copyWith(height: 1.0, color: kTextSecondary);
