import 'package:flutter/material.dart';

const violet = Color(0xFF6940FF);
const ink = Color(0xFF151628);
const muted = Color(0xFF7E8099);
const page = Color(0xFFF6F6FC);
const lavender = Color(0xFFE8E5FF);
const backgroundGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFF8F8FD), Color(0xFFF2F3FB), Color(0xFFECEAFF)],
);
ThemeData musicTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: page,
  colorScheme: ColorScheme.fromSeed(
    seedColor: violet,
    primary: violet,
    surface: page,
    onSurface: ink,
  ),
  fontFamily: 'Roboto',
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w800,
      letterSpacing: -.9,
      color: ink,
    ),
    headlineSmall: TextStyle(
      fontSize: 23,
      fontWeight: FontWeight.w700,
      letterSpacing: -.5,
      color: ink,
    ),
    titleLarge: TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.w700,
      letterSpacing: -.4,
      color: ink,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    bodyMedium: TextStyle(fontSize: 14, color: ink),
    bodySmall: TextStyle(fontSize: 12, color: muted),
  ),
  iconTheme: const IconThemeData(color: ink, size: 24),
  dividerColor: const Color(0xFFE6E5F0),
  splashFactory: InkSparkle.splashFactory,
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: page,
    showDragHandle: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: ink,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFECECF6),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide.none,
    ),
  ),
  sliderTheme: const SliderThemeData(
    trackHeight: 3,
    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5),
  ),
);
