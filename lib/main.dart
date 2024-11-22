import 'package:berlin_service_portal/services/openid_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flavor/flutter_flavor.dart';
import 'package:provider/provider.dart';
import 'app/app_state.dart';
import 'app/bsp_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initOpenidClient();
  FlavorConfig(
    name: "DEV",
    color: Colors.red,
    location: BannerLocation.topEnd,
  );
  runApp(ChangeNotifierProvider(
    create: (_) => AppState(),
    child: const BSPApp(),
  ));
}
