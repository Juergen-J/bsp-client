import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ImageService {
  final Dio dio;
  final Map<String, Uint8List> _cache = {};

  ImageService({required this.dio});

  Future<Uint8List> fetchImageBytes(String attachmentId) async {
    if (_cache.containsKey(attachmentId)) {
      return _cache[attachmentId]!;
    }

    try {
      final response = await dio.get<List<int>>(
        'http://localhost:8090/v1/attachment/$attachmentId',
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = Uint8List.fromList(response.data!);
      _cache[attachmentId] = bytes;
      return bytes;
    } on DioException catch (e) {
      debugPrint(
          'Error fetching image: ${e.response?.statusCode} - ${e.message}');
      rethrow;
    }
  }

  Future<Widget> getImageWidget(
    String attachmentId, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) async {
    try {
      final bytes = await fetchImageBytes(attachmentId);
      return Image.memory(
        bytes,
        fit: fit,
        width: width,
        height: height,
      );
    } catch (_) {
      return const Icon(Icons.broken_image);
    }
  }
}
