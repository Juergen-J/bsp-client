import 'dart:io';
import 'package:berlin_service_portal/services/openid_browser.dart';
import 'package:flutter/foundation.dart';
import 'package:openid_client/openid_client.dart';
import 'openid_io.dart' if (dart.library.html) 'openid_browser.dart';

const keycloakUri = 'http://localhost:50604/realms/berlin-service-portal';
const scopes = ['profile'];

Credential? credential;

late final Client client;

Future<Client> getClient() async {
  var uri = Uri.parse(keycloakUri);

  if (!kIsWeb && Platform.isAndroid) {
    uri = uri.replace(host: '10.0.2.2');
  }

  var clientId = 'public-client';
  var issuer = await Issuer.discover(uri);
  return Client(issuer, clientId);
}

Future<UserInfo?> initOpenidClient() async {
  client = await getClient();

  credential = await getRedirectResult(client, scopes: scopes);

  if (credential != null) {
    print('Credential obtained on startup');
    return credential!.getUserInfo();
  } else {
    print('No credential obtained during redirect.');
    return null;
  }
}

Future<UserInfo> auth() async {
  try {
    print('Starting authentication...');

    // Аутентификация пользователя через OpenID клиент
    credential = await authenticate(client, scopes: scopes);
    print('Credential obtained: ${credential != null}');

    if (credential == null) {
      throw Exception('Authentication failed or user cancelled the process.');
    }

    // Получаем информацию о пользователе
    UserInfo userInfo = await credential!.getUserInfo();
    print('UserInfo retrieved: ${userInfo.name}, ${userInfo.email}');

    return userInfo;
  } catch (e) {
    print('Authentication error: $e');
    rethrow; // Прокидываем исключение вверх для дальнейшей обработки
  }
}

Future<void> logot() async {
  print("logout web");
  await logout(client, scopes: scopes);
}

Future<void> logoutFromKeycloak() async{

}
