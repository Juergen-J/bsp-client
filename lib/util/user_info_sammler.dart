import 'dart:convert';
import 'dart:ui';

import 'package:dio/dio.dart';

Future<void> fetchLocation() async {
  final dio = Dio();
  final response = await dio.get(' https://ipwho.is/');

  if (response.statusCode == 200) {
    final data = json.decode(response.data);
    print(data);
    print("City: ${data['city']}, Country: ${data['country_name']}");
  } else {
    print("Failed to get location data");
  }
}