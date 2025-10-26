import 'package:berlin_service_portal/app/stomp_client_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import 'app_state.dart';
import 'router.dart';

class BSPApp extends StatefulWidget {
  const BSPApp({super.key});

  @override
  State<BSPApp> createState() => _BSPAppState();
}

class _BSPAppState extends State<BSPApp> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StompClientNotifier>();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, appState, child) {
      return MaterialApp.router(
        title: 'Title App',
        theme: appState.currentTheme,
        locale: appState.locale,
        localizationsDelegates: const [
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
