import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class FavoriteService extends ChangeNotifier {
  Dio _dio;

  FavoriteService({required Dio dio}) : _dio = dio;

  void updateClient(Dio dio) {
    _dio = dio;
  }

  Future<void> addFavorite(String serviceId) async {
    await _dio.post(
      '/v1/service/favorites',
      data: {'serviceId': serviceId},
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    notifyListeners();
  }

  Future<void> removeFavorite(String serviceId) async {
    await _dio.delete('/v1/service/favorites/$serviceId');
    notifyListeners();
  }
}
