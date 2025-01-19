import 'dart:convert';
import 'package:flutter_flavor/flutter_flavor.dart';
import 'openid_client.dart';

createChatWith(List<String> userIds) async {
  final String _host = FlavorConfig.instance.variables['beHost'];
  final httpClient = await getAccessTokenHttpClient();
  if (httpClient == null) {
    print('HTTP client is null. Authentication might have failed.');
    return;
  }
  final response = await httpClient.post(
      Uri.parse('http://$_host/v1/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userIds));
  if (response.statusCode == 200) {
  } else {
    print('Error : $response');
  }
}
