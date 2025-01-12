import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'app_state.dart';
import 'router.dart';

class BSPApp extends StatelessWidget {
  const BSPApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, appState, child) {
      return MaterialApp.router(
        title: 'Tittle App',
        theme: appState.currentTheme,
        locale: appState.locale,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: appState.supportedLocales,
        routerConfig: router,
      );
    });
  }
}
