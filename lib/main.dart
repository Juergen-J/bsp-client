import 'package:berlin_service_portal/page/modal/modal_service.dart';
import 'package:berlin_service_portal/provider/messager_provider.dart';
import 'package:berlin_service_portal/service/auth_redirect_service.dart';
import 'package:berlin_service_portal/service/auth_service.dart';
import 'package:berlin_service_portal/service/image_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flavor/flutter_flavor.dart';
import 'package:provider/provider.dart';
import 'package:url_strategy/url_strategy.dart';
import 'app/app_state.dart';
import 'app/bsp_app.dart';
import 'app/stomp_client_notifier.dart';

void main() async {
  if (kDebugMode) {
    print('App running in DEBUG mode');
  } else {
    print('App running in RELEASE mode');
  }
  WidgetsFlutterBinding.ensureInitialized();

  FlavorConfig(
      name: "DEV",
      color: Colors.red,
      location: BannerLocation.bottomEnd,
      variables: {"beHost": "localhost:8090"});
  setPathUrlStrategy();
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => AuthRedirectService()),
    ChangeNotifierProvider(
        create: (_) => AuthService(FlavorConfig.instance.variables['beHost'])),
    ChangeNotifierProxyProvider<AuthService, StompClientNotifier>(
      create: (context) {
        final authService = context.read<AuthService>();
        return StompClientNotifier(authService);
      },
      update: (_, authService, stompNotifier) {
        final stomp = stompNotifier ?? StompClientNotifier(authService);

        authService.onLogoutCallback = () {
          stomp.dispose();
        };

        return stomp;
      },
    ),
    ChangeNotifierProxyProvider<AuthService, MessagesProvider>(
      create: (context) => MessagesProvider(context.read<AuthService>()),
      update: (context, authService, messagesProv) {
        messagesProv ??= MessagesProvider(authService);

        if (!authService.isLoggedIn) {
          messagesProv.clear();
        } else {
          messagesProv.fetchConversations();
        }
        return messagesProv;
      },
    ),
    ProxyProvider<AuthService, ImageService>(
      update: (_, auth, __) => ImageService(dio: auth.dio),
    ),
    ChangeNotifierProvider(create: (_) => AppState()),
    ChangeNotifierProvider(create: (_) => ModalManager())
  ], child: const BSPApp()));
}
