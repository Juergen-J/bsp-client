import 'package:berlin_service_portal/services/openid_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flavor/flutter_flavor.dart';
import 'package:provider/provider.dart';
import 'app/app_state.dart';
import 'app/bsp_app.dart';
import 'app/stomp_client_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var userInfo = await initOpenidClient();
  FlavorConfig(
      name: "DEV",
      color: Colors.red,
      location: BannerLocation.bottomEnd,
      variables: {"beHost": "localhost:8090"});
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => AppState(userInfo: userInfo)),
    ChangeNotifierProvider(create: (_) => StompClientNotifier())
  ], child: const BSPApp()));
}
