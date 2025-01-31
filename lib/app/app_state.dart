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
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        );

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }
}
