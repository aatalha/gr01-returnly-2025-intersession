import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Light theme with:
/// • background: #FEFAF6
/// • text: black
/// • appBar & buttons: #EADBC8
/// • icons: #102C57
final ThemeData lightMode = ThemeData.light().copyWith(
  useMaterial3: true,

  // All Scaffold backgrounds
  scaffoldBackgroundColor: const Color(0xFFFEFAF6),

  // Core color roles
  colorScheme: const ColorScheme.light(
    primary: Color(0xFFEADBC8),    // buttons & AppBar
    onPrimary: Colors.black,       // text/icons on primary surfaces
    secondary: Color(0xFFEADBC8),  // accents (if used)
    onSecondary: Colors.black,
    surface: Color(0xFFFEFAF6),    // cards, sheets, etc
    onSurface: Colors.black,
    background: Color(0xFFFEFAF6), // default page BG if used
    error: Colors.red,
    onError: Colors.white,
  ),

  // AppBar styling
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFEADBC8),
    foregroundColor: Colors.black,
    iconTheme: IconThemeData(color: Color(0xFF102C57)),
    titleTextStyle: TextStyle(
      color: Colors.black,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),

  // Base text styling (Roboto, all black by default)
  textTheme: GoogleFonts.robotoTextTheme(
    ThemeData.light().textTheme,
  ).apply(bodyColor: Colors.black, displayColor: Colors.black),

  // Default icon color
  iconTheme: const IconThemeData(color: Color(0xFF102C57)),

  // ElevatedButton defaults to EADBC8 bg + black text
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFEADBC8),
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
    ),
  ),

  // Card styling (same as background or change if you like)
  cardTheme: CardTheme(
    color: const Color(0xFFFEFAF6),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 0,
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  ),

  // TextField styling
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFFEFAF6),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    labelStyle: const TextStyle(color: Colors.black),
    hintStyle: const TextStyle(color: Colors.black54),
  ),

  // Switch styling (thumb navy, semi-opaque track)
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.all(const Color(0xFF102C57)),
    trackColor: WidgetStateProperty.all(const Color(0xFF102C57).withAlpha(128)),
  ),
);

/// Dark theme with simple black/grey/white palette:
/// - Background: black
/// - Surface:   grey[850]
/// - Text/Icons: white
final ThemeData darkMode = ThemeData.dark().copyWith(
  // ignore: deprecated_member_use
  useMaterial3: true,

  // All Scaffold backgrounds will be pure black
  scaffoldBackgroundColor: Colors.black,

  // Build a ColorScheme without deprecated fields
  colorScheme: ColorScheme.dark(
    primary: Colors.white,    // buttons, active elements
    onPrimary: Colors.black,   // text/icons on primary surfaces
    secondary: Colors.grey,    // accents
    onSecondary: Colors.white, // text/icons on secondary surfaces
    surface: Colors.grey[850]!,// card & dialog backgrounds
    onSurface: Colors.white,   // text/icons on surfaces
    error: Colors.red,         // error color
    onError: Colors.white,     // text/icons on error surfaces
  ),

  textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme)
      .apply(bodyColor: Colors.white, displayColor: Colors.white),

  iconTheme: const IconThemeData(color: Colors.white),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.grey[700],
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
    ),
  ),

  cardTheme: CardTheme(
    color: Colors.grey[850],
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 2,
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey[800],
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),

  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.all(Colors.white),
    trackColor: WidgetStateProperty.all(Colors.white30),
  ),
);
