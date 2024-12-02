import 'dart:async';
import 'dart:html';

import 'package:dio/dio.dart';
import 'package:openid_client/openid_client.dart';
import 'package:openid_client/openid_client_browser.dart' as browser;

final dio = Dio();

Future<Credential> authenticate(Client client,
    {List<String> scopes = const []}) async {
  var authenticator = browser.Authenticator(client, scopes: scopes);

  authenticator.authorize();

  return Completer<Credential>().future;
}

Future<Credential?> getRedirectResult(Client client,
    {List<String> scopes = const []}) async {
  var authenticator = browser.Authenticator(client, scopes: scopes);

  var c = await authenticator.credential;
  if (c == null) {
    print("credential is null in getRedirect result ");
  }

  return c;
}

Future<void> logout(Client client,
    {List<String> scopes = const []}) async {
  var authenticator = browser.Authenticator(client, scopes: scopes);

  authenticator.logout();
  window.localStorage.remove('openid_client:state');
  window.localStorage.remove('openid_client:auth');
  return Completer<void>().future;
}