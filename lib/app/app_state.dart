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
          colorScheme: ColorScheme(
            brightness: Brightness.light,
            primary: Color(0xFF2754E8),
            onPrimary: Color(0xFFFFFFFF),
            secondary: Color(0xFFB7C3EC),
            onSecondary: Color(0xFF222222),
            error: Color(0xFFB00020),
            onError: Color(0xFFFFFFFF),
            surface: Color(0xFFFFFFFF),
            onSurface: Color(0xFF222222),
            primaryContainer: Color(0xFFE3E7FB),
            onPrimaryContainer: Color(0xFF2754E8),
            surfaceVariant: Color(0xFFF2F4F7),
            onSurfaceVariant: Color(0xFF1A1A1A),
            outline: Color(0xFFCCCCCC),
          ),
          textTheme: TextTheme(
            titleLarge: TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
            labelMedium: TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              // height: 2.86,
            ),
          ));

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }
}
