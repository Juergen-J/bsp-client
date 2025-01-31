import 'package:dio/dio.dart';
import 'package:flutter_flavor/flutter_flavor.dart';
import 'package:provider/provider.dart';

import 'auth_service.dart';

createChatWith(context, List<String> userIds) async {
  final Dio dio = Provider.of<AuthService>(context, listen: false).dio;
  final String _host = FlavorConfig.instance.variables['beHost'];
  final response = await dio.post(
    'http://$_host/v1/chat',
    options: Options(headers: {"Content-Type": "application/json"}),
    data: userIds,
  );

  if (response.statusCode == 200) {
  } else {
    print('Error : $response');
  }
}
