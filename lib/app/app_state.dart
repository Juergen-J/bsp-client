import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  final List<Locale> supportedLocales = [Locale('en'), Locale('ru')];
  Locale _locale = Locale('en');
  bool isDarkMode = false;

  Locale get locale => _locale;

  void changeLocale(Locale newLocale) {
    _locale = newLocale;
    notifyListeners();
  }

  ThemeData get currentTheme => isDarkMode
      ? ThemeData.dark(useMaterial3: true)
      : ThemeData(
    fontFamily: 'NotoSans',
    useMaterial3: true,
    colorScheme: _colorScheme,
    textTheme: _textTheme,
  );

  ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: _colorScheme.primary,
    foregroundColor: _colorScheme.onPrimary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(32),
    ),
    minimumSize: const Size.fromHeight(50),
  );

  ColorScheme get _colorScheme => ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF2754E8),
    onPrimary: Colors.white,
    secondary: Color(0xFFB7C3EC),
    onSecondary: Color(0xFF222222),
    error: Color(0xFFB00020),
    onError: Colors.white,
    surface: Colors.white,
    onSurface: Color(0xFF222222),
    primaryContainer: Color(0xFFE3E7FB),
    onPrimaryContainer: Color(0xFF2754E8),
    surfaceVariant: Color(0xFFF2F4F7),
    onSurfaceVariant: Color(0xFFD9D9D9),
    outline: Color(0xFFCCCCCC),
  );

  TextTheme get _textTheme => TextTheme(
    titleLarge: TextStyle(
      fontFamily: 'NotoSans',
      fontSize: 24,
      fontWeight: FontWeight.w500,
    ),
    labelMedium: TextStyle(
      fontFamily: 'NotoSans',
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'NotoSans',
      fontSize: 14,
      fontWeight: FontWeight.normal,
    ),
  );

  BoxDecoration get modalDecoration => BoxDecoration(
    color: currentTheme.colorScheme.surface,
    borderRadius: BorderRadius.circular(32),
    boxShadow: [
      BoxShadow(
        color: const Color.fromRGBO(212, 217, 233, 0.5),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );

  EdgeInsets get modalPadding => const EdgeInsets.symmetric(horizontal: 100, vertical: 50);
  double get modalMaxWidth => 400;

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }
}
