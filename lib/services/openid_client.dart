import 'dart:io';
import 'package:berlin_service_portal/services/openid_browser.dart';
import 'package:flutter/foundation.dart';
import 'package:openid_client/openid_client.dart';
import 'openid_io.dart' if (dart.library.html) 'openid_browser.dart';

const keycloakUri = 'http://localhost:51315/realms/berlin-service-portal';
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

Future<void> auth() async {
  try {
    print('Starting authentication...');

    credential = await authenticate(client, scopes: scopes);
  } catch (e) {
    print('Authentication error: $e');
    rethrow;
  }
}
