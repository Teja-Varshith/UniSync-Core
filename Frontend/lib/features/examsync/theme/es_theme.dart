import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:UniSync/features/examsync/utils/hash.dart';

/// ExamSync's NeoPOP palette. ExamSync keeps its own dark look regardless of
/// UniSync's theme mode, matching the web student app.
class EsColors {
  EsColors._();

  static const bg = Color(0xFF0D0D0D);
  static const bgSecondary = Color(0xFF121212);
  static const surface = Color(0xFF161616);
  static const surfaceElevated = Color(0xFF1F1F1F);
  static const border = Color(0xFF2A2A2A);
  static const borderLight = Color(0xFF3D3D3D);

  static const text = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFBDBDBD);
  static const textMuted = Color(0xFF8A8A8A);
  static const textDisabled = Color(0xFF6B6B6B);

  static const accent = Color(0xFFFFCB45);
  static const accentRight = Color(0xFFB38E30);
  static const accentBottom = Color(0xFF806623);

  static const premium = Color(0xFF6A35FF);
  static const premiumRight = Color(0xFF4A25B3);
  static const premiumBottom = Color(0xFF351A80);

  static const success = Color(0xFF06C270);
  static const successRight = Color(0xFF048A50);
  static const successBottom = Color(0xFF035C35);

  static const error = Color(0xFFEE4D37);
  static const warning = Color(0xFFFF8744);
  static const lime = Color(0xFFE5FE40);
  static const pink = Color(0xFFFF426F);
}

/// Per-subject colour, picked by a stable hash of the course code.
class EsTone {
  const EsTone({
    required this.name,
    required this.face,
    required this.right,
    required this.bottom,
    required this.ink,
    required this.pop,
  });

  final String name;
  final Color face;
  final Color right;
  final Color bottom;
  final Color ink;
  final Color pop;

  static const all = <EsTone>[
    EsTone(
      name: 'purple',
      face: Color(0xFF6A35FF),
      right: Color(0xFF4A25B3),
      bottom: Color(0xFF351A80),
      ink: Colors.white,
      pop: Color(0xFFE5FE40),
    ),
    EsTone(
      name: 'lime',
      face: Color(0xFFE5FE40),
      right: Color(0xFFA0B22D),
      bottom: Color(0xFF727F20),
      ink: Colors.black,
      pop: Color(0xFF6A35FF),
    ),
    EsTone(
      name: 'pink',
      face: Color(0xFFFF426F),
      right: Color(0xFFB32E4E),
      bottom: Color(0xFF802138),
      ink: Colors.black,
      pop: Colors.white,
    ),
    EsTone(
      name: 'orange',
      face: Color(0xFFFF8744),
      right: Color(0xFFB35F30),
      bottom: Color(0xFF804322),
      ink: Colors.black,
      pop: Color(0xFF6A35FF),
    ),
    EsTone(
      name: 'violet',
      face: Color(0xFFAA3FFF),
      right: Color(0xFF772CB3),
      bottom: Color(0xFF552080),
      ink: Colors.white,
      pop: Color(0xFFFFCB45),
    ),
    EsTone(
      name: 'blue',
      face: Color(0xFF144CC7),
      right: Color(0xFF0E3793),
      bottom: Color(0xFF0A2766),
      ink: Colors.white,
      pop: Color(0xFFFF426F),
    ),
  ];

  static EsTone forCode(String courseCode) =>
      all[fnv1a32(courseCode) % all.length];
}

/// Typography: Plus Jakarta Sans for UI, Fraunces for display, JetBrains Mono
/// for codes and numbers.
class EsText {
  EsText._();

  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = EsColors.text,
    double? height,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );

  static TextStyle display({
    double size = 26,
    Color color = EsColors.text,
    FontStyle style = FontStyle.normal,
  }) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        fontStyle: style,
        letterSpacing: -0.02 * size,
        height: 1.1,
      );

  static TextStyle mono({
    double size = 12,
    Color color = EsColors.text,
    FontWeight weight = FontWeight.w700,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
      );

  /// 11sp, uppercase, wide tracking. Callers upper-case the text.
  static TextStyle eyebrow({Color color = EsColors.textMuted}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.65,
        color: color,
      );
}

/// Material theme for the ExamSync subtree, so stock widgets (sheets,
/// progress indicators, selection) pick up the NeoPOP colours.
ThemeData examSyncTheme(ThemeData base) {
  final scheme = const ColorScheme.dark(
    primary: EsColors.accent,
    onPrimary: Colors.black,
    secondary: EsColors.premium,
    surface: EsColors.surface,
    onSurface: EsColors.text,
    error: EsColors.error,
  );
  return base.copyWith(
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: EsColors.bg,
    canvasColor: EsColors.bg,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(
      ThemeData.dark().textTheme,
    ).apply(bodyColor: EsColors.text, displayColor: EsColors.text),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: EsColors.accent),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: EsColors.surface,
      shape: RoundedRectangleBorder(),
    ),
    splashFactory: NoSplash.splashFactory,
  );
}
