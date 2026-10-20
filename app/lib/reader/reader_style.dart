/// Tokens de tipografía del lector (M1).
///
/// El original usa una serif para el cuerpo de texto; aquí usamos la serif
/// del sistema con una lista de respaldo por plataforma (Linux/Windows/macOS).
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

const double kReaderBodySize = 15.5;

TextStyle readerBodyStyle({double size = kReaderBodySize, Color? color}) =>
    TextStyle(
      fontFamily: kReaderFontFallback.first,
      fontFamilyFallback: kReaderFontFallback.sublist(1),
      fontSize: size,
      height: 1.55,
      color: color ?? kTextPrimary,
    );

TextStyle readerHeadingStyle() => readerBodyStyle(size: 17.5).copyWith(
      fontWeight: FontWeight.w700,
    );

TextStyle readerSectionHeadingStyle() => readerBodyStyle(size: 17).copyWith(
      fontWeight: FontWeight.w700,
    );

TextStyle readerChapterNumberStyle() => readerBodyStyle(size: 30).copyWith(
      fontWeight: FontWeight.w600,
      height: 1.2,
    );

TextStyle readerMarkerStyle() =>
    readerBodyStyle(size: 10).copyWith(height: 1.0, color: kTextSecondary);
