import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const BASE_URI  = "http://10.171.216.196:3000/api";

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
	GlobalKey<ScaffoldMessengerState>();

final dio = Dio();



final dioProvider = Provider((ref) => dio);

class UniSyncColors {
	UniSyncColors._();

	// Brand anchors
	static const Color brandYellow = Color(0xFFFFD72F);
	static const Color neutralLight = Color(0xFFF1EFE7);
	static const Color darkBase = Color(0xFF0B0B0D);

	// Backgrounds and surfaces
	static const Color backgroundPrimary = darkBase;
	static const Color backgroundSecondary = Color(0xFF121212);
	static const Color surfaceCard = Color(0xFF1A1A1A);
	static const Color surfaceElevated = Color(0xFF202020);

	// Structure
	static const Color divider = Color(0xFF2A2A2A);
	static const Color border = Color(0xFF343434);
	static const Color borderSubtle = Color(0xFF262626);

	// Text hierarchy
	static const Color textPrimary = neutralLight;
	static const Color textSecondary = Color(0xFFD0CEC7);
	static const Color textMuted = Color(0xFFA09D95);
	static const Color textDisabled = Color(0xFF6E6B65);

	// Accent and interaction
	static const Color accent = brandYellow;
	static const Color accentSoft = Color(0x33FFD72F);
	static const Color accentHover = Color(0xFFF3CB21);
	static const Color accentPressed = Color(0xFFE4BA16);

	// Primary button
	static const Color buttonPrimaryBg = accent;
	static const Color buttonPrimaryFg = darkBase;
	static const Color buttonPrimaryStroke = Color(0xFFFFC928);
	static const Color buttonPrimaryHover = accentHover;
	static const Color buttonPrimaryPressed = accentPressed;

	// Secondary button
	static const Color buttonSecondaryBg = Color(0xFF1A1A1A);
	static const Color buttonSecondaryFg = textPrimary;
	static const Color buttonSecondaryBorder = border;
	static const Color buttonSecondaryHover = Color(0xFF242424);
	static const Color buttonSecondaryPressed = Color(0xFF151515);

	// Ghost button
	static const Color buttonGhostFg = textSecondary;
	static const Color buttonGhostHover = Color(0x1AF1EFE7);
	static const Color buttonGhostPressed = Color(0x2AF1EFE7);

	// Status colors
	static const Color success = Color(0xFF35D39A);
	static const Color warning = Color(0xFFF5A623);
	static const Color error = Color(0xFFFF5C74);
	static const Color info = Color(0xFFFFE08A);

	static const Color onSuccess = Color(0xFF0B1A15);
	static const Color onWarning = Color(0xFF231500);
	static const Color onError = Color(0xFF2A0B11);
	static const Color onInfo = Color(0xFF2B2300);
}

const TextTheme uniSyncTextTheme = TextTheme(
	displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
	displayMedium: TextStyle(fontSize: 36, fontWeight: FontWeight.w600),
	displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
	headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
	headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
	headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
	titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
	titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
	titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
	bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
	bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
	bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
	labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
	labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
	labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
);

ThemeData buildUniSyncDarkTheme() {
	final base = ThemeData(
		brightness: Brightness.dark,
		fontFamily: 'Poppins',
		scaffoldBackgroundColor: UniSyncColors.backgroundPrimary,
		canvasColor: UniSyncColors.backgroundSecondary,
		cardColor: UniSyncColors.surfaceCard,
		dividerColor: UniSyncColors.divider,
		useMaterial3: true,
	);

	final colorScheme = const ColorScheme.dark(
		primary: UniSyncColors.accent,
		onPrimary: UniSyncColors.buttonPrimaryFg,
		secondary: UniSyncColors.accent,
		onSecondary: UniSyncColors.buttonPrimaryFg,
		surface: UniSyncColors.surfaceCard,
		onSurface: UniSyncColors.textPrimary,
		error: UniSyncColors.error,
		onError: UniSyncColors.onError,
		outline: UniSyncColors.border,
		shadow: Colors.black,
		scrim: Colors.black,
	).copyWith(
		surfaceContainerHighest: UniSyncColors.surfaceElevated,
		surfaceContainerHigh: UniSyncColors.surfaceCard,
		surfaceContainer: UniSyncColors.backgroundSecondary,
	);

	return base.copyWith(
		colorScheme: colorScheme,
		textTheme: uniSyncTextTheme.apply(
			fontFamily: 'Poppins',
			bodyColor: UniSyncColors.textPrimary,
			displayColor: UniSyncColors.textPrimary,
		),
		primaryTextTheme: uniSyncTextTheme.apply(
			fontFamily: 'Poppins',
			bodyColor: UniSyncColors.textPrimary,
			displayColor: UniSyncColors.textPrimary,
		),
		disabledColor: UniSyncColors.textDisabled,
		appBarTheme: const AppBarTheme(
			backgroundColor: UniSyncColors.backgroundPrimary,
			foregroundColor: UniSyncColors.textPrimary,
			surfaceTintColor: Colors.transparent,
			elevation: 0,
		),
		cardTheme: CardThemeData(
			color: UniSyncColors.surfaceCard,
			elevation: 0,
			shape: RoundedRectangleBorder(
				borderRadius: BorderRadius.circular(14),
				side: const BorderSide(color: UniSyncColors.borderSubtle),
			),
		),
		dividerTheme: const DividerThemeData(
			color: UniSyncColors.divider,
			thickness: 1,
		),
		outlinedButtonTheme: OutlinedButtonThemeData(
			style: ButtonStyle(
				backgroundColor: MaterialStateProperty.resolveWith((states) {
					if (states.contains(MaterialState.pressed)) {
						return UniSyncColors.buttonSecondaryPressed;
					}
					if (states.contains(MaterialState.hovered)) {
						return UniSyncColors.buttonSecondaryHover;
					}
					return UniSyncColors.buttonSecondaryBg;
				}),
				foregroundColor: const MaterialStatePropertyAll(UniSyncColors.buttonSecondaryFg),
				side: const MaterialStatePropertyAll(
					BorderSide(color: UniSyncColors.buttonSecondaryBorder),
				),
			),
		),
		elevatedButtonTheme: ElevatedButtonThemeData(
			style: ButtonStyle(
				elevation: const MaterialStatePropertyAll(0),
				backgroundColor: MaterialStateProperty.resolveWith((states) {
					if (states.contains(MaterialState.disabled)) {
						return UniSyncColors.accent.withValues(alpha: 0.35);
					}
					if (states.contains(MaterialState.pressed)) {
						return UniSyncColors.buttonPrimaryPressed;
					}
					if (states.contains(MaterialState.hovered)) {
						return UniSyncColors.buttonPrimaryHover;
					}
					return UniSyncColors.buttonPrimaryBg;
				}),
				foregroundColor: const MaterialStatePropertyAll(UniSyncColors.buttonPrimaryFg),
			),
		),
		textButtonTheme: TextButtonThemeData(
			style: ButtonStyle(
				foregroundColor: const MaterialStatePropertyAll(UniSyncColors.buttonGhostFg),
				overlayColor: MaterialStateProperty.resolveWith((states) {
					if (states.contains(MaterialState.pressed)) {
						return UniSyncColors.buttonGhostPressed;
					}
					if (states.contains(MaterialState.hovered)) {
						return UniSyncColors.buttonGhostHover;
					}
					return Colors.transparent;
				}),
			),
		),
		inputDecorationTheme: InputDecorationTheme(
			filled: true,
			fillColor: UniSyncColors.backgroundSecondary,
			hintStyle: const TextStyle(color: UniSyncColors.textMuted),
			enabledBorder: OutlineInputBorder(
				borderRadius: BorderRadius.circular(12),
				borderSide: const BorderSide(color: UniSyncColors.borderSubtle),
			),
			focusedBorder: OutlineInputBorder(
				borderRadius: BorderRadius.circular(12),
				borderSide: const BorderSide(color: UniSyncColors.accent),
			),
			errorBorder: OutlineInputBorder(
				borderRadius: BorderRadius.circular(12),
				borderSide: const BorderSide(color: UniSyncColors.error),
			),
			focusedErrorBorder: OutlineInputBorder(
				borderRadius: BorderRadius.circular(12),
				borderSide: const BorderSide(color: UniSyncColors.error),
			),
		),
	);
}