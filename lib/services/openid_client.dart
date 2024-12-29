import 'dart:io';
import 'package:berlin_service_portal/services/openid_browser.dart';
import 'package:flutter/foundation.dart';
import 'package:http/src/client.dart' as oidc;
import 'package:openid_client/openid_client.dart';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'openid_io.dart' if (dart.library.html) 'openid_browser.dart';

const keycloakUri = 'http://localhost:8080/realms/berlin-service-portal';
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

Future<void> logoutUser() async {
  try {
    print('Starting logout...');
    if (credential != null) {
      final url = credential?.generateLogoutUrl()?.toString();
      if (url != null) {
        final request = html.HttpRequest();
        request.open('GET', url);
        request.setRequestHeader(
            'Access-Control-Request-Private-Network', 'true');
        request.onLoad.listen((event) async {
          if (request.status == 200) {
            await logout(client, scopes: scopes);
          } else {
            print('Error ${request.status}: ${request.statusText}');
          }
        });
        request.send();
      }
    }
  } catch (e) {
    print('Logout error: $e');
    rethrow;
  }
}

Future<http.Client?> getAccessTokenHttpClient() async {
  if (credential != null) {
    return credential!.createHttpClient();
  }
  print("Nullable credentials");
  return null;
}

Future<String?> getToken() async {
  if (credential != null) {
    TokenResponse tokenResponse = await credential!.getTokenResponse();
    print(tokenResponse.accessToken);
    return tokenResponse.accessToken;
  } else {
    return null;
  }
}

Future<UserInfo?> getUserInfo() async {
  if (credential != null) {
    return await credential!.getUserInfo();
  } else {
    return null;
  }
}
