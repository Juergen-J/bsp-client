import 'package:dio/dio.dart';

class FavoriteService {
  final Dio dio;

  FavoriteService({required this.dio});

  Future<void> addFavorite(String serviceId) async {
    await dio.post(
      '/v1/service/favorites',
      data: {'serviceId': serviceId},
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
  }

  Future<void> removeFavorite(String serviceId) async {
    await dio.delete('/v1/service/favorites/$serviceId');
  }
}
