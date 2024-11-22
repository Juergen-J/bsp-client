import 'package:berlin_service_portal/app/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = Provider.of<AppState>(context);

    final locales = appState.supportedLocales;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Change Language',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        DropdownButton<Locale>(
          value: appState.locale,
          onChanged: (Locale? newLocale) {
            if (newLocale != null) {
              appState.changeLocale(newLocale);
            }
          },
          items: locales.map((locale) {
            return DropdownMenuItem(
              value: locale,
              child: Text(_getLanguageName(locale)),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'ru':
        return 'Русский';
      default:
        return locale.languageCode;
    }
  }
}
